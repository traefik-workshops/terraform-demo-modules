# =============================================================================
# traefik/shared - Main Configuration Module
# =============================================================================
# Generates Helm values and optionally extracts config for VM deployments.
# - K8s: Uses helm_values output directly
# - EC2/ECS/Nutanix: Uses extracted CLI args, env vars, etc.
# =============================================================================

locals {
  # ---------------------------------------------------------------------------
  # Computed Image Configuration
  # ---------------------------------------------------------------------------
  image_registry = (
    var.custom_image_registry != "" ? var.custom_image_registry :
    var.enable_preview_mode ? "europe-west9-docker.pkg.dev/traefiklabs" :
    var.enable_api_gateway ? "ghcr.io" : ""
  )

  image_repository = (
    var.custom_image_repository != "" ? var.custom_image_repository :
    var.enable_preview_mode ? "traefik-hub/traefik-hub" :
    var.enable_api_gateway ? "traefik/traefik-hub" : "traefik"
  )

  image_tag = (
    var.custom_image_tag != "" ? var.custom_image_tag :
    var.enable_preview_mode && var.traefik_hub_preview_tag != "" ? var.traefik_hub_preview_tag :
    var.enable_preview_mode ? "latest-v3" :
    var.enable_api_gateway ? var.traefik_hub_tag : var.traefik_tag
  )

  image_full = "${local.image_registry != "" ? "${local.image_registry}/" : ""}${local.image_repository}:${local.image_tag}"

  # ---------------------------------------------------------------------------
  # Let's Encrypt Configuration
  # ---------------------------------------------------------------------------
  letsencrypt_server = var.is_staging_letsencrypt ? "https://acme-staging-v02.api.letsencrypt.org/directory" : "https://acme-v02.api.letsencrypt.org/directory"

  # ---------------------------------------------------------------------------
  # OTLP Endpoint
  # ---------------------------------------------------------------------------
  otlp_endpoint = var.otlp_address != "" ? var.otlp_address : "http://opentelemetry-collector:4318"

  # ---------------------------------------------------------------------------
  # Helm Values (source of truth for all deployments)
  # ---------------------------------------------------------------------------
  helm_values = {
    image = merge(
      {
        repository = local.image_repository
        tag        = local.image_tag
      },
      local.image_registry != "" ? { registry = local.image_registry } : {}
    )

    hub = var.enable_api_gateway || var.enable_api_management || var.enable_preview_mode ? {
      token       = var.traefik_hub_token
      offline     = var.enable_offline_mode
      aigateway   = var.enable_ai_gateway ? { enabled = true, maxRequestBodySize = 2097152 } : null
      mcpgateway  = var.enable_mcp_gateway ? { enabled = true, maxRequestBodySize = 2097152 } : null
      platformUrl = var.enable_preview_mode ? "https://api-preview.hub.traefik.io/agent" : null
    } : null

    ports = merge(
      {
        web = {
          port     = 80
          expose   = { default = true }
          protocol = "TCP"
        }
        websecure = {
          port     = 443
          expose   = { default = true }
          protocol = "TCP"
          tls = var.cloudflare_dns.enabled ? {
            certResolver = "cf"
            domains = [{
              main = var.cloudflare_dns.domain
              sans = concat(["*.${var.cloudflare_dns.domain}"], var.cloudflare_dns.extra_san_domains)
            }]
          } : null
        }
        traefik = {
          port   = 8080
          expose = { default = true }
        }
      },
      var.enable_prometheus ? {
        prometheus = {
          port       = 9101
          expose     = { default = true }
          exposePort = 9101
          protocol   = "TCP"
        }
      } : {},
      var.custom_ports
    )

    api = {
      dashboard = var.enable_dashboard
      insecure  = var.dashboard_insecure
    }

    additionalArguments = concat(
      var.file_provider_config != "" ? [
        "--providers.file.filename=${var.file_provider_path}"
      ] : [],
      var.custom_arguments
    )

    env = concat(
      var.cloudflare_dns.enabled ? [
        { name = "CF_DNS_API_TOKEN", value = var.cloudflare_dns.api_token }
      ] : [],
      var.custom_envs
    )

    logs = {
      general = {
        level = var.log_level
        otlp = {
          enabled     = var.enable_otlp_application_logs
          serviceName = var.otlp_service_name
          http = {
            enabled  = true
            endpoint = "${local.otlp_endpoint}/v1/logs"
            tls = {
              insecureSkipVerify = true
            }
          }
        }
      }
      access = {
        enabled = true
        filters = {
          statuscodes = "200-599"
        }
        otlp = {
          enabled     = var.enable_otlp_access_logs
          serviceName = var.otlp_service_name
          http = {
            enabled  = true
            endpoint = "${local.otlp_endpoint}/v1/logs"
            tls = {
              insecureSkipVerify = true
            }
          }
        }
      }
    }

    metrics = var.enable_prometheus ? {
      prometheus = {
        addEntryPointsLabels = true
        addRoutersLabels     = true
        addServicesLabels    = true
      }
    } : null

    tracing = var.enable_otlp_traces && var.otlp_address != "" ? {
      serviceName = var.otlp_service_name
      otlp = {
        http = {
          endpoint = "${local.otlp_endpoint}/v1/traces"
          tls = {
            insecureSkipVerify = true
          }
        }
      }
    } : null

    experimental = merge({
      otlpLogs = true
      }, length(var.custom_plugins) > 0 ? {
      plugins = var.custom_plugins
    } : null)

    certificatesResolvers = var.cloudflare_dns.enabled ? {
      cf = {
        acme = {
          email    = "zaid@traefik.io"
          storage  = "/data/acme.json"
          caServer = local.letsencrypt_server
          dnsChallenge = {
            provider         = "cloudflare"
            resolvers        = ["1.1.1.1:53", "1.0.0.1:53"]
            delayBeforeCheck = 20
          }
        }
      }
    } : null
  }

  # Clean null values from helm_values
  helm_values_clean = { for k, v in local.helm_values : k => v if v != null }
}

# Extract config using helm template (for VM deployments)
data "external" "helm_config" {
  count   = var.extract_config ? 1 : 0
  program = ["bash", "${path.module}/scripts/extract_config.sh"]

  query = {
    values_yaml   = yamlencode(local.helm_values_clean)
    chart_version = var.traefik_chart_version
  }
}

# Variable to control extraction
variable "extract_config" {
  description = "Whether to run helm template extraction (for EC2/ECS/Nutanix)"
  type        = bool
  default     = false
}
