variable "apis" {
  type = list(object({
    host   = string
    models = list(string)
  }))
}

variable "users" {
  type = list(object({
    username = string
    password = string
  }))
  description = "List of users with credentials for JWT authentication"
}

variable "keycloak_url" {
  type        = string
  description = "Keycloak token endpoint URL"
  default     = "http://keycloak.traefik.aiworld:8080/realms/traefik/protocol/openid-connect/token"
}

variable "keycloak_client_id" {
  type        = string
  description = "Keycloak client ID"
  default     = "traefik"
}

variable "keycloak_client_secret" {
  type        = string
  description = "Keycloak client secret"
  default     = "NoTgoLZpbrr5QvbNDIRIvmZOhe9wI0r0"
  sensitive   = true
}

variable "min_messages_per_conversation" {
  type        = number
  description = "Minimum number of messages in a conversation"
  default     = 3
}

variable "max_messages_per_conversation" {
  type        = number
  description = "Maximum number of messages in a conversation"
  default     = 8
}
