variable "apps" {
  description = "Map of applications to deploy to Kubernetes. Each app can have multiple replicas."
  default     = {}
  type = map(object({
    replicas     = optional(number, 1)
    port         = optional(number, 80)
    docker_image = optional(string, "traefik/whoami:latest")
    labels       = optional(map(string), {})
    ingress_route = optional(object({
      enabled     = optional(bool, false)
      host        = optional(string)
      entrypoints = optional(list(string), ["web"])
      middlewares = optional(list(object({
        name      = string
        namespace = optional(string)
      })), [])
      strip_prefix = optional(object({
        enabled  = optional(bool, false)
        prefixes = optional(list(string), [])
      }), {})
    }), {})
  }))
}

variable "namespace" {
  description = "Kubernetes namespace to deploy applications"
  type        = string
  default     = "apps"
}

variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "node_selector" {
  description = "Node selector for pod scheduling"
  type        = map(string)
  default     = {}
}
