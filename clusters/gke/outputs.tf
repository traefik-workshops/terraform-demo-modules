output "host" {
  description = "GKE cluster host (endpoint)"
  value       = google_container_cluster.traefik_demo.endpoint
}

output "client_certificate" {
  description = "GKE cluster client certificate"
  value       = base64decode(google_container_cluster.traefik_demo.master_auth.0.client_certificate)
}

output "client_key" {
  description = "GKE cluster client key"
  value       = base64decode(google_container_cluster.traefik_demo.master_auth.0.client_key)
}

output "cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = base64decode(google_container_cluster.traefik_demo.master_auth.0.cluster_ca_certificate)
}
