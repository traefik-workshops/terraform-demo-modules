variable "name" {
  description = "The name of the ArgoCD release"
  type        = string
  default     = "argocd"
}

variable "namespace" {
  description = "Namespace for the ArgoCD deployment"
  type        = string
}

variable "admin_password" {
  description = "Admin password for ArgoCD"
  type        = string
  sensitive   = true
}