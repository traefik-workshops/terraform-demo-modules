module "traefik_vm" {
  source = "../../compute/nutanix/vm"

  name                 = var.vm_name
  cluster_uuid         = var.cluster_id
  subnet_uuid          = var.subnet_uuid
  image_uuid           = var.image_id
  num_vcpus_per_socket = var.vm_num_vcpus_per_socket
  num_sockets          = var.vm_num_sockets
  memory_size_mib      = var.vm_memory_mib

  cloud_init_user_data = templatefile("${path.module}/cloud-init.tpl", {
    traefik_config     = var.traefik_static_config
    traefik_hub_token  = var.traefik_hub_token
    entry_points       = var.entry_points
    enable_dashboard   = var.enable_dashboard
    dashboard_insecure = var.dashboard_insecure

    log_level                    = var.log_level
    enable_prometheus            = var.enable_prometheus
    metrics_port                 = var.metrics_port
    otlp_address                 = var.otlp_address
    otlp_service_name            = var.otlp_service_name
    enable_otlp_metrics          = var.enable_otlp_metrics
    enable_otlp_traces           = var.enable_otlp_traces
    enable_otlp_access_logs      = var.enable_otlp_access_logs
    enable_otlp_application_logs = var.enable_otlp_application_logs
    custom_plugins               = var.custom_plugins
    custom_envs                  = var.custom_envs
    file_provider_config         = var.file_provider_config
  })
}

output "ip_address" {
  value = module.traefik_vm.ip_address
}
