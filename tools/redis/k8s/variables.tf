variable "name" {
  description = "The name of the redis release"
  type        = string
  default     = "traefik"
}

variable "namespace" {
  description = "Namespace for the Redis deployment"
  type        = string
}

variable "password" {
  description = "Redis password"
  type        = string
  default     = "topsecretpassword"
}

variable "replicaCount" {
  description = "Number of replicas for the Redis deployment"
  type        = number
  default     = 1
}
