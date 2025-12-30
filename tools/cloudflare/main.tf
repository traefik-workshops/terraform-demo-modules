locals {
  # Combine legacy 'ip' and new 'ips' for A records, or use 'hostname' for CNAME
  record_targets = var.record_type == "A" ? concat(var.ip != "" ? [var.ip] : [], var.ips) : [var.hostname]
}

resource "cloudflare_dns_record" "root" {
  for_each = toset(local.record_targets)

  zone_id = var.zone_id
  name    = var.domain
  content = each.value
  type    = var.record_type
  ttl     = 1
  proxied = false
}

resource "cloudflare_dns_record" "wildcard" {
  for_each = toset(local.record_targets)

  zone_id = var.zone_id
  name    = "*.${var.domain}"
  content = each.value
  type    = var.record_type
  ttl     = 1
  proxied = false
}
