# Create ArgoCD Application for airlines resources using Helm
resource "argocd_application" "airlines" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }

  cascade = true
  wait    = true

  spec {
    project = "default"

    source {
      repo_url        = "https://github.com/traefik-workshops/traefik-demo-resources"
      target_revision = var.git_ref
      path            = "airlines/helm"

      helm {
        values = yamlencode({
          domain = var.domain

          "tools-access" = var.tools_access
          "users-access" = var.users_access
          chat          = var.chat

          oidc = {
            clientId     = var.oidc_client_id
            clientSecret = var.oidc_client_secret
            issuerUrl    = var.oidc_issuer_url
          }
        })
      }
    }

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "default"
    }

    sync_policy {
      automated {
        prune       = true
        self_heal   = true
        allow_empty = true
      }

      sync_options = [
        "CreateNamespace=true",
        "PruneLast=true"
      ]
    }
  }
}
