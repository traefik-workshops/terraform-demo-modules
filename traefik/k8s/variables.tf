# =============================================================================
# K8s-specific Variables
# =============================================================================
# Shared Traefik variables are defined in shared.tf.
# This file contains only K8s platform-specific variables.
# =============================================================================

variable "name" {
  description = "The name of the traefik release"
  type        = string
  default     = "traefik"
}

variable "namespace" {
  description = "Namespace for the Traefik Hub deployment"
  type        = string
}

variable "deploymentType" {
  description = "Traefik deployment type"
  type        = string
  default     = "Deployment"
}

variable "replicaCount" {
  description = "Number of replicas for the Traefik Hub deployment"
  type        = number
  default     = 1
}

variable "serviceType" {
  description = "Traefik service type"
  type        = string
  default     = "LoadBalancer"
}

variable "resources" {
  description = "Resources for the Traefik deployment"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "0"
      memory = "0"
    }
    limits = {
      cpu    = "0"
      memory = "0"
    }
  }
}

variable "tolerations" {
  description = "Tolerations for the Traefik deployment"
  type = list(object({
    key      = string
    operator = string
    value    = string
    effect   = string
  }))
  default = []
}

variable "redis_password" {
  description = "Redis password for API Management"
  type        = string
  default     = "topsecretpassword"
}

variable "skip_crds" {
  description = "Skip CRD installation (for NKP/Kommander clusters with pre-installed CRDs)"
  type        = bool
  default     = false
}

variable "enable_knative_provider" {
  description = "Enable Knative provider"
  type        = bool
  default     = false
}

variable "nginx_provider_enabled" {
  description = "Enable NGINX provider"
  type        = bool
  default     = false
}

variable "custom_providers" {
  type        = any
  description = "Custom providers to use for the deployment"
  default     = {}
}

variable "custom_objects" {
  type        = list(object({}))
  description = "Extra Kubernetes objects to deploy"
  default     = []
}

variable "extra_values" {
  type        = any
  description = "Extra Helm values to merge"
  default     = {}
}

variable "kubernetes_namespaces" {
  description = "List of namespaces to watch for Kubernetes providers (Ingress, Gateway, CRD)"
  type        = list(string)
  default     = []
}
