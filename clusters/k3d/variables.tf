variable "cluster_name" {
  type        = string
  description = "k3d cluster name."
}

variable "control_plane_nodes" {
  type = object({
    count = number
  })
  default     = { count: 1 }
  description = "Cluster Control Plane node config."
}

variable "worker_nodes" {
  type = list(object({
    label = string
    taint = string
    count = number
  }))
  default = []
  description = "Worker node config."
}

variable "ports" {
  type = list(object({
    from = number
    to   = number
  }))
  default = [
    { from: 80,   to: 8000},
    { from: 8443, to: 443},
    { from: 8080, to: 8080},
  ]
}
