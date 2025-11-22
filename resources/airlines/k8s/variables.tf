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

variable "jwt_tokens" {
  description = "Map of JWT tokens for MCP servers (ticketing, userAssistance, partnerAssistance)"
  type = object({
    ticketing         = string
    userAssistance    = string
    partnerAssistance = string
  })
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

variable "keycloak_admin_id" {
  description = "Admin user ID from Keycloak"
  type        = string
}

variable "keycloak_developer_id" {
  description = "Developer user ID from Keycloak"
  type        = string
}

variable "keycloak_agent_id" {
  description = "Agent user ID from Keycloak"
  type        = string
}
