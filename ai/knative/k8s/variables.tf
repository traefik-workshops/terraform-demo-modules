variable "name" {
  type        = string
  description = "The name of the knative release"
  default     = "knative"
}

variable "namespace" {
  type        = string
  description = "The namespace of the knative release"
}
  