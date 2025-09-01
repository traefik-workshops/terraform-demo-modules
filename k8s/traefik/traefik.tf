locals {
  additional_arguments = concat(var.enable_otlp_access_logs ? [
    "--experimental.otlpLogs=true", 
    "--accesslog.otlp.http.tls.insecureSkipVerify=true", 
    "--accesslog.otlp.http.endpoint=http://opentelemetry-opentelemetry-collector.traefik-observability:4318/v1/logs"
  ]: [],
  var.enable_otlp_application_logs ? [
    "--experimental.otlpLogs=true", 
    "--log.otlp.http.tls.insecureSkipVerify=true", 
    "--log.otlp.http.endpoint=http://opentelemetry-opentelemetry-collector.traefik-observability:4318/v1/logs"
  ] : [], var.custom_arguments)

  metrics_port = var.enable_prometheus ? {
    metrics = {
      expose = {
        default = true
      }
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

  plugins = var.custom_plugins
  extra_objects = var.extra_objects
}

resource "kubernetes_namespace" "traefik" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret" "traefik-hub-license" {
  metadata {
    name = "traefik-hub-license"
    namespace = var.namespace
  }

  type = "Opaque"
  data = {
    token = var.traefik_license
  }

  depends_on = [ kubernetes_namespace.traefik ]
}

resource "helm_release" "traefik" {
  name             = "traefik"
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
          enabled = var.enable_ai_gateway
          maxRequestBodySize = 1048576
        }
        redis = var.enable_api_management ? {
          endpoints = "traefik-redis-master.traefik.svc:6379"
          password  = var.redis_password
        } : {}
        platformUrl = var.enable_preview_mode ? "https://api-preview.hub.traefik.io/agent" : ""
        offline = var.enable_offline_mode && var.enable_api_management
      }
      ingressRoute = {
        dashboard = {
          enabled = true
          matchRule = "Host(`dashboard.traefik.cloud`) || Host(`dashboard.traefik.localhost`)"
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
        fsGroup = 65532
        fsGroupChangePolicy = "OnRootMismatch"
      }

      api = {
        debug = "DEBUG" == var.log_level
      }

      gateway = {
        listeners = {
          web = {
            port = 8000
            protocol = "HTTP"
            namespacePolicy = {
              from = "All"
            }
          }
          traefik = {
            port = 8080
            protocol = "HTTP"
            namespacePolicy = {
              from = "All"
            }
          }
        }
      }

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
        tag        = var.enable_preview_mode ? "latest-v3" : var.traefik_hub_tag
        pullPolicy = var.enable_preview_mode ? "Always" : "IfNotPresent"
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
          enabled = true
          experimentalChannel = false
        }
      }

      certificatesResolvers = {
        treafik-airlines = {
          acme = {
            email = "zaid@traefik.io"
            storage = "/data/acme.json"
            httpChallenge = {
              entryPoint = "web"
            }
          }
        }
        le = {
          acme = {
            email = "zaid@traefik.io"
            storage = "/data/acme.json"
            httpChallenge = {
              entryPoint = "web"
            }
          }
        }
      }

      metrics = {
        prometheus = {
          addEntryPointsLabels = var.enable_prometheus
          addRoutersLabels = var.enable_prometheus
          addServicesLabels = var.enable_prometheus
        }
        otlp = {
          enabled = var.enable_otlp_metrics
          addEntryPointsLabels = ! var.enable_prometheus
          addRoutersLabels = ! var.enable_prometheus
          addServicesLabels = ! var.enable_prometheus
          http = {
            enabled  = true
            endpoint = "http://opentelemetry-opentelemetry-collector.traefik-observability:4318/v1/metrics"
            tls = {
              insecureSkipVerify = true
            }
          }
        }
      }

      tracing = {
        otlp = {
          enabled = var.enable_otlp_tracing
          http = {
            enabled  = true
            endpoint = "http://opentelemetry-opentelemetry-collector.traefik-observability:4318/v1/traces"
            tls = {
              insecureSkipVerify = true
            }
          }
        }
      }

      additionalArguments = local.additional_arguments
      extra_objects = local.extra_objects
    })
  ]

  depends_on = [helm_release.redis, kubernetes_secret.traefik-hub-license, helm_release.traefik-crds]
}
