locals {
  # Combine all users for token generation
  token_users = [
    for user in local.all_users : {
      username = user.username
      password = user.password
    }
  ]
}

# Fetch tokens using external script - runs once if secret doesn't exist
data "external" "fetch_tokens" {
  depends_on = [null_resource.validate_keycloak_deployment]

  program = ["bash", "-c", <<-EOT
    set -e
    
    NAMESPACE="${var.namespace}"
    SECRET_NAME="traefik-user-tokens"
    
    # Check if secret exists
    if kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" &>/dev/null; then
      # Secret exists, read tokens from it
      kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data}' | \
      jq -r 'to_entries | map({key: .key, value: (.value | @base64d)}) | from_entries'
    else
      # Secret missing, generate new tokens
      
      # Start port-forward in background
      kubectl port-forward svc/keycloak-service 8080:8080 -n "$NAMESPACE" &>/dev/null &
      PF_PID=$!
      
      # Wait for port-forward
      sleep 5
      
      # Generate tokens for all users
      TOKENS_JSON="{}"
      
      # We need to loop through users passed as JSON argument
      # Since we can't easily pass complex JSON to bash in external data source without it being a string,
      # we'll construct the loop in bash using the input variables which are limited to strings.
      # Instead, we will iterate over the list of users provided in the input
      
      # Actually, passing a list of users to external program is tricky.
      # Let's use a different approach: We will hardcode the user generation logic here 
      # based on the known structure or pass them as a single JSON string argument if possible.
      # But 'query' only supports map of strings.
      
      # Alternative: We can just use the same logic as in the realm.tf to know which users to generate for.
      # But we don't have access to terraform variables inside the bash script easily unless passed.
      
      # Let's try to pass the users as a JSON string in the query.
      # Terraform 'external' query values must be strings.
      
      USERS_JSON='${jsonencode(local.token_users)}'
      
      # Iterate and fetch tokens
      # We use jq to parse the JSON string and iterate
      
      TOKENS=""
      MISSING_USERS=""
      
      while read -r user; do
        USERNAME=$(echo "$user" | jq -r '.username')
        PASSWORD=$(echo "$user" | jq -r '.password')
        
        TOKEN=$(curl -sk -X POST "http://localhost:8080/realms/traefik/protocol/openid-connect/token" \
          -H "Content-Type: application/x-www-form-urlencoded" \
          -d "client_id=traefik" \
          -d "grant_type=password" \
          -d "client_secret=NoTgoLZpbrr5QvbNDIRIvmZOhe9wI0r0" \
          -d "scope=openid" \
          -d "username=$USERNAME" \
          -d "password=$PASSWORD" | jq -r '.access_token')
          
        if [ "$TOKEN" != "null" ] && [ -n "$TOKEN" ]; then
          TOKENS="$TOKENS\"$USERNAME\": \"$TOKEN\"," 
        else
          MISSING_USERS="$MISSING_USERS$USERNAME "
        fi
      done < <(echo "$USERS_JSON" | jq -c '.[]')
      
      # Kill port-forward
      kill $PF_PID || true
      
      if [ -n "$MISSING_USERS" ]; then
        echo "Error: Failed to fetch tokens for users: $MISSING_USERS" >&2
        exit 1
      fi
      
      # Format output as JSON
      echo "{ $${TOKENS%,} }"
    fi
  EOT
  ]
}

resource "kubernetes_secret_v1" "user_tokens" {
  metadata {
    name      = "traefik-user-tokens"
    namespace = var.namespace
  }

  data = data.external.fetch_tokens.result

  type = "Opaque"

  lifecycle {
    ignore_changes = [data]
  }
}
