variable "clusters" {
  description = "Map of ECS clusters with their applications"
  type = map(object({
    apps = map(object({
      replicas           = optional(number, 1)
      subnet_ids         = optional(list(string), [])
      port               = optional(number, 80)
      docker_image       = optional(string, "traefik/whoami:latest")
      docker_command     = optional(string, "")
      labels             = optional(map(string), {})
      security_group_ids = optional(list(string), [])
    }))
  }))
}

variable "vpc_id" {
  description = "VPC ID for ECS resources"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
  default     = []
}

variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default     = {}
}
