module "observability-prometheus" {
  source = "../../prometheus/k8s"

  namespace          = var.namespace
  ingress            = var.ingress
  ingress_domain     = var.ingress_domain
  ingress_entrypoint = var.ingress_entrypoint

  traefik_metrics_job_url = "${var.metrics_host}:${var.metrics_port}"
}

module "observability-grafana-loki" {
  source = "../../grafana-loki/k8s"

  namespace = var.namespace
}

module "observability-grafana-tempo" {
  source = "../../grafana-tempo/k8s"

  namespace = var.namespace
}

module "grafana" {
  source = "../../grafana/k8s"

  namespace          = var.namespace
  ingress            = var.ingress
  ingress_domain     = var.ingress_domain
  ingress_entrypoint = var.ingress_entrypoint
  dashboards         = var.dashboards

  prometheus = {
    enabled = true
    url = {
      service   = "prometheus-kube-prometheus-prometheus"
      port      = 9090
      namespace = ""
      override  = ""
    }
  }

  tempo = {
    enabled = true
    url = {
      service   = "tempo"
      port      = 3200
      namespace = ""
      override  = ""
    }
  }

  loki = {
    enabled = true
    url = {
      service   = "loki"
      port      = 3100
      namespace = ""
      override  = ""
    }
  }
}
