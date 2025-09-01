
resource "helm_release" "traefik-crds" {
  name      = "traefik-crds"
  namespace = var.namespace
  chart     = "oci://registry-1.docker.io/traefik/traefik-crds"
  version   = "1.10.0"
  timeout   = 900
  atomic    = true
  
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

  depends_on = [helm_release.redis]
}
