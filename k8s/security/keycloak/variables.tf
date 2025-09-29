variable "name" {
  description = "The name of the traefik release"
  type        = string
  default     = "traefik"
}

variable "namespace" {
  description = "Namespace for the Traefik Hub deployment"
  type        = string
}

variable "users" {
  description = "List of users to create in the security module"
  type        = list(string)
}
