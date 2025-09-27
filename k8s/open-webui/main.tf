resource "helm_release" "open_webui" {
  name       = var.name
  namespace  = var.namespace
  repository = "https://helm.openwebui.com/"
  chart      = "open-webui"
  version    = "6.28.0"
  timeout    = 900
  atomic     = true

  set = [
    {
      name = "ollama.enabled"
      value = "false"
    },
    {
      name = "pipelines.enabled"
      value = "false"
    },
    {
      name = "ingress.enabled"
      value = "true"
    },
    {
      name = "extraEnvVars[0].name"
      value = "DEFAULT_USER_ROLE"
    },
    {
      name = "extraEnvVars[0].value"
      value = "admin"
    },
    {
      name = "extraEnvVars[1].name"
      value = "WEBUI_NAME"
    },
    {
      name = "extraEnvVars[1].value"
      value = "Traefik Chat"
    },
    {
      name = "extraEnvVars[2].name"
      value = "USE_CUDA_DOCKER"
    },
    {
      name = "extraEnvVars[2].value"
      type = "string"
      value = "false"
    },
    {
      name = "extraEnvVars[3].name"
      value = "OPENAI_API_BASE_URLS"
    },
    {
      name = "extraEnvVars[3].value"
      value = join(";", var.openai_api_base_urls)
    },
    {
      name = "extraEnvVars[4].name"
      value = "OPENAI_API_KEYS"
    },
    {
      name = "extraEnvVars[4].value"
      value = join(";", var.openai_api_keys)
    }
  ]
}
