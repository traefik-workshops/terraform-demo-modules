locals {
  kubeconfig_raw  = base64decode(linode_lke_cluster.traefik_demo.kubeconfig)
  kubeconfig_json = yamldecode(local.kubeconfig_raw)

  cluster_entry   = local.kubeconfig_json.clusters[0].cluster
  cluster_server  = local.cluster_entry.server
  cluster_ca_cert = local.cluster_entry["certificate-authority-data"]
}

output "host" {
  sensitive   = true
  description = "LKE cluster host"
  value       = local.cluster_server
}

output "cluster_ca_certificate" {
  sensitive   = true
  description = "LKE cluster CA certificate"
  value       = base64decode(local.cluster_ca_cert)
}
