# Deploy higher-ed resources using Helm
resource "helm_release" "higher-ed" {
  name             = var.name
  namespace        = var.namespace
  create_namespace = var.create_namespace

  repository = "oci://ghcr.io/traefik-workshops"
  chart      = "higher-ed"
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
    })
  ]
}
