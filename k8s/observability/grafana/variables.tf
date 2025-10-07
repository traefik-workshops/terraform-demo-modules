variable "name" {
  type        = string
  description = "The name of the grafana release"
  default     = "grafana"
}

variable "namespace" {
  type        = string
  description = "Namespace for the Grafana deployment"
}

variable "prometheus" {
  type = object({
    enabled = bool
    url     = object({
      override  = string
      service   = string
      port      = number
      namespace = string
    })
  })
  description = "Prometheus datasource configuration."
}

variable "tempo" {
  type = object({
    enabled = bool
    url     = object({
      override  = string
      service   = string
      port      = number
      namespace = string
    })
  })
  description = "Tempo datasource configuration."
}

variable "loki" {
  type = object({
    enabled = bool
    url     = object({
      override  = string
      service   = string
      port      = number
      namespace = string
    })
  })
  description = "Loki datasource configuration."
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

variable "extra_values" {
  type        = any
  description = "Extra values to pass to the Grafana deployment."
  default     = {}
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
