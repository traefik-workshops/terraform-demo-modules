output "public_ip" {
  description = "The allocated Floating IP address"
  value       = try(nutanix_floating_ip_v2.fip.floating_ip[0].ipv4[0].value, "")
}

output "id" {
  description = "The ID of the Floating IP"
  value       = nutanix_floating_ip_v2.fip.id
}
