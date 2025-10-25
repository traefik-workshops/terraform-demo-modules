variable "apps" {
  description = "Map of applications to deploy to EC2. Each app can have multiple replicas."
  type        = any
  # default     = {}

    default = {
      apps = {
        whoami = {
          replicas           = 1
          subnet_ids         = []
          port               = 80
          docker_image       = "traefik/whoami:latest"
          docker_command     = ""
          labels             = {}
          security_group_ids = []
        }
      }
    }
}

variable "instance_type" {
  description = "EC2 instance type for all echo servers"
  type        = string
  default     = "t3.micro"
}

variable "common_tags" {
  description = "Common tags to apply to all instances"
  type        = map(string)
  default     = {}
}

variable "create_vpc" {
  description = "Create VPC if vpc_id is not provided"
  type        = bool
  default     = true
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