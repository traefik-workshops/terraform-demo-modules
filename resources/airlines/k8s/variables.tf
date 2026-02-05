variable "name" {
  type        = string
  description = "The name of the airlines release"
  default     = "airlines"
}

variable "namespace" {
  type        = string
  description = "Namespace for the airlines deployment"
  default     = "airlines"
}

variable "create_namespace" {
  type        = bool
  description = "Whether to create the namespace if it doesn't exist"
  default     = true
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

variable "oidc_issuer_url" {
  description = "OIDC Issuer URL for the API Management"
  type        = string
}

variable "tools_access" {
  description = "Configuration for tool access (tokens and groups)"
  type = map(object({
    token = string
    group = string
  }))
  default = {}
}

variable "users_access" {
  description = "Configuration for user access (ids and groups)"
  type = list(object({
    name  = string
    id    = string
    group = string
  }))
}

variable "ai_gateway" {
  description = "Configuration for the AI Gateway (new format)"
  type        = any
  default     = {}
}

variable "dns_traefiker" {
  description = "Configuration for dns-traefiker"
  type        = any
  default     = {}
}

variable "traefik_dashboard_enabled" {
  description = "Enable Traefik Dashboard"
  type        = bool
  default     = false
}

variable "unique_domain" {
  description = "Enable unique domain generation"
  type        = bool
  default     = false
}
