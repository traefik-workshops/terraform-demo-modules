locals {
  prometheus_url = var.prometheus.url.override != "" ? var.prometheus.url.override : "http://${var.prometheus.url.service}${var.prometheus.url.namespace != "" ? ".${var.prometheus.url.namespace}.svc" : ""}:${var.prometheus.url.port}"
  tempo_url      = var.tempo.url.override      != "" ? var.tempo.url.override      : "http://${var.tempo.url.service}${var.tempo.url.namespace != "" ? ".${var.tempo.url.namespace}.svc" : ""}:${var.tempo.url.port}"
  loki_url       = var.loki.url.override       != "" ? var.loki.url.override       : "http://${var.loki.url.service}${var.loki.url.namespace != "" ? ".${var.loki.url.namespace}.svc" : ""}:${var.loki.url.port}"

  datasources = concat(
    var.prometheus.enabled ? [{
      name = "Prometheus"
      type = "prometheus"
      url = local.prometheus_url
      access = "proxy"
      isDefault = true
    }] : [],
    var.tempo.enabled ? [{
      name = "Tempo"
      type = "tempo"
      url = local.tempo_url
      access = "proxy"
      isDefault = ! var.prometheus.enabled
    }] : [],
    var.loki.enabled ? [{
      name = "Loki"
      type = "loki"
      url = local.loki_url
      access = "proxy"
      isDefault = ! var.prometheus.enabled && ! var.tempo.enabled
    }] : [])

    aigateway_dashboard = "aigateway-dashboards"
    aigateway_path      = "/dashboards/hub/aigateway"

    dashboardProviders = concat(var.dashboards.aigateway ? [{
      name = local.aigateway_dashboard
      orgId = "1"
      type = "file"
      disableDeletion = false
      editable = true
      updateIntervalSeconds = 10
      options = {
        path = local.aigateway_path
      }
    }] : [])

    configmapMounts = concat(var.dashboards.aigateway ? [{
      name      = local.aigateway_dashboard
      mountPath = "${local.aigateway_path}/dashboard.json"
      subPath   = "dashboard.json"
      configMap = local.aigateway_dashboard
      readOnly  = true
    }] : [])
}

resource "helm_release" "grafana" {
  name       = var.name
  namespace  = var.namespace
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "10.0.0"
  timeout    = 900
  atomic     = true

  values = [
    yamlencode({
      "grafana.ini" = {
        "auth.anonymous" = {
          enabled = true
          org_name = "Main Org."
          org_role = "Admin"
        }
        auth = {
          disable_login_form = true
        }
      }
      datasources = {
        "datasources.yaml" = {
          apiVersion = 1
          datasources = local.datasources
        }
      }
      dashboardProviders = {
        "dashboardproviders.yaml" = {
          apiVersion = 1
          providers = local.dashboardProviders
        }
      }
      extraConfigmapMounts = local.configmapMounts
      tolerations = var.tolerations
    }),
    yamlencode(var.extra_values),
    yamlencode(var.ingress == true ? {
      ingress = {
        enabled = true
        hosts = [
          "grafana.traefik.${var.ingress_domain}",
          "grafana.traefik.localhost"
        ]
        annotations = {
          "traefik.ingress.kubernetes.io/router.entrypoints" = "traefik"
          "traefik.ingress.kubernetes.io/router.observability.accesslogs" = "false"
          "traefik.ingress.kubernetes.io/router.observability.metrics" = "false"
          "traefik.ingress.kubernetes.io/router.observability.tracing" = "false"
        }
      }
    } : {})
  ]
}

module "aigateway_dashboard" {
  source    = "./dashboards/aigateway"

  name      = local.aigateway_dashboard
  namespace = var.namespace

  count = var.dashboards.aigateway ? 1 : 0
}
