variable "arch" {
  type        = string
  description = "The architecture (amd64, arm64)"
  default     = "amd64"
}

variable "traefik_hub_version" {
  type        = string
  description = "The Traefik Hub version to download"
}

variable "cli_arguments" {
  type        = list(string)
  description = "CLI arguments for Traefik Hub"
  default     = []
}

variable "env_vars" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "Environment variables for Traefik Hub"
  default     = []
}

variable "file_provider_config" {
  type        = string
  description = "Dynamic configuration for the file provider"
  default     = ""
}

variable "dashboard_config" {
  type        = string
  description = "Dashboard configuration"
  default     = ""
}

variable "performance_tuning" {
  type = object({
    limit_nofile        = number
    gomaxprocs          = number
    gogc                = number
    tcp_tw_reuse        = number
    tcp_timestamps      = number
    rmem_max            = number
    wmem_max            = number
    somaxconn           = number
    netdev_max_backlog  = number
    ip_local_port_range = string
    numa_node           = number
  })
  description = "Performance tuning settings"
  default = {
    limit_nofile        = 500000
    gomaxprocs          = 0
    gogc                = 100
    tcp_tw_reuse        = 1
    tcp_timestamps      = 1
    rmem_max            = 16777216
    wmem_max            = 16777216
    somaxconn           = 4096
    netdev_max_backlog  = 4096
    ip_local_port_range = "1024 65535"
    numa_node           = -1
  }
}

variable "vip" {
  type        = string
  description = "Virtual IP for Keepalived"
  default     = ""
}

variable "keepalived_priority" {
  type        = number
  description = "Priority for Keepalived VRRP"
  default     = 100
}

variable "network_interface" {
  type        = string
  description = "Network interface for Keepalived"
  default     = "ens3"
}

variable "otlp_address" {
  type        = string
  description = "OTLP endpoint URL (e.g. https://collector.example.com)"
  default     = ""
}

variable "instance_name" {
  type        = string
  description = "Unique name for this instance (used for metrics identity)"
  default     = "traefik-node"
}

output "rendered" {
  value = templatefile("${path.module}/cloud-init.tpl", {
    traefik_hub_version  = var.traefik_hub_version
    arch                 = var.arch
    cli_arguments        = var.cli_arguments
    env_vars             = var.env_vars
    file_provider_config = var.file_provider_config
    dashboard_config     = var.dashboard_config
    performance_tuning   = var.performance_tuning
    vip                  = var.vip
    keepalived_priority  = var.keepalived_priority
    network_interface    = var.network_interface
    otlp_address         = var.otlp_address
    instance_name        = var.instance_name
  })
}
