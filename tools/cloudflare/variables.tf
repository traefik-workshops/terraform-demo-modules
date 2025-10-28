variable "zone_id" {
  description = "The zone ID of the Cloudflare DNS record"
  type        = string
}

variable "domain" {
  description = "Domain for the Cloudflare DNS record"
  type        = string
}

variable "ip" {
  description = "IP address for the Cloudflare DNS record"
  type        = string
}