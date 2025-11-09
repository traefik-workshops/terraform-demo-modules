# Use compute/ec2 module with apps mode
locals {
  apps = {
    for app_name, app_config in var.apps : app_name => merge(
      app_config,
      {
        docker_image = "traefik/whoami:latest"
        docker_options = "-p ${app_config.port}:${app_config.port}"
      }
    )
  }
}

module "echo_instances" {
  source = "../../../compute/aws/ec2"

  # Pass through apps configuration with echo config
  apps                   = local.apps
  instance_type          = var.instance_type
  common_tags            = var.common_tags
  create_vpc             = var.create_vpc
  vpc_id                 = var.vpc_id
  subnet_ids             = var.subnet_ids
  security_group_ids     = var.security_group_ids
}