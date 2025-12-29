# =============================================================================
# Nutanix VM Traefik Deployment
# =============================================================================
# Uses extracted config from traefik/shared module (via Helm template).
# =============================================================================

locals {
  cli_arguments = module.config.extracted_cli_args
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

    # Use extracted environment variables
    env_vars = module.config.env_vars_list

    # File provider config (user-provided)
    file_provider_config = var.file_provider_config
  })
}

output "ip_address" {
  value = module.traefik_vm.ip_address
}
