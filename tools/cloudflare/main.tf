# Cloudflare Zone Data Source
data "cloudflare_zone" "traefikhub" {
  zone_id = var.zone_id
}

resource "cloudflare_record" "root" {
  zone_id = data.cloudflare_zone.traefikhub.id
  name    = var.domain
  content = var.ip
  type    = "A"
  ttl     = 1
  proxied = false
}

resource "cloudflare_record" "wildcard" {
  zone_id = data.cloudflare_zone.traefikhub.id
  name    = "*.${var.domain}"
  content = var.ip
  type    = "A"
  ttl     = 1
  proxied = false
}

resource "cloudflare_record" "wildcard_traefik" {
  zone_id = data.cloudflare_zone.traefikhub.id
  name    = "*.traefik.${var.domain}"
  content = var.ip
  type    = "A"
  ttl     = 1
  proxied = false
}
