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

variable "ingress_internal" {
  type        = bool
  default     = true
  description = "Enable ingress for the keycloak service"
}

variable "ingress_domain" {
  type        = string
  default     = "cloud"
  description = "The domain for the ingress, default is `cloud`"
}

variable "ingress_entrypoint" {
  type        = string
  default     = "traefik"
  description = "The entrypoint to use for the ingress, default is `traefik`"
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

variable "advanced_users" {
  description = "List of advanced users with detailed configuration including groups and claims"
  type = list(object({
    username = string
    email    = string
    password = string
    groups   = list(string)
    claims   = map(list(string))
  }))
  default = []
}

variable "access_token_lifespan" {
  description = "The lifespan of the access token in seconds"
  type        = number
  default     = 2419200 # 28 days
}

variable "host" {
  type    = string
  default = ""
}

variable "client_certificate" {
  type    = string
  default = ""
}

variable "client_key" {
  type    = string
  default = ""
}

variable "chart" {
  type        = string
  description = "Path to the Helm chart for the Keycloak deployment"
}
