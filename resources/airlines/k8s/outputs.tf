output "airlines_domain" {
  value       = var.unique_domain ? "Value stored in Kubernetes Secret 'domain-secret'" : "airlines.${var.domain}"
  description = "The domain of the airlines application"
}
