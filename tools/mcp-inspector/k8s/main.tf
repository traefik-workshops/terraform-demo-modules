resource "kubernetes_deployment" "mcp_inspector" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = "mcp-inspector"
      }
    }

    template {
      metadata {
        labels = {
          app = "mcp-inspector"
        }
      }

      spec {
        container {
          name  = "mcp-inspector"
          image = "ghcr.io/modelcontextprotocol/inspector:latest"

          port {
            container_port = 6274
            name           = "client"
          }

          port {
            container_port = 6277
            name           = "server"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "mcp_inspector" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }

  spec {
    selector = {
      app = "mcp-inspector"
    }

    port {
      name        = "client"
      port        = 6274
      target_port = 6274
    }

    port {
      name        = "server"
      port        = 6277
      target_port = 6277
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "mcp_inspector_traefik" {
  metadata {
    name      = var.name
    namespace = var.namespace
    annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints"              = var.ingress_entrypoint
      "traefik.ingress.kubernetes.io/router.observability.accesslogs" = "true"
      "traefik.ingress.kubernetes.io/router.observability.metrics"    = "true"
      "traefik.ingress.kubernetes.io/router.observability.tracing"    = "true"
    }
  }

  spec {
    rule {
      host = "mcp-inspector.${var.ingress_domain}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = var.name
              port {
                number = 6274
              }
            }
          }
        }
      }
    }
  }

  count = var.ingress == true ? 1 : 0
}
