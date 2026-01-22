resource "linode_lke_cluster" "traefik_demo" {
  label       = var.cluster_name
  region      = var.cluster_location
  k8s_version = var.lke_version

  control_plane {
    high_availability = var.control_plane_high_availability
  }

  pool {
    type   = var.cluster_node_type
    count  = var.cluster_node_count
    labels = var.node_labels
  }

  dynamic "pool" {
    for_each = var.enable_gpu ? ["gpu"] : []
    content {
      type   = var.gpu_node_type
      count  = var.gpu_node_count
      labels = var.node_labels
    }
  }
}

resource "null_resource" "wait" {
  depends_on = [linode_lke_cluster.traefik_demo]

  provisioner "local-exec" {
    command = <<EOF
    sleep 30
    EOF
  }
}

resource "null_resource" "lke_cluster" {
  provisioner "local-exec" {

    command = <<EOT
      echo '${local.kubeconfig_raw}' > lke-kubeconfig.yaml

      export KUBECONFIG=~/.kube/config:lke-kubeconfig.yaml
      kubectl config view --flatten > merged.yaml
      mv merged.yaml ~/.kube/config

      kubectl config delete-context "${var.cluster_name_prefix}${var.cluster_name}" 2>/dev/null || true
      kubectl config rename-context "lke${linode_lke_cluster.traefik_demo.id}-ctx" "${var.cluster_name_prefix}${var.cluster_name}"
      kubectl config use-context "${var.cluster_name_prefix}${var.cluster_name}"

      rm lke-kubeconfig.yaml
    EOT
  }

  triggers = {
    always_run = timestamp()
  }

  count      = var.update_kubeconfig ? 1 : 0
  depends_on = [null_resource.wait]
}
