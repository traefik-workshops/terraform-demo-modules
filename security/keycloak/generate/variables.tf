variable "keycloak_url" {
  description = "Keycloak base URL (e.g., https://keycloak.example.com)"
  type        = string
}

variable "realm" {
  description = "Keycloak realm name"
  type        = string
  default     = "traefik"
}

variable "client_id" {
  description = "Keycloak client ID"
  type        = string
  default     = "traefik"
}

variable "client_secret" {
  description = "Keycloak client secret"
  type        = string
  sensitive   = true
}

variable "users" {
  description = "List of users to generate JWT tokens for"
  type = list(object({
    username = string
    password = string
  }))
}

variable "token_rotation_hours" {
  description = "Number of hours after which tokens should rotate (only when terraform apply is run)"
  type        = number
  default     = 4
}
