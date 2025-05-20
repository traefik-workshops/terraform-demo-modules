resource "k3d_cluster" "traefik_demo" {
  name    = var.cluster_name
  # See https://k3d.io/v5.8.3/usage/configfile/#config-options
  k3d_config = <<EOF
apiVersion: k3d.io/v1alpha5
kind: Simple
metadata:
  name: ${var.cluster_name}
servers: 1
ports:
  - port: 8000:80
    nodeFilters:
      - loadbalancer
  - port: 8443:443
    nodeFilters:
      - loadbalancer
  - port: 8080:8080
    nodeFilters:
      - loadbalancer
options:
  k3s:
    extraArgs:
      - arg: "--disable=traefik"
        nodeFilters:
          - "server:*"
EOF
}
