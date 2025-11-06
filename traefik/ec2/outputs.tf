output "instances" {
  description = "Map of EC2 instances with their details"
  value       = module.ec2.instances
}
