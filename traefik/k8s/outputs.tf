output "load_balancer_ip" {
  description = "The Load Balancer IP of the Traefik Service"
  value       = try(data.kubernetes_service.traefik.status.0.load_balancer.0.ingress.0.ip, "")
}

data "kubernetes_service" "traefik" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }

  depends_on = [helm_release.traefik]
}
