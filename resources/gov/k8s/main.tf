# Create ArgoCD Application for gov resources using Helm
resource "argocd_application" "gov" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }

  spec {
    project = "default"

    source {
      repo_url        = "https://github.com/traefik-workshops/traefik-demo-resources"
      target_revision = var.git_ref
      path            = "gov/helm"
      
      helm {
        values = yamlencode({
          domain = var.domain
          
          keycloak = {
            adminId     = var.keycloak_admin_id
            developerId = var.keycloak_developer_id
            agentId     = var.keycloak_agent_id
          }
          
          oidc = {
            clientId     = var.oidc_client_id
            clientSecret = var.oidc_client_secret
          }
          
          presidio = {
            host = var.presidio_host
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
      }
      
      sync_options = [
        "CreateNamespace=true",
        "PruneLast=true"
      ]
    }
  }
}
