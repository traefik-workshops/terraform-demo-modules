resource "helm_release" "nginx_ingress" {
  name       = var.name
  namespace  = var.namespace
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.14.1"
  timeout    = 900
  atomic     = true

  set = [
    {
      name  = "controller.service.type"
      value = "ClusterIP"
    }
  ]
}
