variable "cluster_name" {
  type        = string
  description = "AKS cluster name"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "cluster_location" {
  type        = string
  default     = "westus"
  description = "AKS cluster location"
}

variable "cluster_machine_type" {
  type        = string
  default     = "Standard_B2s"
  description = "Default machine type for cluster"
}

variable "cluster_node_count" {
  type        = number
  default     = 1
  description = "Number of nodes for the cluster"
}

variable "aks_version" {
  type        = string
  default     = "1.30"
  description = "AKS Kubernetes version"
}
