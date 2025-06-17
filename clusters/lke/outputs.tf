# output "host" {
#   description = "LKE cluster host"
#   value = linode_lke_cluster.traefik_demo.api_endpoints[0]
# }

# output "cluster_ca_certificate" {
#   description = "LKE cluster CA certificate"
#   value = base64decode(azurerm_kubernetes_cluster.traefik_demo.kube_config.0.cluster_ca_certificate)
# }
