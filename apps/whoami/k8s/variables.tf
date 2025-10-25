variable "apps" {
  description = "Map of applications to deploy to Kubernetes. Each app can have multiple replicas."
  type        = any
  default     = {}
}

variable "namespace" {
  description = "Kubernetes namespace to deploy applications"
  type        = string
  default     = "apps"
}

variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default     = {}
}
