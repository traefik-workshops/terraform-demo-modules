variable "name" {
  type        = string
  description = "The name of the mcp-inspector Deployment and Service"
  default     = "mcp-inspector"
}

variable "namespace" {
  type        = string
  description = "The namespace of the mcp-inspector Deployment and Service"
}

variable "replicas" {
  type    = number
  default = 1
}

variable "ingress" {
  type        = bool
  default     = false
  description = "Enable Ingress for the mcp-inspector service"
}

variable "ingress_domain" {
  type        = string
  default     = "cloud"
  description = "The domain for the ingress, default is `cloud`"
}

variable "ingress_entrypoint" {
  type        = string
  default     = "web"
  description = "The entrypoint to use for the ingress, default is `web`"
}
