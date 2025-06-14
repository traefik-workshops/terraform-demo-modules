variable "cluster_name" {
  type        = string
  description = "GKE cluster name."
}

variable "cluster_location" {
  type        = string
  default     = "us-west1-a"
  description = "GKE cluster location."
}

variable "cluster_node_count" {
  type        = number
  default     = 1
  description = "Number of nodes for the cluster."
}

variable "cluster_machine_type" {
  type        = string
  default     = "e2-standard-2"
  description = "Default machine type for cluster"
}

variable "gke_version" {
  type        = string
  default     = ""
  description = "GKE cluster version."
}

variable "enable_gpu" {
  type        = bool
  default     = false
  description = "Enable GPU nodes"
}
