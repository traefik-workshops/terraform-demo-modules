data "google_client_config" "traefik_demo" {}

resource "google_container_cluster" "traefik_demo" {
  name                = var.cluster_name
  min_master_version  = var.gke_version
  location            = var.cluster_location
  deletion_protection = false
  initial_node_count  = var.cluster_node_count

  node_config {
    machine_type = var.cluster_machine_type
  }

  monitoring_config {
    managed_prometheus {
      enabled = false
    }
  }
}
