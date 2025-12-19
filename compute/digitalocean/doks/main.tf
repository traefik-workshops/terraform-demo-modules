resource "digitalocean_kubernetes_cluster" "traefik_demo" {
  name    = var.cluster_name
  region  = var.cluster_location
  version = var.doks_version

  node_pool {
    name       = "default"
    size       = var.cluster_node_type
    node_count = var.cluster_node_count
    auto_scale = var.enable_autoscaling
    min_nodes  = var.min_nodes
    max_nodes  = var.max_nodes
  }
}

resource "null_resource" "wait" {
  depends_on = [digitalocean_kubernetes_cluster.traefik_demo]

  provisioner "local-exec" {
    command = <<EOF
    sleep 30
    EOF
  }
}

resource "null_resource" "doks_cluster" {
  provisioner "local-exec" {
    command = <<EOT
      echo '${digitalocean_kubernetes_cluster.traefik_demo.kube_config.0.raw_config}' > doks-kubeconfig.yaml

      export KUBECONFIG=~/.kube/config:doks-kubeconfig.yaml
      kubectl config view --flatten > merged.yaml
      mv merged.yaml ~/.kube/config

      kubectl config delete-context "doks-${var.cluster_name}" 2>/dev/null || true
      kubectl config rename-context "do-${var.cluster_location}-${var.cluster_name}" "doks-${var.cluster_name}"
      kubectl config use-context "doks-${var.cluster_name}"

      rm doks-kubeconfig.yaml
    EOT
  }

  triggers = {
    always_run = timestamp()
  }

  count      = var.update_kubeconfig ? 1 : 0
  depends_on = [null_resource.wait]
}