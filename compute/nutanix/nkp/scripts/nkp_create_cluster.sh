#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

#------------------------------------------------------------------------------

# Copyright 2024 Nutanix, Inc
#
# Licensed under the MIT License;
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”),
# to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#------------------------------------------------------------------------------

# Link to original: https://github.com/nutanixdev/nkp-tutorials/blob/main/deploying-nkp-with-terraform/scripts/nkp_create_cluster.sh
# Modified to support multiple subnets and configurable node specs

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
)

if [ -n "${REGISTRY_MIRROR_URL:-}" ]; then
    CLEAN_MIRROR_URL="${REGISTRY_MIRROR_URL#https://}"
    
    BOOTSTRAP_IMAGE="$CLEAN_MIRROR_URL/mesosphere/konvoy-bootstrap:v$NKP_VERSION"
    
    ARGS+=(--bootstrap-cluster-image "$BOOTSTRAP_IMAGE")
    ARGS+=(--registry-mirror-url "$REGISTRY_MIRROR_URL")
    ARGS+=(--skip-preflight-checks "Registry,NutanixCredentials,NutanixVMImageKubernetesVersion,NutanixStorageContainer")
fi

nkp "${ARGS[@]}"

# Make new cluster KUBECONFIG default
mkdir -p ~/.kube
cp "${CLUSTER_NAME}.conf" ~/.kube/config
chmod 600 ~/.kube/config
