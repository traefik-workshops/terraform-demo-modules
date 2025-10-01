
variable "name" {
  type        = string
  description = "The name of the prometheus release"
  default     = "prometheus"
}

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
  type        = any
  description = "Extra values to pass to the Grafana deployment."
  default     = {}
}
