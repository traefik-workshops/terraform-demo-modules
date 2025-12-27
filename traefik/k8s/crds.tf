
resource "helm_release" "traefik-crds" {
  count = var.skip_crds ? 0 : 1

  name       = "traefik-crds"
  namespace  = var.namespace
  repository = "https://traefik.github.io/charts"
  chart      = "traefik-crds"
  version    = "1.11.1"
  timeout    = 900
  atomic     = true

  set = [
    {
      name  = "gatewayAPI"
      value = true
    },
    {
      name  = "hub"
      value = true
    },
    {
      name  = "deleteOnUninstall"
      value = true
    }
  ]
}

resource "null_resource" "gateway_api_experimental" {
  count = var.skip_crds ? 0 : 1

  provisioner "local-exec" {
    command = <<EOF
    kubectl apply --server-side \
      -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/experimental-install.yaml \
      --force-conflicts
EOF
  }

  depends_on = [helm_release.traefik-crds]
}
