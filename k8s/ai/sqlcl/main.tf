resource "kubernetes_deployment" "sqlcl" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = "sqlcl-mcp"
      }
    }

    template {
      metadata {
        labels = {
          app = "sqlcl-mcp"
        }
      }

      spec {
        container {
          name  = "sqlcl-mcp"
          image = var.image

          port {
            container_port = var.container_port
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "sqlcl" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }

  spec {
    selector = {
      app = "sqlcl-mcp"
    }

    port {
      port        = var.service_port
      target_port = var.container_port
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "sqlcl-traefik" {
  metadata {
    name = var.name
    namespace = var.namespace
    annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints" = "traefik"
      "traefik.ingress.kubernetes.io/router.observability.accesslogs" = "false"
      "traefik.ingress.kubernetes.io/router.observability.metrics" = "false"
      "traefik.ingress.kubernetes.io/router.observability.tracing" = "false"
    }
  }

  spec {
    rule {
      host = "sqlcl.traefik.${var.ingress_domain}"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = var.name
              port {
                number = var.service_port
              }
            }
          }
        }
      }
    }
    rule {
      host = "sqlcl.traefik.localhost"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = var.name
              port {
                number = var.service_port
              }
            }
          }
        }
      }
    }
  }

  count = var.ingress == true ? 1 : 0
}
