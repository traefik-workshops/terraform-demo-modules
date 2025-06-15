variable "cluster_name" {
  type        = string
  description = "LKE cluster name"
}

variable "cluster_location" {
  type        = string
  default     = "us-sea"
  description = "LKE cluster location"
}

variable "cluster_machine_type" {
  type        = string
  default     = "g6-dedicated-2"
  description = "Default machine type for cluster"
}

variable "cluster_node_count" {
  type        = number
  default     = 1
  description = "Number of nodes for the cluster"
}

variable "lke_version" {
  type        = string
  default     = "1.33"
  description = "LKE Kubernetes version"
}
