
resource "helm_release" "traefik-crds" {
  name       = "traefik-crds"
  namespace  = var.namespace
  repository = "https://traefik.github.io/charts"
  chart      = "traefik-crds"
  version    = "1.11.1"
  timeout    = 900
  atomic     = true
  
  set = [
    {
      name = "gatewayAPI"
      value = true
    },
    { 
      name = "hub"
      value = true
    },
    {
      name = "deleteOnUninstall"
      value = true
    }
  ]
}

resource "null_resource" "gateway_api_experimental" {
  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/experimental-install.yaml"
  }

  depends_on = [helm_release.traefik-crds]
}