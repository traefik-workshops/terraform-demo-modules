variable "name" {
  type        = string
  description = "The name of the airlines release"
  default     = "airlines"
}

variable "namespace" {
  type        = string
  description = "Namespace for the airlines deployment"
}

variable "domain" {
  description = "Base domain for all services"
  type        = string
  default     = "triple-gate.traefik.ai"
}

variable "git_ref" {
  description = "Git reference (branch, tag, or commit) for traefik-demo-resources"
  type        = string
  default     = "main"
}

variable "oidc_client_id" {
  description = "OIDC Client ID for the API Portal"
  type        = string
}

variable "oidc_client_secret" {
  description = "OIDC Client Secret for the API Portal"
  type        = string
}

variable "oidc_jwks_url" {
  description = "OIDC JWKS URL for the API Portal"
  type        = string
}

variable "tool_access" {
  description = "Configuration for tool access (tokens and groups)"
  type = map(object({
    token = string
    group = string
  }))
}

variable "user_access" {
  description = "Configuration for user access (ids and groups)"
  type = list(object({
    name  = string
    id    = string
    group = string
  }))
}

variable "chat" {
  description = "Configuration for chat features (LLMs, guards, etc.)"
  type = object({
    llms = object({
      openai = object({
        enabled = bool
        api_key = string
      })
      gpt_oss = object({
        enabled = bool
        host    = string
      })
    })
    guards = object({
      enabled  = bool
      parallel = bool
      topic_control = object({
        enabled = bool
        host    = string
      })
      content_safety = object({
        enabled = bool
        host    = string
      })
      jailbreak_detection = object({
        enabled = bool
        host    = string
      })
      granite_guardian = object({
        enabled = bool
        host    = string
      })
    })
    content_guard = object({
      enabled = bool
      presidio = object({
        host = string
      })
    })
    semantic_cache = object({
      enabled = bool
      tokenizer = object({
        host = string
      })
      vectorDB = object({
        weaviate = object({
          host = string
        })
      })
    })
  })
}
