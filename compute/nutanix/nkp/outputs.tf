output "control_plane_fip" {
  description = "Control plane FIP"
  value       = local.control_plane_fip
}

output "kubeconfig" {
  description = "Kubeconfig content for the cluster"
  value       = try(data.local_file.kubeconfig.content, "")
  sensitive   = true
}
