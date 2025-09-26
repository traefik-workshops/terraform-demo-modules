#!/bin/bash
set -euxo pipefail

# Parse command line arguments
NAME=""
IMAGE=""
TAG=""
RUNPOD_API_KEY=""
NGC_TOKEN=""
POD_TYPE=""
REGISTRY_AUTH_ID=""
OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --name) NAME="$2"; shift 2;;
    --image) IMAGE="$2"; shift 2;;
    --tag) TAG="$2"; shift 2;;
    --runpod-api-key) RUNPOD_API_KEY="$2"; shift 2;;
    --ngc-token) NGC_TOKEN="$2"; shift 2;;
    --pod-type) POD_TYPE="$2"; shift 2;;
    --registry-auth-id) REGISTRY_AUTH_ID="$2"; shift 2;;
    --output-file) OUTPUT_FILE="$2"; shift 2;;
    *) echo "Unknown parameter: $1"; exit 1;;
  esac
done

echo "Starting pod management script" >&2

# Debug: Print non-sensitive parameters
echo "Processing pod: $NAME" >&2
echo "Output file: $OUTPUT_FILE" >&2

# Verify required parameters
if [ -z "${REGISTRY_AUTH_ID:-}" ]; then
    jq -n --arg error 'registry_auth_id is required' '{error: $error}'
    exit 1
fi

if [ -z "${OUTPUT_FILE:-}" ]; then
    jq -n --arg error 'output-file is required' '{error: $error}'
    exit 1
fi

# Initialize output file if it doesn't exist
if [ ! -f "$OUTPUT_FILE" ]; then
    echo '{}' > "$OUTPUT_FILE"
fi

# Function to check if pod exists and get its info
check_existing_pod() {
    local pod_name="$1"
    echo "Checking for existing pod: $pod_name" >&2
    
    # Get all pods and filter by name
    if ! runpodctl_output=$(runpodctl get pods 2>&1); then
        echo "Error running 'runpodctl get pods': $runpodctl_output" >&2
        return 1
    fi
    
    echo "runpodctl output: $runpodctl_output" >&2
    
    local pod_line
    pod_line=$(echo "$runpodctl_output" | awk -v name="$pod_name" '$2 == name' | head -n 1)
    
    if [ -n "$pod_line" ]; then
        echo "Found existing pod: $pod_line" >&2
        # Extract pod ID from the line (first column)
        local pod_id=$(echo "$pod_line" | awk '{print $1}')
        echo "Extracted pod ID: $pod_id" >&2
        
        # Get detailed pod info
        local pod_info
        if ! pod_info=$(runpodctl get pods "$pod_id" 2>&1); then
            return 1
        fi
        
        if [ -n "$pod_info" ]; then
            echo "Pod info: $pod_info" >&2
            # Format the output as JSON with host key
            jq -n --arg id "$pod_id" --arg name "$pod_name" \
                --arg host "https://${pod_id}-8000.proxy.runpod.net/" \
                '{id: $id, name: $name, desiredStatus: "RUNNING", host: $host}' || {
                echo "Failed to format pod info as JSON" >&2
                return 1
            }
            return 0
        fi
    else
        echo "No existing pod found with name: $pod_name" >&2
    fi
    
    return 1
}

# Check if pod already exists
echo "Checking if pod '$NAME' already exists..." >&2
existing_pod=""
if existing_pod=$(check_existing_pod "$NAME"); then
    echo "Pod '$NAME' already exists, using existing pod" >&2
    pod_info="$existing_pod"
else
    echo "No existing pod found, creating a new one..." >&2
    # Create new pod
    QUERY=$(cat <<EOF
    {
      "query": "mutation { podFindAndDeployOnDemand(input: { cloudType: ALL name: \"$NAME\" containerDiskInGb: 40 volumeInGb: 0 gpuCount: 1 gpuTypeId: \"$POD_TYPE\" imageName: \"$IMAGE:$TAG\" ports: \"8000/http\" containerRegistryAuthId: \"$REGISTRY_AUTH_ID\" env: [ { key: \"NGC_API_KEY\", value: \"$NGC_TOKEN\" } ] } ) { id name desiredStatus } }"
    }
EOF
    )

    echo "Creating pod '$NAME'..." >&2
    RESPONSE=$(curl -sS -X POST \
      -H "Content-Type: application/json" \
      -d "$QUERY" \
      "https://api.runpod.io/graphql?api_key=$RUNPOD_API_KEY")

    # Extract pod info from response and add host key
    pod_info=$(echo "$RESPONSE" | jq --arg host "https://$(echo "$RESPONSE" | jq -r '.data.podFindAndDeployOnDemand.id')-8000.proxy.runpod.net/" \
        '.data.podFindAndDeployOnDemand | {id, name, desiredStatus, host: $host}' 2>/dev/null)
    
    if [ -z "$pod_info" ] || [ "$pod_info" = "null" ]; then
        echo "Failed to create pod. Response: $RESPONSE" >&2
        exit 1
    fi
fi

# Update the output file with the new pod info
echo "Updating output file: $OUTPUT_FILE" >&2
tmp_file=$(mktemp) || { echo "Failed to create temporary file" >&2; exit 1; }

if ! jq --arg name "$NAME" --argjson pod "$pod_info" '.[$name] = $pod' "$OUTPUT_FILE" > "$tmp_file"; then
    echo "Failed to update JSON file" >&2
    rm -f "$tmp_file"
    exit 1
fi

if ! mv "$tmp_file" "$OUTPUT_FILE"; then
    echo "Failed to move temporary file to $OUTPUT_FILE" >&2
    rm -f "$tmp_file"
    exit 1
fi

# Output the current state of pods
echo "Pod information:" >&2
if ! cat "$OUTPUT_FILE" >&2; then
    echo "Failed to read output file" >&2
    exit 1
fi

# Also output to stdout for Terraform
cat "$OUTPUT_FILE"
