variable "apps" {
  description = "Map of applications to deploy with multiple replicas"
  type = map(object({
    replicas       = optional(number, 1)
    subnet_ids     = optional(list(string), [])
    port           = optional(number, 80)
    docker_image   = optional(string, "traefik/whoami:latest")
    docker_command = optional(string, "")
    tags           = optional(map(string), {})
  }))
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "common_tags" {
  description = "Common tags to apply to all instances"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC ID"
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
