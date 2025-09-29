variable "namespace" {
  type        = string
  description = "Namespace for the Grafana deployment"
}

variable "traefik_metrics_job_url" {
  type        = string
  description = "URL for the Traefik metrics job"
  default     = ""
}

variable "traefik_metrics_job_metrics_path" {
  type        = string
  description = "Metrics path for the Traefik metrics job"
  default     = "/metrics"
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

variable "extraValues" {
  type = object({})
  description = "Extra values to pass to the Grafana deployment."
  default     = {}
}
