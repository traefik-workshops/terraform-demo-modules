locals {
  kubeconfig_raw     = data.external.kubeconfig.result["content"]
  kubeconfig         = yamldecode(local.kubeconfig_raw)
  client_certificate = base64decode(local.kubeconfig.users[0].user["client-certificate-data"])
  client_key         = base64decode(local.kubeconfig.users[0].user["client-key-data"])
}

output "host" {
  description = "Kubernetes API Server endpoint"
  value       = "https://${var.control_plane_fip != "" ? var.control_plane_fip : var.control_plane_vip}:6443"
  sensitive   = true
}

output "client_certificate_data" {
  description = "Client certificate data"
  value       = local.client_certificate
  sensitive   = true
}

output "client_key_data" {
  description = "Client key data"
  value       = local.client_key
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubeconfig content for the cluster"
  value       = local.kubeconfig_raw
  sensitive   = true
}
