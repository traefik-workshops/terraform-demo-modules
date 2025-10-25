# Create Kubernetes deployments for each app
resource "kubernetes_deployment" "echo" {
  for_each = var.apps

  metadata {
    name      = each.key
    namespace = var.namespace
    labels = merge(
      var.common_labels,
      each.value.labels,
      {
        app = each.key
      }
    )
  }

  spec {
    replicas = each.value.replicas

    selector {
      match_labels = {
        app = each.key
      }
    }

    template {
      metadata {
        labels = merge(
          var.common_labels,
          each.value.labels,
          {
            app = each.key
          }
        )
      }

      spec {
        container {
          name              = each.key
          image             = each.value.docker_image
          image_pull_policy = "IfNotPresent"

          port {
            container_port = each.value.port
          }

          env {
            name  = "APP_NAME"
            value = each.key
          }

          env {
            name  = "WHOAMI_NAME"
            value = each.key
          }

          env {
            name = "POD_NAME"
            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }

          env {
            name = "POD_IP"
            value_from {
              field_ref {
                field_path = "status.podIP"
              }
            }
          }

          env {
            name  = "REPLICA_NUMBER"
            value = "k8s-managed"
          }
        }
      }
    }
  }
}

# Create Kubernetes services for each app
resource "kubernetes_service" "echo" {
  for_each = var.apps

  metadata {
    name      = "${each.key}-svc"
    namespace = var.namespace
    labels = merge(
      var.common_labels,
      each.value.labels,
      {
        app = each.key
      }
    )
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = each.key
    }

    port {
      port        = each.value.port
      target_port = each.value.port
    }
  }

  depends_on = [kubernetes_deployment.echo]
}
