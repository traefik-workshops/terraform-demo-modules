variable "enable_api_gateway" {
  description = "Enable Traefik Hub API Gateway features"
  type        = bool
  default     = false
}

variable "enable_preview_mode" {
  description = "Enable Traefik Hub Preview features"
  type        = bool
  default     = false
}

variable "enable_offline_mode" {
  description = "Enable Traefik Hub Offline features"
  type        = bool
  default     = false
}

variable "traefik_tag" {
  description = "Traefik tag"
  type        = string
  default     = "v3.5.2"
}

variable "traefik_hub_tag" {
  description = "Traefik Hub tag"
  type        = string
  default     = "v3.18.0-rc.1"
}

variable "traefik_hub_preview_tag" {
  description = "Traefik Hub preview tag"
  type        = string
  default     = ""
}

variable "dashboard_match_rule" {
  description = "Dashboard match rule (not applicable in EC2, dashboard available on port 8080)"
  type        = string
  default     = ""
}

variable "dashboard_entrypoints" {
  description = "Dashboard entry points (not applicable in EC2)"
  type        = list(string)
  default     = ["traefik"]
}

variable "replicaCount" {
  description = "Number of replicas for the Traefik deployment"
  type        = number
  default     = 1
}

variable "log_level" {
  description = "Log level for Traefik"
  type        = string
  default     = "INFO"
  
  validation {
    condition     = contains(["DEBUG", "INFO", "WARN", "ERROR"], var.log_level)
    error_message = "Log level must be one of: DEBUG, INFO, WARN, ERROR"
  }
}

variable "traefik_license" {
  description = "Traefik Hub license key (token)"
  type        = string
  default     = ""
  sensitive   = true

  validation {
    condition     = (var.enable_api_gateway == false && var.enable_preview_mode == false) || var.traefik_license != ""
    error_message = "Traefik license key is required when enable_api_gateway or enable_preview_mode is true"
  }
}

variable "otlp_service_name" {
  description = "OTLP service name"
  type        = string
  default     = "traefik"
}

variable "otlp_address" {
  description = "OTLP collector address"
  type        = string
  default     = "http://opentelemetry-collector:4318"
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

variable "custom_plugins" {
  type        = map(object({
    moduleName = string
    version    = string
  }))
  description = "Custom plugins to use for the deployment (requires plugin loading mechanism)"
  default     = {}
}

variable "custom_ports" {
  type        = map(object({
    port     = number
    protocol = optional(string, "tcp")
  }))
  description = "Custom ports to expose for the deployment"
  default     = {}
}

variable "custom_arguments" {
  type        = list(string)
  description = "Custom arguments to pass to Traefik"
  default     = []
}

variable "custom_envs" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "Custom environment variables for the deployment"
  default     = []
}

variable "is_staging_letsencrypt" {
  description = "Use Let's Encrypt staging environment"
  type        = bool
  default     = false
}

variable "cloudflare_dns" {
  description = "Cloudflare DNS configuration for certificate resolver"
  type = object({
    enabled   = optional(bool, false)
    domain    = optional(string, "")
    api_token = optional(string, "")
  })
  default = {
    enabled   = false
    domain    = ""
    api_token = ""
  }
  sensitive = true
}

# EC2-specific variables

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "create_vpc" {
  description = "Create VPC if vpc_id is not provided"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID for EC2 instances"
  type        = string
  default     = ""

  validation {
    condition     = var.create_vpc || var.vpc_id != ""
    error_message = "vpc_id must be provided if create_vpc is false"
  }
}

variable "subnet_ids" {
  description = "List of subnet IDs for EC2 instances"
  type        = list(string)
  default     = []

  validation {
    condition     = var.create_vpc || length(var.subnet_ids) > 0
    error_message = "subnet_ids must be provided if create_vpc is false"
  }
}

variable "security_group_ids" {
  description = "List of security group IDs for EC2 instances"
  type        = list(string)
  default     = []

  validation {
    condition     = var.create_vpc || length(var.security_group_ids) > 0
    error_message = "security_group_ids must be provided if create_vpc is false"
  }
}

variable "iam_instance_profile" {
  description = "IAM instance profile name to attach to EC2 instances"
  type        = string
  default     = ""
}
