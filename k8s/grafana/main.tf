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
      tolerations = var.tolerations
    }),
    yamlencode(var.extraValues)
  ]
}
