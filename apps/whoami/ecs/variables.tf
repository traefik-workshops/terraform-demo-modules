variable "clusters" {
  description = "Map of ECS clusters with their echo applications."
  type        = any
  default     = {}
}

variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC ID for ECS resources"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "List of subnet IDs for ECS resources"
  type        = list(string)
  default     = []
}
