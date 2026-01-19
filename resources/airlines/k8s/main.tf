# Create ArgoCD Application for airlines resources using Helm
resource "kubectl_manifest" "airlines" {
  yaml_body = yamlencode({
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
        path           = "airlines/helm"
        helm = {
          values = yamlencode({
            domain         = var.domain
            "tools-access" = var.tools_access
            "users-access" = var.users_access
            ai-gateway     = var.ai_gateway
            oidc = {
              clientId     = var.oidc_client_id
              clientSecret = var.oidc_client_secret
              issuerUrl    = var.oidc_issuer_url
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
          "PruneLast=true",
          "ServerSideApply=true"
        ]
      }
    }
  })
}
