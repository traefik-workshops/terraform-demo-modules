variable "name" {
  description = "The name of the k6 release"
  type        = string
  default     = "k6-operator"
}

variable "namespace" {
  description = "Namespace for the k6 deployment"
  type        = string
}

variable "node_selector" {
  description = "Node selector for pod scheduling"
  type        = map(string)
  default     = {}
}
