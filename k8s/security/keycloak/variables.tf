variable "name" {
  description = "The name of the traefik release"
  type        = string
  default     = "traefik"
}

variable "namespace" {
  description = "Namespace for the Traefik Hub deployment"
  type        = string
}

variable "ingress" {
  type        = bool
  default     = false
  description = "Enable ingress for the keycloak service"
}

variable "users" {
  description = "List of users to create in the security module"
  type        = list(string)
}

variable "redirect_uris" {
  type        = list(string)
  default     = []
  description = "Allowed callback URL for the authentication flow"
}
