resource "digitalocean_volume" "traefik_demo_volume" {
  region                  = var.cluster_location
  name                    = "${var.cluster_name}-volume"
  size                    = 10
  initial_filesystem_type = "ext4"
  description             = "Volume for ${var.cluster_name} cluster"

  tags = [
    "cluster:${var.cluster_name}",
    "terraform:true"
  ]
}

resource "digitalocean_volume_attachment" "traefik_demo_volume_attachment" {
  count      = var.cluster_node_count
  droplet_id = digitalocean_kubernetes_cluster.traefik_demo.node_pool[0].nodes[count.index].droplet_id
  volume_id  = digitalocean_volume.traefik_demo_volume.id
}