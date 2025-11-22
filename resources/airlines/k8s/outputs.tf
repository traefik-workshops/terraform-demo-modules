output "application_name" {
  description = "Name of the ArgoCD application"
  value       = argocd_application.airlines.metadata[0].name
}

output "dashboard_url" {
  description = "Public URL of the Ops dashboard"
  value       = "https://ops.${var.domain}"
}
