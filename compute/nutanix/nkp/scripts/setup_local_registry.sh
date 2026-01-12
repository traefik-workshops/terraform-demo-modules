#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ~/variables.sh

echo "Setting up local Docker registry for NKP bootstrap image..."

# Check if the bootstrap tar file exists
BOOTSTRAP_TAR="konvoy-bootstrap-image-v${NKP_VERSION}.tar"
if [ ! -f "$BOOTSTRAP_TAR" ]; then
    echo "Error: Bootstrap tar file $BOOTSTRAP_TAR not found"
    exit 1
fi

# Load the bootstrap image into Docker
echo "Loading bootstrap image from tar file..."
docker load -i "$BOOTSTRAP_TAR"

# Start a local Docker registry if not already running
if ! docker ps | grep -q local-registry; then
    echo "Starting local Docker registry on port 5000..."
    
    # Temporarily disable registry mirror to pull registry:2 from Docker Hub
    if [ -f /etc/docker/daemon.json ]; then
        echo "Temporarily backing up docker daemon.json to bypass registry mirror..."
        sudo mv /etc/docker/daemon.json /etc/docker/daemon.json.bak
        sudo systemctl restart docker
        sleep 3
    fi
    
    # Pull registry:2 from Docker Hub directly
    echo "Pulling registry:2 image from Docker Hub..."
    docker pull docker.io/library/registry:2
    
    # Restore registry mirror configuration
    if [ -f /etc/docker/daemon.json.bak ]; then
        echo "Restoring docker daemon.json..."
        sudo mv /etc/docker/daemon.json.bak /etc/docker/daemon.json
        sudo systemctl restart docker
        sleep 3
    fi
    
    # Start the registry container
    docker run -d -p 5000:5000 --restart=always --name local-registry registry:2
    
    # Wait for registry to be ready
    echo "Waiting for registry to be ready..."
    MAX_RETRIES=30
    RETRY_COUNT=0
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if curl -s http://localhost:5000/v2/ > /dev/null 2>&1; then
            echo "Registry is ready!"
            break
        fi
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
            echo "Error: Registry failed to become ready after $MAX_RETRIES attempts"
            exit 1
        fi
        echo "Waiting for registry... (attempt $RETRY_COUNT/$MAX_RETRIES)"
        sleep 1
    done
else
    echo "Local registry already running"
fi

# Tag the bootstrap image for the local registry
ORIGINAL_IMAGE="mesosphere/konvoy-bootstrap:v${NKP_VERSION}"
LOCAL_IMAGE="localhost:5000/mesosphere/konvoy-bootstrap:v${NKP_VERSION}"

echo "Tagging image for local registry..."
docker tag "$ORIGINAL_IMAGE" "$LOCAL_IMAGE"

# Push to local registry
echo "Pushing image to local registry..."
docker push "$LOCAL_IMAGE"

echo "Local registry setup complete!"
echo "Bootstrap image available at: $LOCAL_IMAGE"
