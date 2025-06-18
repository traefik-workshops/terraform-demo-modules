resource "linode_lke_cluster" "traefik_demo" {
  label       = var.cluster_name
  region      = var.cluster_location
  k8s_version = var.lke_version

  pool {
    type  = var.cluster_node_type
    count = var.cluster_node_count
  }

  dynamic "pool" {
    for_each = var.enable_gpu ? ["gpu"] : []
    content {
      type  = var.gpu_node_type
      count = var.gpu_node_count
    }
  }
}
