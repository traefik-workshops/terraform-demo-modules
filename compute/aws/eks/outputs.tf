data "aws_eks_cluster_auth" "eks" {
  name = var.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster host"
  value       = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  sensitive   = true
  description = "EKS cluster CA certificate"
  value       = base64decode(module.eks.cluster_certificate_authority_data)
}

output "token" {
  sensitive   = true
  description = "EKS cluster auth token"
  value       = data.aws_eks_cluster_auth.eks.token
}
