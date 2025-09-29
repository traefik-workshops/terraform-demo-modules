variable "name" {
  type        = string
  description = "The name of the opentelemetry release"
  default     = "opentelemetry"
}

variable "namespace" {
  type        = string
  description = "The namespace of the opentelemetry release"
  default     = "traefik-observability"
}

variable "enable_prometheus" {
  type        = bool
  description = "Enable Prometheus observability module"
  default     = false
}

variable "prometheus_port" {
  type        = number
  description = "Prometheus port"
  default     = 8889
}

variable "enable_loki" {
  type        = bool
  description = "Enable Grafana Loki observability module"
  default     = false
}

variable "loki_endpoint" {
  type        = string
  description = "Loki endpoint"
  default     = ""
}

variable "enable_tempo" {
  type        = bool
  description = "Enable Grafana Tempo observability module"
  default     = false
}

variable "tempo_endpoint" {
  type        = string
  description = "Tempo endpoint"
  default     = ""
}

variable "enable_new_relic" {
  type        = bool
  description = "Enable New Relic observability module"
  default     = false
}

variable "newrelic_endpoint" {
  type        = string
  description = "New Relic endpoint"
  default     = ""
}

variable "newrelic_license_key" {
  type        = string
  description = "New Relic license key"
  default     = ""
}

variable "enable_dash0" {
  type        = bool
  description = "Enable Dash0 observability module"
  default     = false
}

variable "dash0_endpoint" {
  type        = string
  description = "Dash0 endpoint"
  default     = ""
}

variable "dash0_auth_token" {
  type        = string
  description = "Dash0 auth token"
  sensitive   = true
  default     = ""
}

variable "dash0_dataset" {
  type        = string
  description = "Dash0 dataset"
  default     = ""
}

variable "enable_honeycomb" {
  type        = bool
  description = "Enable Honeycomb observability module"
  default     = false
}

variable "honeycomb_endpoint" {
  type        = string
  description = "Honeycomb endpoint"
  default     = ""
}

variable "honeycomb_api_key" {
  type        = string
  description = "Honeycomb API key"
  sensitive   = true
  default     = ""
}

variable "honeycomb_dataset" {
  type        = string
  description = "Honeycomb dataset"
  default     = ""
}