locals {
  clusters = {
    for cluster_name, cluster_config in var.clusters : cluster_name => merge(
      cluster_config,
      {
        apps = {
          for app_name, app_config in cluster_config.apps : app_name => merge(
            app_config,
            {
              docker_image = "traefik/whoami:latest"
            }
          )
        }
      }
    )
  }
}

module "echo_services" {
  source = "../../../compute/aws/ecs"

  clusters      = local.clusters
  create_vpc    = var.create_vpc
  vpc_id        = var.vpc_id
  subnet_ids    = var.subnet_ids
  common_labels = var.common_labels
}
