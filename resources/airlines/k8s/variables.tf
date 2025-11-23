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
