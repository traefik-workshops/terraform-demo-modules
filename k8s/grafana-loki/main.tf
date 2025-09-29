resource "helm_release" "loki" {
  name       = "loki"
  namespace  = var.namespace
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = "6.40.0"
  timeout    = 900
  atomic     = true

  values = [
    yamlencode({
      deploymentMode = "SingleBinary"
      singleBinary = {
        replicas = 1
        tolerations = var.tolerations
      }
      loki = {
        auth_enabled = false
        commonConfig = {
          replication_factor = 1
          use_test_schema    = true
          storage_type       = "filesystem"
        }
      }
      lokiCanary = {
        enabled = false
      }
      test = {
        enabled = false
      }
      gateway = {
        enabled = false
      }
      write = {
        replicas = 0
      }
      read = {
        replicas = 0
      }
      backend = {
        replicas = 0
      }
      ruler = {
        enabled = false
      }
      resultsCache = {
        enabled = false
      }
      chunksCache = {
        enabled = false
      }
    }),
    yamlencode(var.extraValues)
  ]
}
