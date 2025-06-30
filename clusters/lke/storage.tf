provider "kubernetes" {
  host                    = local.cluster_server
  cluster_ca_certificate  = local.cluster_ca_cert
  token                   = local.token
}

resource "kubernetes_storage_class" "default" {
  metadata {
    name = "default"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  allow_volume_expansion = true
  storage_provisioner    = "linode.com/linode-block-storage"
  volume_binding_mode    = "Immediate"
  reclaim_policy         = "Delete"

  depends_on = [null_resource.wait]
}
