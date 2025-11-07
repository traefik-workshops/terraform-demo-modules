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

  # Build environment variables
  traefik_envs = concat(
    var.cloudflare_dns.enabled ? [
      {
        name  = "CF_DNS_API_TOKEN"
        value = var.cloudflare_dns.api_token
      }
    ] : [],
    var.custom_envs
  )

  # Determine Traefik image
  traefik_image = var.enable_api_gateway || var.enable_preview_mode ? (
    var.enable_preview_mode ? 
      "europe-west9-docker.pkg.dev/traefiklabs/traefik-hub/traefik-hub:${var.traefik_hub_preview_tag != "" ? var.traefik_hub_preview_tag : "latest-v3"}" :
      "ghcr.io/traefik/traefik-hub:${var.traefik_hub_tag}"
  ) : "traefik:${var.traefik_tag}"

  # Build Docker labels from custom ports
  docker_labels = merge(var.extra_labels, {
    for port_name, port_config in var.custom_ports : 
      "traefik.http.routers.${port_name}.entrypoints" => port_name
  },
  {
    "traefik.enable"                                           = "true"
    "traefik.http.routers.dashboard.rule"                      = var.dashboard_match_rule
    "traefik.http.routers.dashboard.entrypoints"               = var.dashboard_entrypoints[0]
    "traefik.http.services.dashboard.loadbalancer.server.port" = "8080"
  })
}

module "ecs" {
  source = "../../compute/aws/ecs"

  name     = "traefik"
  clusters = {
    traefik = {
      apps = {
        traefik = {
          replicas           = var.replicaCount
          port               = 80
          docker_image       = local.traefik_image
          docker_command     = join(" ", local.traefik_arguments)
          subnet_ids         = var.subnet_ids
          security_group_ids = var.security_group_ids
          labels = merge(
            local.docker_labels
          )
        }
      }
    }
  }

  create_vpc = var.create_vpc
  vpc_id     = var.vpc_id
}
