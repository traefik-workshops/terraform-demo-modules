resource "helm_release" "k6_operator" {
  name       = var.name
  namespace  = var.namespace
  repository = "https://grafana.github.io/helm-charts"
  chart      = "k6-operator"
  version    = "3.14.1"
  timeout    = 900
  atomic     = true

  set = [
    {
      name = "namespace.create"
      value = false
    }
  ]
}
