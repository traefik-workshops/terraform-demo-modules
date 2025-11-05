locals {
  clusters = {
    for cluster_name, cluster_config in var.clusters : cluster_name => merge(
      cluster_config,
      {
        apps = {
          for app_name, app_config in cluster_config.apps : app_name => merge(
            app_config,
            {
              docker_image       = "traefik/whoami:latest"
              subnet_ids         = try(coalesce(app_config.subnet_ids, cluster_config.subnet_ids, var.subnet_ids), var.subnet_ids)
              security_group_ids = try(coalesce(app_config.security_group_ids, cluster_config.security_group_ids, []), [])
            }
          )
        }
      }
    )
  }
}

module "echo_services" {
  source = "../../../compute/aws/ecs"

  clusters           = local.clusters
  create_vpc         = var.create_vpc
  vpc_id             = var.vpc_id
  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids
  common_labels      = var.common_labels
}
