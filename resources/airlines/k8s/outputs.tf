output "airlines_domain" {
  value       = var.unique_domain ? try(data.kubernetes_secret.domain_secret[0].data["domain"], "Use 'terraform refresh' to fetch value") : "airlines.${var.domain}"
  description = "The domain of the airlines application"
}
