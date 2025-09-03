variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "aks_version" {
  type        = string
  default     = "1.30"
  description = "AKS Kubernetes version"
}

variable "cluster_name" {
  type        = string
  description = "AKS cluster name"
}

variable "cluster_location" {
  type        = string
  default     = "westus"
  description = "AKS cluster location"
}

variable "cluster_node_type" {
  type        = string
  default     = "Standard_B2s"
  description = "Default node type for cluster"
}

variable "cluster_node_count" {
  type        = number
  default     = 1
  description = "Number of nodes for the cluster"
}

variable "enable_gpu" {
  type        = bool
  default     = false
  description = "Enable GPU nodes"
}

variable "gpu_node_type" {
  type        = string
  default     = ""
  description = "GPU node type for cluster"
}

variable "gpu_node_count" {
  type        = number
  default     = 1
  description = "Number of GPU nodes for the cluster"
}

variable "update_kubeconfig" {
  type        = bool
  default     = true
  description = "Update kubeconfig after cluster creation"
}
