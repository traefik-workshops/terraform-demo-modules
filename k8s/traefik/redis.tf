resource "helm_release" "redis" {
  name       = "traefik-redis"
  namespace  = var.namespace
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"
  version    = "19.6.4"
  timeout    = 900
  atomic     = true

  set = [
    {
      name = "auth.password"
      value = var.redis_password
    },
    {
      name = "replica.replicaCount"
      value = 1
    }
  ]
  count = var.enable_api_management ? 1 : 0
}
