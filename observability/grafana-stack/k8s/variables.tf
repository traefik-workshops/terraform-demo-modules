variable "namespace" {
  type        = string
  description = "Namespace for the Grafana deployment"
}

variable "tolerations" {
  type = list(object({
    key      = string
    operator = string
    value    = string
    effect   = string
  }))
  description = "Tolerations for the Grafana deployment."
  default     = []
}

variable "metrics_host" {
  type        = string
  description = "Host of metrics endpoint"
  default     = ""
}

variable "metrics_port" {
  type        = number
  description = "Port of metrics endpoint"
  default     = 8889
}

variable "ingress" {
  type        = bool
  description = "Enable Ingress for the Grafana deployment."
  default     = false
}

variable "ingress_domain" {
  type        = string
  default     = "cloud"
  description = "The domain for the ingress, default is `cloud`"
}

variable "ingress_entrypoint" {
  type        = string
  default     = "traefik"
  description = "The entrypoint to use for the ingress, default is `traefik`"
}

variable "dashboards" {
  type = object({
    aigateway  = bool
    mcpgateway = bool
    apim       = bool
  })
}
