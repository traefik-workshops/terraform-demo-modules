resource "helm_release" "open_webui" {
  name       = var.name
  namespace  = var.namespace
  repository = "https://helm.openwebui.com/"
  chart      = "open-webui"
  version    = "6.28.0"
  timeout    = 900
  atomic     = true

  values = [
    yamlencode({
      ollama = {
        enabled = false
      }
      pipelines = {
        enabled = false
      }
      extraEnvVars = [
        {
          name = "DEFAULT_USER_ROLE"
          value = "admin"
        },
        {
          name = "WEBUI_NAME"
          value = "Traefik Chat"
        },
        {
          name = "USE_CUDA_DOCKER"
          value = "false"
        },
        {
          name = "OPENAI_API_BASE_URLS"
          value = join(";", var.openai_api_base_urls)
        },
        {
          name = "OPENAI_API_KEYS"
          value = join(";", var.openai_api_keys)
        }
      ]
    }),
    yamlencode(var.extraValues),
    yamlencode(var.ingress == true ? {
      ingress = {
        enabled = true
        hosts = ["chat.traefik.cloud", "chat.traefik.localhost"]
        annotations = {
          "traefik.ingress.kubernetes.io/router.entrypoints" = "web"
          "traefik.ingress.kubernetes.io/router.observability.accesslogs" = "false"
          "traefik.ingress.kubernetes.io/router.observability.metrics" = "false"
          "traefik.ingress.kubernetes.io/router.observability.tracing" = "false"
        }
      }
    } : {})
  ]
}
