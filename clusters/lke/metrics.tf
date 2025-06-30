provider "helm" {
  kubernetes = {
    host                    = local.cluster_server
    cluster_ca_certificate  = local.cluster_ca_cert
    token                   = local.token
  }
}

provider "kubernetes" {
  host                    = local.cluster_server
  cluster_ca_certificate  = local.cluster_ca_cert
  token                   = local.token
}

resource "null_resource" "wait" {
  depends_on = [linode_lke_cluster.traefik_demo]

  provisioner "local-exec" {
    command = <<EOF
    sleep 10
    EOF
  }
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.12.2"

  namespace  = "kube-system"

  depends_on = [null_resource.wait]
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
