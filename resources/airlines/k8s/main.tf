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

          tokens = {
            ticketing         = var.jwt_tokens["ticketing"]
            userAssistance    = var.jwt_tokens["userAssistance"]
            partnerAssistance = var.jwt_tokens["partnerAssistance"]
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
