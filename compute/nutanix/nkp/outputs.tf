output "control_plane_vip" {
  description = "Control plane VIP (internal to VPC)"
  value       = var.control_plane_vip
}

output "kubeconfig" {
  description = "Kubeconfig content for the cluster"
  value       = try(data.local_file.kubeconfig.content, "")
  sensitive   = true
}
