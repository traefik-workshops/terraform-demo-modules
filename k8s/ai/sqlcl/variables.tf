variable "name" {
  type        = string
  description = "The name of the sqlcl-mcp Deployment and Service"
  default     = "sqlcl-mcp"
}

variable "namespace" {
  type        = string
  description = "The namespace of the sqlcl-mcp Deployment and Service"
}

variable "replicas" {
  type    = number
  default = 1
}

variable "image" {
  type    = string
  default = "zalbiraw/sqlcl:latest"
}

variable "service_port" {
  type    = number
  default = 8096
}

variable "container_port" {
  type    = number
  default = 8096
}

variable "ingress" {
  type        = bool
  default     = false
  description = "Enable Ingress for the sqlcl-mcp service"
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
