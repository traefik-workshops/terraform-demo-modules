resource "nutanix_floating_ip_v2" "fip" {
  name                      = var.name
  external_subnet_reference = var.external_subnet_uuid

  association {
    dynamic "vm_nic_association" {
      for_each = var.vm_nic_uuid != "" ? [1] : []
      content {
        vm_nic_reference = var.vm_nic_uuid
      }
    }

    dynamic "private_ip_association" {
      for_each = var.private_ip != "" && var.vpc_uuid != "" ? [1] : []
      content {
        vpc_reference = var.vpc_uuid
        private_ip {
          ipv4 {
            value = var.private_ip
          }
        }
      }
    }
  }
}
