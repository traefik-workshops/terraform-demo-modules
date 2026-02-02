output "instances" {
  description = "Map of EC2 instances with their details"
  value       = module.ec2.instances
}

output "public_ips" {
  description = "Map of instance names to their public IP addresses (Elastic IPs if created, otherwise instance public IPs)"
  value = {
    for name, inst in module.ec2.instances : name => (
      var.create_eip ? aws_eip.traefik[name].public_ip : inst.public_ip
    )
  }
}

output "private_ips" {
  description = "Map of instance names to their private IP addresses"
  value = {
    for name, inst in module.ec2.instances : name => inst.private_ip
  }
}
