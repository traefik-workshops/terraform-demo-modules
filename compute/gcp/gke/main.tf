data "google_client_config" "traefik_demo" {}

resource "google_container_cluster" "traefik_demo" {
  name                = var.cluster_name
  min_master_version  = var.gke_version
  location            = var.cluster_location
  deletion_protection = false
  initial_node_count  = var.cluster_node_count

  node_config {
    machine_type = var.cluster_node_type
    disk_type    = "pd-standard"
  }

  monitoring_config {
    managed_prometheus {
      enabled = false
    }
  }
}

resource "google_container_node_pool" "traefik_demo_gpu" {
  name       = "${google_container_cluster.traefik_demo.name}-gpu"
  location   = var.cluster_location
  cluster    = google_container_cluster.traefik_demo.name
  node_count = var.gpu_node_count

  node_config {
    machine_type = var.gpu_node_type
    disk_type    = "pd-standard"

    guest_accelerator {
      type  = var.gpu_type
      count = var.gpu_count
    }
  }

  count = var.enable_gpu ? 1 : 0
}

resource "null_resource" "gke_cluster" {
  provisioner "local-exec" {
    command = <<EOT
      gcloud container clusters get-credentials ${var.cluster_name} \
        --zone ${var.cluster_location} \
        --project ${data.google_client_config.traefik_demo.project}

      kubectl config delete-context "gke-${var.cluster_name}" 2>/dev/null || true
      kubectl config rename-context "gke_${data.google_client_config.traefik_demo.project}_${var.cluster_location}_${var.cluster_name}" "gke-${var.cluster_name}"
      kubectl config use-context "gke-${var.cluster_name}"
    EOT
  }

  triggers = {
    always_run = timestamp()
  }

  count      = var.update_kubeconfig ? 1 : 0
  depends_on = [google_container_cluster.traefik_demo, google_container_node_pool.traefik_demo_gpu]
}
