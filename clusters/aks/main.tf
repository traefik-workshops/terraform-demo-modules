resource "azurerm_kubernetes_cluster" "traefik_demo" {
  name                = var.cluster_name
  location            = var.cluster_location
  kubernetes_version  = var.aks_version
  resource_group_name = var.resource_group_name
  dns_prefix          = replace(var.cluster_name, "_", "-")

  default_node_pool {
    name       = "default"
    node_count = var.cluster_node_count
    vm_size    = var.cluster_node_type

    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "traefik_demo_gpu" {
  name                  = "gpu"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.traefik_demo.id
  vm_size               = var.gpu_node_type
  node_count            = var.gpu_node_count

  node_labels = {
    accelerator = "nvidia"
  }

  node_taints = [
    "nvidia.com/gpu=true:NoSchedule"
  ]

  upgrade_settings {
    drain_timeout_in_minutes      = 0
    max_surge                     = "10%"
    node_soak_duration_in_minutes = 0
  }

  count = var.enable_gpu ? 1 : 0
}
