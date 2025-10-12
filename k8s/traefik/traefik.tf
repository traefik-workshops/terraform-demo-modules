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
    },
    local.metrics_port,
    var.custom_ports
  )

  plugins       = var.custom_plugins
  extra_objects = var.custom_objects
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
          entryPoints = var.dashboard_entry_points
        }
      }

      ports = local.ports

      experimental = {
        kubernetesGateway = {
          enabled = true
        }
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
        registry   = var.enable_preview_mode ? "europe-west9-docker.pkg.dev/traefiklabs" : "ghcr.io"
        repository = var.enable_preview_mode ? "traefik-hub/traefik-hub" : "traefik/traefik-hub"
        tag        = var.enable_preview_mode ? var.traefik_hub_preview_tag != "" ? var.traefik_hub_preview_tag : "latest-v3" : var.traefik_hub_tag
        pullPolicy = var.enable_preview_mode ? "Always" : "IfNotPresent"
        } : var.traefik_tag != "" ? {
        tag = var.traefik_tag
      } : {}

      providers = {
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
      }

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
          distributedAcme = {
            caServer = var.is_staging_letsencrypt ? "https://acme-staging-v02.api.letsencrypt.org/directory" : "https://acme-v02.api.letsencrypt.org/directory"
            email    = "zaid@traefik.io"
            storage = {
              kubernetes = true
            }
            dnschallenge = {
              provider         = "cloudflare"
              resolvers        = ["1.1.1.1:53", "1.0.0.1:53"]
              delayBeforeCheck = 20
            }
          }
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

      additionalArguments = local.additional_arguments
      extra_objects       = local.extra_objects
    }),
    yamlencode(var.extra_values)
  ]

  depends_on = [kubernetes_secret.traefik-hub-license, helm_release.traefik-crds]
}

module "redis" {
  source = "../tools/redis"

  name         = "traefik-redis"
  namespace    = var.namespace
  password     = var.redis_password
  replicaCount = 1

  count = var.enable_api_management ? 1 : 0
}
