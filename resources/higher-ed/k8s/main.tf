# Create ArgoCD Application for higher-ed resources using Helm
resource "kubernetes_manifest" "higher-ed" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = var.name
      namespace = var.namespace
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/traefik-workshops/traefik-demo-resources"
        targetRevision = var.git_ref
        path           = "higher-ed/helm"
        helm = {
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
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
      }
      syncPolicy = {
        automated = {
          prune      = true
          selfHeal   = true
          allowEmpty = true
        }
        syncOptions = [
          "CreateNamespace=true",
          "PruneLast=true"
        ]
      }
    }
  }
}
