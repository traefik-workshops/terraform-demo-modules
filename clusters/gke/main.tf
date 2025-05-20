data "google_client_config" "traefik_demo" {}

resource "google_container_cluster" "traefik_demo" {
  name                = var.cluster_name
  min_master_version  = var.gke_version
  location            = var.cluster_location
  deletion_protection = false

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  monitoring_config {
    managed_prometheus {
      enabled = false
    }
  }
}

resource "google_container_node_pool" "traefik_demo" {
  name       = "${var.cluster_name}-np"
  cluster    = google_container_cluster.traefik_demo.name
  version    = var.gke_version
  location   = google_container_cluster.traefik_demo.location
  node_count = var.cluster_node_count

  node_config {
    machine_type = var.cluster_node_machine_type
  }
}