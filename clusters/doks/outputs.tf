output "cluster_endpoint" {
  value = digitalocean_kubernetes_cluster.traefik_demo.endpoint
}

output "cluster_token" {
  value     = digitalocean_kubernetes_cluster.traefik_demo.kube_config.0.token
  sensitive = true
}

output "cluster_ca_certificate" {
  value = base64decode(digitalocean_kubernetes_cluster.traefik_demo.kube_config.0.cluster_ca_certificate)
}

output "cluster_name" {
  value = digitalocean_kubernetes_cluster.traefik_demo.name
}

output "cluster_id" {
  value = digitalocean_kubernetes_cluster.traefik_demo.id
}

output "cluster_urn" {
  value = digitalocean_kubernetes_cluster.traefik_demo.urn
}

output "cluster_status" {
  value = digitalocean_kubernetes_cluster.traefik_demo.status
}

output "cluster_version" {
  value = digitalocean_kubernetes_cluster.traefik_demo.version
}

output "node_pool" {
  value = digitalocean_kubernetes_cluster.traefik_demo.node_pool
}

output "region" {
  value = digitalocean_kubernetes_cluster.traefik_demo.region
}

output "raw_config" {
  value     = digitalocean_kubernetes_cluster.traefik_demo.kube_config.0.raw_config
  sensitive = true
}

output "kubeconfig" {
  value     = digitalocean_kubernetes_cluster.traefik_demo.kube_config.0.raw_config
  sensitive = true
}