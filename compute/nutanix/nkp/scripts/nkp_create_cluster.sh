#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ~/variables.sh

echo "Creating NKP cluster ${CLUSTER_NAME}. This can take about 45 minutes depending on Internet connectivity"

# Construct flags
ARGS=(
    create cluster nutanix -c "$CLUSTER_NAME"
    --endpoint "https://$NUTANIX_ENDPOINT:$NUTANIX_PORT"
    --insecure
    --vm-image "$NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME"
    --kubernetes-service-load-balancer-ip-range "$LB_IP_RANGE"
    --control-plane-endpoint-ip "$CONTROL_PLANE_ENDPOINT_IP"
    --control-plane-prism-element-cluster "$NUTANIX_PRISM_ELEMENT_CLUSTER_NAME"
    --control-plane-subnets "$NUTANIX_SUBNETS"
    --control-plane-replicas "$CP_REPLICAS"
    --worker-prism-element-cluster "$NUTANIX_PRISM_ELEMENT_CLUSTER_NAME"
    --worker-subnets "$NUTANIX_SUBNETS"
    --worker-replicas "$WORKER_REPLICAS"
    --csi-storage-container "$NUTANIX_STORAGE_CONTAINER_NAME"
    --self-managed
    --control-plane-memory "$((CP_MEM / 1024))"
    --control-plane-vcpus "$CP_CPU"
    --worker-memory "$((WORKER_MEM / 1024))"
    --worker-vcpus "$WORKER_CPU"
    --timeout 60m
    --dry-run -o yaml
)

# Setup Mirror Configuration and Bootstrap
BOOTSTRAP_ARGS=()
if [ -n "${REGISTRY_MIRROR_URL:-}" ]; then
    CLEAN_MIRROR_URL="${REGISTRY_MIRROR_URL#https://}"
    BOOTSTRAP_IMAGE="$CLEAN_MIRROR_URL/mesosphere/konvoy-bootstrap:v$NKP_VERSION"
    
    BOOTSTRAP_ARGS+=(--bootstrap-cluster-image "$BOOTSTRAP_IMAGE")
    ARGS+=(--bootstrap-cluster-image "$BOOTSTRAP_IMAGE")
    ARGS+=(--registry-mirror-url "$REGISTRY_MIRROR_URL")
    ARGS+=(--skip-preflight-checks "Registry,NutanixCredentials")
fi

if [ -n "${KUBERNETES_VERSION:-}" ]; then
    ARGS+=(--kubernetes-version "$KUBERNETES_VERSION")
fi

# --- Create Cluster Manifest (Dry Run) ---
echo "Generating cluster configuration..."
nkp "${ARGS[@]}" > cluster.yaml 2> cluster_gen.log || { echo "Cluster generation failed:"; cat cluster_gen.log; exit 1; }

# Sanitize output (remove potential non-YAML lines)
sed -i '/^• /d; /^✓ /d; /^INFO/d; /^WARN/d' cluster.yaml

echo "Cluster configuration generated."
nkp create bootstrap "${BOOTSTRAP_ARGS[@]}"
echo "Bootstrap creation completed."
kubectl apply -f cluster.yaml --validate=false
echo "Configuration applied."

echo "Waiting for Control Plane..."
kubectl wait --for=condition=ControlPlaneReady "cluster.cluster.x-k8s.io/$CLUSTER_NAME" --timeout=60m
echo "Control Plane is ready."

echo "Waiting for nodes to be ready..."
nkp get kubeconfig -c ${CLUSTER_NAME} > ~/${CLUSTER_NAME}.conf
kubectl --kubeconfig ~/${CLUSTER_NAME}.conf wait --for=condition=Ready nodes --all --timeout=60m
echo "Nodes are ready."

echo "Moving cluster to self-managed..."
nkp create capi-components --kubeconfig ${CLUSTER_NAME}.conf
nkp move capi-resources --to-kubeconfig ${CLUSTER_NAME}.conf
echo "Cluster moved to self-managed."

# Wait for the dashboard deployment to be created
echo "Waiting for Kommander UI deployment to be created..."
until kubectl --kubeconfig ~/${CLUSTER_NAME}.conf get deployment/kommander-kommander-ui -n kommander > /dev/null 2>&1; do
    echo "Waiting for kommander-kommander-ui deployment..."
    sleep 10
done

# Wait for the dashboard deployment availability
kubectl --kubeconfig ~/${CLUSTER_NAME}.conf wait --for=condition=Available deployment/kommander-kommander-ui -n kommander --timeout=60m
echo "Kommander is ready."

# Make new cluster KUBECONFIG default
mkdir -p ~/.kube
cp "${CLUSTER_NAME}.conf" ~/.kube/config
chmod 600 ~/.kube/config
