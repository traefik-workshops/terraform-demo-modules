resource "k3d_cluster" "traefik_demo" {
  name    = var.cluster_name
  # See https://k3d.io/v5.8.3/usage/configfile/#config-options
  k3d_config = <<EOF
apiVersion: k3d.io/v1alpha5
kind: Simple
metadata:
  name: ${var.cluster_name}
servers: ${var.control_plane_nodes.count}
agents: ${sum([for node in var.worker_nodes : node.count])}
ports:
%{ for port in var.ports ~}
  - port: ${port.to}:${port.from}
    nodeFilters:
      - loadbalancer
%{ endfor ~}
options:
  k3s:
    extraArgs:
      - arg: "--disable=traefik"
        nodeFilters:
          - "server:*"
          - "agent:*"
    nodeLabels:
%{ for node_idx, node in var.worker_nodes ~}
%{ if node.label != "" ~}
%{ for instance in range(0, node.count) ~}
      - label: ${node.label}
        nodeFilters:
          - agent:${sum([for i in range(0, node_idx): var.worker_nodes[i].count]) + instance}
%{ endfor ~}
%{ endif ~}
%{ endfor ~}
EOF
}
