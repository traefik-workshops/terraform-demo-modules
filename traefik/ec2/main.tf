# =============================================================================
# EC2 Traefik Deployment
# =============================================================================
# Uses extracted config from traefik/shared module (via Helm template).
# =============================================================================

locals {
  # Use extracted CLI arguments from Helm template (includes file provider if configured)
  # Uses centralized filtering to exclude Kubernetes-specific args
  traefik_arguments = module.config.extracted_cli_args_cloud

  # Build environment variables for Docker run command
  env_vars = [
    for env in module.config.env_vars_list : "-e ${env.name}='${env.value}'"
  ]

  # Build port mappings from shared module ports
  port_mappings = [
    for port in module.config.ports_list : "-p ${port}:${port}"
  ]

  # Use shared module for image reference
  traefik_image = module.config.image_full

  # Build Docker run options (flags that come before the image)
  # Include file provider volume mount if configured
  docker_options = join(" ", concat(
    local.env_vars,
    local.port_mappings,
    ["-v /var/run/docker.sock:/var/run/docker.sock"],
    ["-v traefik-data:/data"],
    var.file_provider_config != "" ? ["-v /etc/traefik/dynamic.yaml:/etc/traefik/dynamic.yaml:ro"] : []
  ))

  # Build container arguments (Traefik flags that come after the image)
  # Wrap each argument in single quotes and escape any single quotes within
  container_arguments = join(" ", [
    for arg in local.traefik_arguments :
    "'${replace(arg, "'", "'\\''")}'"
  ])
}

module "ec2" {
  source = "../../compute/aws/ec2"

  apps = {
    traefik = {
      replicas            = module.config.replica_count
      port                = 80
      docker_image        = local.traefik_image
      docker_options      = local.docker_options
      container_arguments = local.container_arguments
      subnet_ids          = var.subnet_ids
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
}
