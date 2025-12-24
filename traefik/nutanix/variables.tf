variable "vm_name" {
  description = "Name of the VM"
  type        = string
}

variable "cluster_id" {
  description = "UUID of the Nutanix Cluster"
  type        = string
}

variable "subnet_uuid" {
  description = "UUID of the Subnet"
  type        = string
}

variable "image_id" {
  description = "UUID of the Image to use"
  type        = string
}

variable "arch" {
  description = "Architecture of the VM"
  type        = string
  default     = "amd64"
}

variable "vm_num_vcpus_per_socket" {
  description = "Number of vCPUs per socket"
  type        = number
  default     = 1
}

variable "vm_num_sockets" {
  description = "Number of sockets"
  type        = number
  default     = 1
}

variable "vm_memory_mib" {
  description = "Memory size in MiB"
  type        = number
  default     = 2048
}

variable "traefik_hub_token" {
  description = "Traefik Hub Token"
  type        = string
  sensitive   = true
}

variable "traefik_static_config" {
  description = "Traefik static configuration (YAML string)"
  type        = string
  default     = ""
}

variable "entry_points" {
  description = "Traefik entry points configuration"
  type = map(object({
    address = string
  }))
  default = {
    web = { address = ":80" }
  }
}

variable "enable_dashboard" {
  description = "Enable Traefik Dashboard"
  type        = bool
  default     = true
}

variable "dashboard_insecure" {
  description = "Enable insecure dashboard (HTTP)"
  type        = bool
  default     = false
}

variable "log_level" {
  description = "Traefik log level"
  type        = string
  default     = "INFO"
}

variable "enable_prometheus" {
  description = "Enable Prometheus metrics"
  type        = bool
  default     = true
}

variable "metrics_port" {
  description = "Port for metrics"
  type        = number
  default     = 8082
}

# OTLP Configuration
variable "otlp_address" {
  description = "OTLP gRPC endpoint (e.g. localhost:4317)"
  type        = string
  default     = ""
}

variable "otlp_service_name" {
  description = "Service name for OTLP traces/metrics"
  type        = string
  default     = "traefik"
}

variable "enable_otlp_metrics" {
  description = "Enable OTLP metrics"
  type        = bool
  default     = false
}

variable "enable_otlp_traces" {
  description = "Enable OTLP traces"
  type        = bool
  default     = false
}

variable "enable_otlp_access_logs" {
  description = "Enable OTLP access logs. Requires enable_otlp_traces = true or enable_otlp_metrics = true usually, but handled by otlp.http/grpc config"
  type        = bool
  default     = false
}

variable "enable_otlp_application_logs" {
  description = "Enable OTLP application logs (requires Traefik v3+ logic)"
  type        = bool
  default     = false
}

# Custom Extensions
variable "custom_plugins" {
  description = "Map of custom plugins configuration"
  type        = map(any)
  default     = {}
}

variable "custom_envs" {
  description = "Map of custom environment variables to inject into Traefik"
  type        = map(string)
  default     = {}
}

variable "file_provider_config" {
  description = "Additional dynamic configuration for file provider"
  type        = string
  default     = ""
}
