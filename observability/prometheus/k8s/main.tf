resource "helm_release" "prometheus" {
  name       = var.name
  namespace  = var.namespace
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "77.10.0"
  timeout    = 900
  atomic     = true

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          scrapeInterval     = "5s"
          evaluationInterval = "5s"
          additionalScrapeConfigs = var.traefik_metrics_job_url != "" ? [
            {
              job_name     = "traefik-otel-metrics"
              metrics_path = var.traefik_metrics_job_metrics_path
              static_configs = [
                {
                  targets = [var.traefik_metrics_job_url]
                }
              ]
            }
          ] : []
        }
      }
      "prometheus-pushgateway" = {
        enabled = false
      }
      grafana = {
        enabled = false
      }
    }),
    yamlencode(var.extra_values),
    yamlencode(var.ingress == true ? {
      prometheus = {
        ingress = {
          enabled = true
          hosts   = ["prometheus.${var.ingress_domain}"]
          annotations = {
            "traefik.ingress.kubernetes.io/router.entrypoints"              = var.ingress_entrypoint
            "traefik.ingress.kubernetes.io/router.observability.accesslogs" = "false"
            "traefik.ingress.kubernetes.io/router.observability.metrics"    = "false"
            "traefik.ingress.kubernetes.io/router.observability.tracing"    = "false"
          }
        }
      }
    } : {})
  ]
}
