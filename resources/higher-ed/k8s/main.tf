# Create ArgoCD Application for higher-ed resources using Helm
resource "argocd_application" "higher-ed" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }

  spec {
    project = "default"

    source {
      repo_url        = "https://github.com/traefik-workshops/traefik-demo-resources"
      target_revision = var.git_ref
      path            = "higher-ed/helm"
      
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
      
      sync_options = ["CreateNamespace=true"]
    }
  }
}
