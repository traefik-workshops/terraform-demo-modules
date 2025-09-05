provider "kubernetes" {
  host                   = digitalocean_kubernetes_cluster.traefik_demo.endpoint
  token                  = digitalocean_kubernetes_cluster.traefik_demo.kube_config.0.token
  cluster_ca_certificate = base64decode(digitalocean_kubernetes_cluster.traefik_demo.kube_config.0.cluster_ca_certificate)
}

resource "kubernetes_storage_class" "do_block_storage" {
  metadata {
    name = "do-block-storage"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  allow_volume_expansion = true
  storage_provisioner    = "dobs.csi.digitalocean.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  reclaim_policy         = "Delete"

  parameters = {
    "csi.storage.k8s.io/fstype" = "ext4"
  }

  depends_on = [digitalocean_kubernetes_cluster.traefik_demo]
}

resource "kubernetes_storage_class" "do_block_storage_retain" {
  metadata {
    name = "do-block-storage-retain"
  }

  allow_volume_expansion = true
  storage_provisioner    = "dobs.csi.digitalocean.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  reclaim_policy         = "Retain"

  parameters = {
    "csi.storage.k8s.io/fstype" = "ext4"
  }

  depends_on = [digitalocean_kubernetes_cluster.traefik_demo]
}