# =============================================================================
# Nutanix VM Traefik Deployment
# =============================================================================
# Uses extracted config from traefik/shared module (via Helm template).
# =============================================================================

locals {
  cli_arguments = module.config.extracted_cli_args_cloud

  # Extract ports from entry points (e.g. ":80" -> "80")
  ports_to_open = [
    for ep in module.config.entry_points :
    replace(ep.address, ":", "")
  ]
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

  cloud_init_user_data = templatefile("${path.module}/cloud-init.tpl", {
    # Use computed CLI arguments
    cli_arguments = local.cli_arguments

    # Use extracted environment variables (plus Hub Token which is usually a Secret in K8s)
    env_vars = concat(
      module.config.env_vars_list,
      module.config.traefik_hub_token != "" ? [{ name = "HUB_TOKEN", value = module.config.traefik_hub_token }] : []
    )

    # File provider config (user-provided)
    file_provider_config = var.file_provider_config

    # Dynamic ports for firewall
    ports_to_open = local.ports_to_open

    # Cloudflare DNS flag for conditional ACME setup
    cloudflare_dns_enabled = module.config.cloudflare_dns.enabled
  })
}

output "ip_address" {
  value = module.traefik_vm.ip_address
}
