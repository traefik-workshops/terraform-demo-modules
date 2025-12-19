variable "name" {
  type = string
}

variable "namespace" {
  type = string
}

resource "kubernetes_config_map" "grafana_aigateway_dashboards" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }

  data = {
    "dashboard.json" = "${file("${path.module}/dashboard.json")}"
  }
}