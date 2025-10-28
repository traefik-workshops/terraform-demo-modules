resource "cloudflare_dns_record" "root" {
  zone_id = var.zone_id
  name    = var.domain
  content = var.ip
  type    = "A"
  ttl     = 1
  proxied = false
}

resource "cloudflare_dns_record" "wildcard" {
  zone_id = var.zone_id
  name    = "*.${var.domain}"
  content = var.ip
  type    = "A"
  ttl     = 1
  proxied = false
}

resource "cloudflare_dns_record" "wildcard_traefik" {
  zone_id = var.zone_id
  name    = "*.traefik.${var.domain}"
  content = var.ip
  type    = "A"
  ttl     = 1
  proxied = false
}
