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
  default     = ""

  validation {
    condition     = var.record_type != "A" || var.ip != "" || length(var.ips) > 0
    error_message = "IP address is required for A record (set either 'ip' or 'ips')"
  }
}

variable "ips" {
  description = "List of IP addresses for the Cloudflare DNS record (Round Robin)"
  type        = list(string)
  default     = []
}

variable "hostname" {
  description = "Hostname for the Cloudflare DNS record"
  type        = string
  default     = ""

  validation {
    condition     = var.record_type != "CNAME" || var.hostname != ""
    error_message = "Hostname is required for CNAME record"
  }
}

variable "record_type" {
  description = "Type of the Cloudflare DNS record"
  type        = string
  default     = "A"
}
