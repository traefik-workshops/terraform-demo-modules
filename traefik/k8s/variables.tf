variable "name" {
  description = "The name of the traefik release"
  type        = string
  default     = "traefik"
}

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
  default     = "v37.4.0"
}

variable "traefik_tag" {
  description = "Traefik tag"
  type        = string
  default     = "v3.6.4"
}

variable "traefik_hub_tag" {
  description = "Traefik Hub tag"
  type        = string
  default     = "v3.18.0"
}

variable "traefik_hub_preview_tag" {
  description = "Traefik Hub preview tag"
  type        = string
  default     = ""
}

variable "redis_password" {
  description = "Redis password"
  type        = string
  default     = "topsecretpassword"
}

variable "dashboard_match_rule" {
  description = "Dashboard match rule"
  type        = string
  default     = "Host(`dashboard.cloud`) || Host(`dashboard.localhost`)"
}

variable "dashboard_entrypoints" {
  description = "Dashboard entry points"
  type        = list(string)
  default     = ["traefik"]
}

variable "deploymentType" {
  description = "Traefik deployment type."
  type        = string
  default     = "Deployment"
}

variable "replicaCount" {
  description = "Number of replicas for the Traefik Hub deployment"
  type        = number
  default     = 1
}

variable "serviceType" {
  description = "Traefik service type."
  type        = string
  default     = "LoadBalancer"
}

variable "resources" {
  description = "Resources for the Traefik deployment"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })

  default = {
    requests = {
      cpu    = "0"
      memory = "0"
    }
    limits = {
      cpu    = "0"
      memory = "0"
    }
  }
}

variable "tolerations" {
  description = "Tolerations for the Traefik deployment"
  type = list(object({
    key      = string
    operator = string
    value    = string
    effect   = string
  }))

  default = []
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

variable "otlp_service_name" {
  description = "OTLP service name"
  type        = string
  default     = "traefik"
}

variable "otlp_address" {
  description = "OTLP address"
  type        = string
  default     = ""
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
  type = map(object({
    moduleName = string
    version    = string
  }))
  description = "Custom plugins to use for the deployment"
  default     = {}
}

variable "custom_ports" {
  type        = any
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
  type = list(object({
    name  = string
    value = string
  }))
  description = "Custom environment variables to use for the deployment"
  default     = []
}

variable "extra_values" {
  type        = any
  description = "Extra values to use for the deployment"
  default     = {}
}

variable "is_staging_letsencrypt" {
  description = "Use Let's Encrypt staging environment"
  type        = bool
  default     = false
}

variable "enable_mcp_gateway" {
  description = "Enable MCP Gateway"
  type        = bool
  default     = false
}

variable "enable_knative_provider" {
  description = "Enable Knative provider"
  type        = bool
  default     = false
}

variable "cloudflare_dns" {
  description = "Cloudflare DNS configuration"
  type = object({
    enabled           = optional(bool, false)
    domain            = optional(string, "")
    api_token         = optional(string, "")
    extra_san_domains = optional(list(string), [])
  })
  default = {
    enabled           = false
    domain            = ""
    api_token         = ""
    extra_san_domains = []
  }
}
variable "custom_providers" {
  type        = any
  description = "Custom providers to use for the deployment"
  default     = {}
}

variable "file_provider_config" {
  type        = string
  description = "YAML configuration for Traefik file provider. This will be mounted as a ConfigMap and used for dynamic configuration."
  default     = ""
}

variable "custom_image_registry" {
  description = "Custom image registry"
  type        = string
  default     = ""
}

variable "custom_image_repository" {
  description = "Custom image repository"
  type        = string
  default     = ""
}

variable "custom_image_tag" {
  description = "Custom image tag"
  type        = string
  default     = ""
}

variable "nginx_provider_enabled" {
  description = "Enable NGINX provider"
  type        = bool
  default     = false
}

variable "nginx_provider_migration" {
  description = "NGINX provider migration configuration"
  type        = any
  default     = {}
}
