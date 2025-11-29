locals {
  otlp_address = var.otlp_address != "" ? var.otlp_address : "http://opentelemetry-opentelemetry-collector.traefik-observability:4318"

  additional_arguments = concat(var.enable_otlp_access_logs ? [
    "--experimental.otlpLogs=true",
    "--accesslog.otlp.http.tls.insecureSkipVerify=true",
    "--accesslog.otlp.http.endpoint=${local.otlp_address}/v1/logs"
    ] : [],
    var.enable_otlp_application_logs ? [
      "--experimental.otlpLogs=true",
      "--log.otlp.http.tls.insecureSkipVerify=true",
      "--log.otlp.http.endpoint=${local.otlp_address}/v1/logs"
      ] : [], var.enable_mcp_gateway ? [
      "--hub.mcpgateway",
      "--hub.mcpgateway.maxRequestBodySize=2097152"
      ] : [], var.enable_knative_provider ? [
      "--experimental.knative=true",
      "--providers.knative=true"
      ] : [], var.file_provider_config != "" ? [
      "--providers.file.filename=/file-provider/dynamic.yaml"
  ] : [], var.custom_arguments)

  metrics_port = var.enable_prometheus ? {
    prometheus = {
      port = 9101
      expose = {
        default = true
      }
      exposePort = 9101
      protocol   = "TCP"
    }
  } : {}

  ports = merge({
    traefik = {
      expose = {
        default = true
      }
    }
    }, var.cloudflare_dns.enabled ? {
    websecure = {
      tls = {
        certResolver = "cf"
        domains = [
          {
            main = "${var.cloudflare_dns.domain}"
            sans = concat(["*.${var.cloudflare_dns.domain}"], var.cloudflare_dns.extra_san_domains)
          }
        ]
      }
    }
    } : {},
    local.metrics_port,
    var.custom_ports
  )

  caServer = var.is_staging_letsencrypt ? "https://acme-staging-v02.api.letsencrypt.org/directory" : "https://acme-v02.api.letsencrypt.org/directory"
  email    = "zaid@traefik.io"

  dnschallenge = {
    provider         = "cloudflare"
    resolvers        = ["1.1.1.1:53", "1.0.0.1:53"]
    delayBeforeCheck = 20
  }

  distributedAcme = {
    caServer     = local.caServer
    email        = local.email
    dnschallenge = local.dnschallenge
    storage = {
      kubernetes = true
    }
  }
  acme = {
    caServer     = local.caServer
    email        = local.email
    dnschallenge = local.dnschallenge
    storage      = "/data/acme.json"
  }

  plugins       = var.custom_plugins
  extra_objects = var.custom_objects

  # Volumes configuration for file provider
  deployment_volumes = var.file_provider_config != "" ? [
    {
      name = "traefik-dynamic-config"
      configMap = {
        name = "traefik-dynamic-config"
      }
    }
  ] : []

  volume_mounts = var.file_provider_config != "" ? [
    {
      name      = "traefik-dynamic-config"
      mountPath = "/file-provider"
    }
  ] : []
}

resource "kubernetes_secret" "traefik-hub-license" {
  metadata {
    name      = "traefik-hub-license"
    namespace = var.namespace
  }

  type = "Opaque"
  data = {
    token = var.traefik_license
  }

  count = var.enable_api_gateway || var.enable_api_management ? 1 : 0
}

resource "kubernetes_config_map" "traefik-dynamic-config" {
  metadata {
    name      = "traefik-dynamic-config"
    namespace = var.namespace
  }

  data = {
    "dynamic.yaml" = var.file_provider_config
  }

  count = var.file_provider_config != "" ? 1 : 0
}

resource "helm_release" "traefik" {
  name             = var.name
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  version          = var.traefik_chart_version
  namespace        = var.namespace
  create_namespace = true
  atomic           = true
  wait             = true

  values = [
    yamlencode({
      hub = {
        token = var.enable_api_gateway || var.enable_api_management ? "traefik-hub-license" : ""
        apimanagement = {
          enabled = var.enable_api_management
        }
        aigateway = {
          enabled            = var.enable_ai_gateway
          maxRequestBodySize = 1048576
        }
        redis = var.enable_api_management ? {
          endpoints = "traefik-redis.${var.namespace}.svc:6379"
          password  = var.redis_password
        } : {}
        platformUrl = var.enable_preview_mode ? "https://api-preview.hub.traefik.io/agent" : ""
        offline     = var.enable_offline_mode
        sendlogs    = false
      }
      ingressRoute = {
        dashboard = {
          enabled     = true
          matchRule   = var.dashboard_match_rule
          entryPoints = var.dashboard_entrypoints
        }
      }

      ports = local.ports

      experimental = {
        plugins = local.plugins
      }

      podSecurityContext = {
        fsGroup             = 65532
        fsGroupChangePolicy = "OnRootMismatch"
      }

      api = {
        debug = "DEBUG" == var.log_level
      }

      gateway = {
        listeners = {
          web = {
            port     = 8000
            protocol = "HTTP"
            namespacePolicy = {
              from = "All"
            }
          }
          traefik = {
            port     = 8080
            protocol = "HTTP"
            namespacePolicy = {
              from = "All"
            }
          }
        }
      }

      deployment = {
        kind     = var.deploymentType
        replicas = var.replicaCount
      }

      service = {
        kind = var.serviceType
      }

      env = concat(
        [{ name = "USER", value = "traefiker" }],
        var.cloudflare_dns.enabled ? [{ name = "CF_DNS_API_TOKEN", value = var.cloudflare_dns.api_token }] : [],
        var.custom_envs
      )

      logs = {
        general = {
          level = var.log_level
        }
        access = {
          enabled = true
          filters = {
            statuscodes = "200-599"
          }
        }
      }

      image = var.enable_api_gateway || var.enable_api_management ? {
        registry   = var.custom_image_registry != "" ? var.custom_image_registry : var.enable_preview_mode ? "europe-west9-docker.pkg.dev/traefiklabs" : "ghcr.io"
        repository = var.custom_image_repository != "" ? var.custom_image_repository : var.enable_preview_mode ? "traefik-hub/traefik-hub" : "traefik/traefik-hub"
        tag        = var.custom_image_tag != "" ? var.custom_image_tag : var.enable_preview_mode ? var.traefik_hub_preview_tag != "" ? var.traefik_hub_preview_tag : "latest-v3" : var.traefik_hub_tag
        pullPolicy = "Always"
        } : var.traefik_tag != "" ? {
        tag = var.traefik_tag
      } : {}

      providers = merge({
        kubernetesCRD = {
          allowCrossNamespace       = true
          allowExternalNameServices = true
        }
        kubernetesIngress = {
          allowExternalNameServices = true
        }
        kubernetesGateway = {
          enabled             = true
          experimentalChannel = false
        }
      }, var.custom_providers)

      certificatesResolvers = {
        treafik-airlines = {
          acme = {
            email   = "zaid@traefik.io"
            storage = "/data/acme.json"
            httpChallenge = {
              entryPoint = "web"
            }
          }
        }
        # TODO: use distributed acme with k8s storage when var.enable_api_gateway || var.enable_api_management is true
        # TODO: allow configuring a different challenge type
        le = {
          acme = {
            email   = "zaid@traefik.io"
            storage = "/data/acme.json"
            httpChallenge = {
              entryPoint = "web"
            }
          }
        }
        cf = {
          for k, v in {
            distributedAcme = var.enable_api_gateway || var.enable_api_management ? local.distributedAcme : null
            acme            = var.enable_api_gateway || var.enable_api_management ? null : local.acme
          } : k => v if v != null
        }
      }

      metrics = {
        prometheus = {
          addEntryPointsLabels = var.enable_prometheus
          addRoutersLabels     = var.enable_prometheus
          addServicesLabels    = var.enable_prometheus
        }
        otlp = {
          enabled              = var.enable_otlp_metrics
          serviceName          = var.otlp_service_name
          addEntryPointsLabels = !var.enable_prometheus
          addRoutersLabels     = !var.enable_prometheus
          addServicesLabels    = !var.enable_prometheus
          http = {
            enabled  = true
            endpoint = "${local.otlp_address}/v1/metrics"
            tls = {
              insecureSkipVerify = true
            }
          }
        }
      }

      tracing = {
        serviceName = var.otlp_service_name
        otlp = {
          enabled = var.enable_otlp_traces
          http = {
            enabled  = true
            endpoint = "${local.otlp_address}/v1/traces"
            tls = {
              insecureSkipVerify = true
            }
          }
        }
      }

      resources   = var.resources
      tolerations = var.tolerations

      deployment = {
        additionalVolumes = local.deployment_volumes
      }

      additionalArguments    = local.additional_arguments
      additionalVolumeMounts = local.volume_mounts
      extra_objects          = local.extra_objects
    }),
    yamlencode(var.extra_values)
  ]

  depends_on = [
    kubernetes_secret.traefik-hub-license,
    kubernetes_config_map.traefik-dynamic-config,
    helm_release.traefik-crds
  ]
}

module "redis" {
  source = "../../tools/redis/k8s"

  name         = "traefik-redis"
  namespace    = var.namespace
  password     = var.redis_password
  replicaCount = 1

  count = var.enable_api_management ? 1 : 0
}

resource "kubernetes_cluster_role" "knative_networking_role" {
  metadata {
    name = "knative-networking-role"
  }

  rule {
    api_groups = [""]
    resources  = ["services"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.internal.knative.dev"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.internal.knative.dev"]
    resources  = ["ingresses/status"]
    verbs      = ["update"]
  }

  count      = var.enable_knative_provider ? 1 : 0
  depends_on = [helm_release.traefik]
}

resource "kubernetes_cluster_role_binding" "gateway_controller_binding" {
  metadata {
    name = "gateway-controller"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "knative-networking-role"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "traefik"
    namespace = var.namespace
  }

  count      = var.enable_knative_provider ? 1 : 0
  depends_on = [kubernetes_cluster_role.knative_networking_role]
}
