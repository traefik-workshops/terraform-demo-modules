resource "helm_release" "keycloak" {
  name       = var.name
  namespace  = var.namespace
  chart      = "${path.module}/../../../../traefik-demo-resources/keycloak/helm"
  wait       = true
  timeout    = 600

  values = [
    {
      namespace = var.namespace
      
      ingress = {
        enabled      = var.ingress
        domain       = var.ingress_domain
        entrypoint   = var.ingress_entrypoint
      }
      
      realm = {
        name                = "traefik"
        accessTokenLifespan = var.access_token_lifespan
        users               = var.users
        advancedUsers       = var.advanced_users
        redirectUris        = var.redirect_uris
      }
    }
  ]
}
