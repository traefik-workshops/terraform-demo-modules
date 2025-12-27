output "kubeconfig" {
  description = "Kubeconfig content for the cluster (with FIP address)"
  value       = try(data.local_file.kubeconfig.content, "")
  sensitive   = true
}
