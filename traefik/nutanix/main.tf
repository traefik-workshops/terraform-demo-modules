# =============================================================================
# Nutanix VM Traefik Deployment
# =============================================================================
# Uses extracted config from traefik/shared module (via Helm template).
# =============================================================================

locals {
  # CLI arguments from shared module
  cli_arguments = concat(
    module.config.extracted_cli_args_cloud,
    [
      "--providers.file.directory=/etc/traefik-hub/dynamic",
      "--providers.file.watch=true"
    ]
  )

  # Extract ports from entry points
  ports_to_open = [
    for ep in module.config.entry_points :
    replace(ep.address, ":", "")
  ]

  # Dashboard configuration
  dashboard_config = var.enable_dashboard ? yamlencode({
    http = {
      routers = {
        dashboard = {
          rule        = var.dashboard_match_rule != "" ? var.dashboard_match_rule : "Host(`dashboard.localhost`)"
          service     = "api@internal"
          entryPoints = var.dashboard_entrypoints
          tls = var.cloudflare_dns.enabled ? {
            certResolver = "cf"
          } : {}
        }
      }
    }
  }) : ""

  # Traefik instances tagged for service discovery (always enabled with defaults)
  traefik_categories = {
    "TraefikServiceName" = "traefik"
    "TraefikServicePort" = "80"
  }
}

module "traefik_vm" {
  source = "../../compute/nutanix/vm"

  name                 = var.vm_name
  cluster_uuid         = var.cluster_id
  subnet_uuid          = var.subnet_uuid
  image_uuid           = var.image_id
  num_vcpus_per_socket = var.vm_num_vcpus_per_socket
  num_sockets          = var.vm_num_sockets
  memory_size_mib      = var.vm_memory_mib

  categories = local.traefik_categories

  cloud_init_user_data = templatefile("${path.module}/cloud-init.tpl", {
    # Use computed CLI arguments
    cli_arguments = local.cli_arguments

    # Environment variables
    env_vars = concat(
      module.config.env_vars_list,
      module.config.traefik_hub_token != "" ? [{ name = "HUB_TOKEN", value = module.config.traefik_hub_token }] : []
    )

    # File provider config (user-provided)
    file_provider_config = var.file_provider_config

    # Dashboard Config
    dashboard_config = local.dashboard_config

    # Dynamic ports for firewall
    ports_to_open = local.ports_to_open

    # Cloudflare DNS flag for conditional ACME setup
    cloudflare_dns_enabled = module.config.cloudflare_dns.enabled

    # Keepalived config
    vip                 = var.vip
    keepalived_priority = var.keepalived_priority
    network_interface   = var.network_interface
  })
}

output "ip_address" {
  value = module.traefik_vm.ip_address
}
