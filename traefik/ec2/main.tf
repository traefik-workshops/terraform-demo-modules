locals {
  # Build Traefik container arguments similar to K8s implementation
  traefik_arguments = concat(
    [
      "--api.dashboard=true",
      "--api.insecure=true",
      "--entrypoints.web.address=:80",
      "--entrypoints.websecure.address=:443",
      "--entrypoints.traefik.address=:8080",
      "--log.level=${var.log_level}",
      "--accesslog=true",
      "--accesslog.filters.statuscodes=200-599",
    ],
    var.enable_api_gateway || var.enable_preview_mode ? [
      "--hub.token=${var.traefik_license}",
    ] : [],
    var.enable_preview_mode ? [
      "--hub.platformUrl=https://api-preview.hub.traefik.io/agent",
    ] : [],
    var.enable_offline_mode ? [
      "--hub.offline=true",
    ] : [],
    var.enable_otlp_access_logs ? [
      "--experimental.otlpLogs=true",
      "--accesslog.otlp.http.tls.insecureSkipVerify=true",
      "--accesslog.otlp.http.endpoint=${var.otlp_address}/v1/logs",
    ] : [],
    var.enable_otlp_application_logs ? [
      "--experimental.otlpLogs=true",
      "--log.otlp.http.tls.insecureSkipVerify=true",
      "--log.otlp.http.endpoint=${var.otlp_address}/v1/logs",
    ] : [],
    var.enable_otlp_metrics ? [
      "--metrics.otlp=true",
      "--metrics.otlp.serviceName=${var.otlp_service_name}",
      "--metrics.otlp.http.endpoint=${var.otlp_address}/v1/metrics",
      "--metrics.otlp.http.tls.insecureSkipVerify=true",
    ] : [],
    var.enable_otlp_traces ? [
      "--tracing.otlp=true",
      "--tracing.serviceName=${var.otlp_service_name}",
      "--tracing.otlp.http.endpoint=${var.otlp_address}/v1/traces",
      "--tracing.otlp.http.tls.insecureSkipVerify=true",
    ] : [],
    var.cloudflare_dns.enabled ? [
      "--certificatesresolvers.cf.acme.dnschallenge=true",
      "--certificatesresolvers.cf.acme.dnschallenge.provider=cloudflare",
      "--certificatesresolvers.cf.acme.email=zaid@traefik.io",
      "--certificatesresolvers.cf.acme.storage=/data/acme.json",
      "--certificatesresolvers.cf.acme.caserver=${var.is_staging_letsencrypt ? "https://acme-staging-v02.api.letsencrypt.org/directory" : "https://acme-v02.api.letsencrypt.org/directory"}",
    ] : [],
    var.custom_arguments
  )

  # Build environment variables for Docker run command
  env_vars = concat(
    var.cloudflare_dns.enabled ? [
      "-e CF_DNS_API_TOKEN='${var.cloudflare_dns.api_token}'",
    ] : [],
    [for env in var.custom_envs : "-e ${env.name}='${env.value}'"]
  )

  # Build port mappings
  port_mappings = concat(
    [
      "-p 80:80",
      "-p 443:443",
      "-p 8080:8080",
    ],
    [for port_name, port_config in var.custom_ports : "-p ${port_config.port}:${port_config.port}"]
  )

  # Determine Traefik image
  traefik_image = var.enable_api_gateway || var.enable_preview_mode ? (
    var.enable_preview_mode ? 
      "europe-west9-docker.pkg.dev/traefiklabs/traefik-hub/traefik-hub:${var.traefik_hub_preview_tag != "" ? var.traefik_hub_preview_tag : "latest-v3"}" :
      "ghcr.io/traefik/traefik-hub:${var.traefik_hub_tag}"
  ) : "traefik:${var.traefik_tag}"

  # Build Docker run options (flags that come before the image)
  docker_options = join(" ", concat(
    local.env_vars,
    local.port_mappings,
    ["-v /var/run/docker.sock:/var/run/docker.sock"],
    ["-v traefik-data:/data"]
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
      replicas            = var.replicaCount
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
  
  common_tags = merge(var.extra_tags, {
    "Name"                                                     = "traefik"
    "traefik.enable"                                           = "true"
    "traefik.http.routers.dashboard.rule"                      = var.dashboard_match_rule
    "traefik.http.routers.dashboard.entrypoints"               = var.dashboard_entrypoints[0]
    "traefik.http.services.dashboard.loadbalancer.server.port" = "8080"
  })
}
