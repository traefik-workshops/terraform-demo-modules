resource "linode_lke_cluster" "traefik_demo" {
  label       = var.cluster_name
  region      = var.cluster_location
  k8s_version = var.lke_version

  pool {
    type  = var.cluster_node_type
    count = var.cluster_node_count
  }
}

resource "linode_lke_node_pool" "traefik_demo_gpu" {
  cluster_id  = linode_lke_cluster.traefik_demo.id
  type  = var.gpu_node_type
  node_count = var.gpu_node_count
}