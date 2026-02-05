resource "helm_release" "airlines" {
  name             = var.name
  namespace        = var.namespace
  create_namespace = var.create_namespace

  repository = "oci://ghcr.io/traefik-workshops"
  chart      = "airlines"
  version    = var.git_ref

  values = [
    yamlencode({
      domain         = var.domain
      unique_domain  = var.unique_domain
      "tools-access" = var.tools_access
      "users-access" = var.users_access
      ai-gateway     = var.ai_gateway
      oidc = {
        clientId     = var.oidc_client_id
        clientSecret = var.oidc_client_secret
        issuerUrl    = var.oidc_issuer_url
      }
      "dns-traefiker" = var.dns_traefiker
      traefikDashboard = {
        enabled = var.traefik_dashboard_enabled
      }
    })
  ]
}

data "kubernetes_secret" "domain_secret" {
  count = var.unique_domain ? 1 : 0

  metadata {
    name      = "domain-secret"
    namespace = var.namespace
  }

  depends_on = [helm_release.airlines]
}
