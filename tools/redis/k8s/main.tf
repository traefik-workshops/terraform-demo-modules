resource "helm_release" "redis" {
  name       = var.name
  namespace  = var.namespace
  repository = "oci://registry-1.docker.io/"
  chart      = "cloudpirates/redis"
  version    = "0.4.6"
  timeout    = 900
  atomic     = true

  set = [
    {
      name  = "auth.password"
      value = var.password
    },
    {
      name  = "replica.replicaCount"
      value = var.replicaCount
    }
  ]
}
