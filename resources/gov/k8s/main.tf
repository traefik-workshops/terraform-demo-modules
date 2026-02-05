# Deploy gov resources using Helm
resource "helm_release" "gov" {
  name             = var.name
  namespace        = var.namespace
  create_namespace = var.create_namespace

  repository = "https://github.com/traefik-workshops/traefik-demo-resources"
  chart      = "gov/helm"
  version    = var.git_ref

  values = [
    yamlencode({
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
  ]
}
