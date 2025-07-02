variable "eks_version" {
  type        = string
  default     = ""
  description = "EKS cluster version."
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name."
}

variable "cluster_location" {
  type        = string
  default     = "us-west-1"
  description = "EKS cluster location."
}

variable "cluster_node_count" {
  type        = number
  default     = 1
  description = "Number of nodes for the cluster."
}

variable "cluster_node_type" {
  type        = string
  default     = "t3.medium"
  description = "Default machine type for cluster"
}

variable "cluster_machine_ami_type" {
  type        = string
  default     = "AL2_x86_64"
  description = "EKS cluster AMI Type."
}
