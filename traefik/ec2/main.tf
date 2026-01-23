# =============================================================================
# EC2 Traefik Deployment
# =============================================================================
# Uses extracted config from traefik/shared module (via Helm template).
# =============================================================================

locals {
  # Use extracted CLI arguments from Helm template (includes file provider if configured)
  # Filter out placeholder token arg to avoid duplicates with manual injection in Systemd unit
  cli_arguments = concat(
    [
      for arg in module.config.extracted_cli_args_cloud :
      arg if !startswith(arg, "--hub.token=")
    ],
    [
      "--providers.file.directory=/etc/traefik-hub/dynamic",
      "--providers.file.watch=true"
    ]
  )

  # Build environment variables list
  # Merge standard env vars with explicit HUB_TOKEN injection (Nutanix pattern)
  env_vars_list = concat(
    module.config.env_vars_list,
    module.config.traefik_hub_token != "" ? [{ name = "HUB_TOKEN", value = module.config.traefik_hub_token }] : []
  )

  # Use shared module for image reference
  traefik_image = module.config.image_full
}

module "ec2" {
  source = "../../compute/aws/ec2"

  apps = {
    traefik = {
      replicas   = module.config.replica_count
      subnet_ids = var.subnet_ids
    }
  }

  instance_type        = var.instance_type
  create_vpc           = var.create_vpc
  vpc_id               = var.vpc_id
  security_group_ids   = var.security_group_ids
  iam_instance_profile = var.iam_instance_profile
  enable_acme_setup    = module.config.cloudflare_dns.enabled

  common_tags = merge(var.extra_tags, {
    "Name"                                                     = "traefik"
    "traefik.enable"                                           = "true"
    "traefik.http.routers.dashboard.rule"                      = module.config.dashboard_match_rule
    "traefik.http.routers.dashboard.entrypoints"               = module.config.dashboard_entrypoints[0]
    "traefik.http.services.dashboard.loadbalancer.server.port" = "8080"
  })

  # Override default Docker user data with our Systemd service extraction script
  user_data_override = templatefile("${path.module}/cloud-init.tpl", {
    traefik_image        = local.traefik_image
    cli_arguments        = local.cli_arguments
    env_vars             = local.env_vars_list
    file_provider_config = var.file_provider_config
    otlp_address         = var.otlp_address
  })
}
