output "host" {
  description = "EKS cluster host"
  value = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "EKS cluster CA certificate"
  value = base64decode(module.eks.cluster_certificate_authority_data)
}
