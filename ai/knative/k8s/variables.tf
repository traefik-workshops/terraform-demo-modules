variable "name" {
  type        = string
  description = "The name of the knative release"
  default     = "knative"
}

variable "namespace" {
  type        = string
  description = "The namespace of the knative release"
}

variable "ingress_domain" {
  type        = string
  description = "The external domain where knative will publish services. Eg. knative.kubeata.traefikhub.dev will result in <service>.<namespace>.knative.kubeata.traefikhub.dev ingresses"
  default     = "knative.kubeata.traefikhub.dev"
}
