resource "helm_release" "argocd" {
  name       = var.name
  namespace  = var.namespace
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.8.2"
  timeout    = 900
  atomic     = true

  set = [
    {
      name  = "server.service.type"
      value = "ClusterIP"
    },
    {
      name  = "server.extraArgs"
      value = "{--insecure}"
    },
    {
      name  = "configs.params.server\\.insecure"
      value = "true"
    }
  ]

  set_sensitive = [
    {
      name  = "configs.secret.argocdServerAdminPassword"
      value = bcrypt(var.admin_password)
    }
  ]
}

resource "kubernetes_ingress_v1" "argocd-traefik" {
  metadata {
    name = "argocd"
    namespace = "traefik-tools"
    annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints" = "traefik"
      "traefik.ingress.kubernetes.io/router.observability.accesslogs" = "false"
      "traefik.ingress.kubernetes.io/router.observability.metrics" = "false"
      "traefik.ingress.kubernetes.io/router.observability.tracing" = "false"
    }
  }

  spec {
    rule {
      host = "argocd.traefik.cloud"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "argocd-server"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
    rule {
      host = "argocd.traefik.localhost"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "argocd-server"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.argocd]
}