variable "name" {
  type        = string
  description = "The name of the higher-ed release"
  default     = "higher-ed"
}

variable "namespace" {
  type        = string
  description = "Namespace for the higher-ed deployment"
  default     = "default"
}

variable "create_namespace" {
  type        = bool
  description = "Whether to create the namespace if it doesn't exist"
  default     = true
}

variable "domain" {
  description = "Base domain for all services"
  type        = string
  default     = "demo.traefik.ai"
}

variable "git_ref" {
  description = "Git reference (branch, tag, or commit) for traefik-demo-resources"
  type        = string
  default     = "main"
}

variable "oidc_client_id" {
  description = "OIDC client ID"
  type        = string
}

variable "oidc_client_secret" {
  description = "OIDC client secret"
  type        = string
  sensitive   = true
}

# User ID Variables
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
