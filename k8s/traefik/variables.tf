variable "namespace" {
  description = "Namespace for the Traefik Hub deployment"
  type        = string
}

variable "enable_api_gateway" {
  description = "Enable Traefik Hub API Gateway features"
  type        = bool
}

variable "enable_ai_gateway" {
  description = "Enable Traefik Hub AI Gateway features"
  type        = bool
}

variable "enable_api_management" {
  description = "Enable Traefik Hub API Management features (includes API Gateway features)"
  type        = bool
}

variable "enable_preview_mode" {
  description = "Enable Traefik Hub Preview features"
  type        = bool
  default     = false
}

variable "enable_offline_mode" {
  description = "Enable Traefik Hub Offline features"
  type        = bool
}

variable "traefik_chart_version" {
  description = "Traefik chart version"
  type        = string
}

variable "traefik_hub_tag" {
  description = "Traefik Hub tag"
  type        = string
}

variable "redis_password" {
  description = "Redis password"
  type        = string
  default     = "topsecretpassword"
}

variable "dashboard_match_rule" {
  description = "Dashboard match rule"
  type        = string
  default     = "Host(`dashboard.traefik.cloud`) || Host(`dashboard.traefik.localhost`)"
}

variable "replicaCount" {
  description = "Number of replicas for the Traefik Hub deployment"
  type        = number
  default     = 1
}

variable "log_level" {
  description = "Log level for Traefik Hub"
  type        = string
  default     = "INFO"
}

variable "traefik_license" {
  description = "Traefik license key"
  type        = string
  default     = ""

  validation {
    condition     = (var.enable_api_gateway == false && var.enable_api_management == false) || var.traefik_license != ""
    error_message = "Traefik license key is required when enable_api_gateway or enable_api_management is true"
  }
}

variable "enable_otlp_access_logs" {
  type        = bool
  description = "Enable OTLP access logs"
  default     = false
}

variable "enable_otlp_application_logs" {
  type        = bool
  description = "Enable OTLP application logs"
  default     = false
}

variable "enable_otlp_metrics" {
  type        = bool
  description = "Enable OTLP metrics"
  default     = false
}

variable "enable_otlp_traces" {
  type        = bool
  description = "Enable OTLP traces"
  default     = false
}

variable "enable_prometheus" {
  description = "Enable Prometheus observability module"
  type        = bool
  default     = false
}

variable "custom_plugins" {
  type        = map(object({
    moduleName = string
    version    = string
  }))
  description = "Custom plugins to use for the deployment"
  default     = {}
}

variable "custom_ports" {
  type        = map(object({
    expose = object({
      default = bool
    })
    port = number
    exposePort = number
  }))
  description = "Custom ports to use for the deployment"
  default     = {}
}

variable "custom_arguments" {
  type        = list(string)
  description = "Custom arguments to use for the deployment"
  default     = []
}

variable "custom_objects" {
  type        = list(object({}))
  description = "Extra objects to use for the deployment"
  default     = []
}

variable "custom_envs" {
  type        = list(object({
    name  = string
    value = string
  }))
  description = "Custom environment variables to use for the deployment"
  default     = []
}
