resource "nutanix_vpc_v2" "vpc" {
  name     = var.vpc_name
  vpc_type = var.vpc_type
  external_subnets {
    subnet_reference = var.external_subnet_uuid
  }
}

resource "nutanix_subnet_v2" "subnets" {
  for_each = var.subnets

  name          = each.key
  subnet_type   = "OVERLAY"
  vpc_reference = nutanix_vpc_v2.vpc.id

  ip_config {
    ipv4 {
      ip_subnet {
        ip {
          value = cidrhost(each.value.cidr, 0)
        }
        prefix_length = each.value.prefix_length != null ? each.value.prefix_length : tonumber(split("/", each.value.cidr)[1])
      }
      default_gateway_ip {
        value = cidrhost(each.value.cidr, 1)
      }
      pool_list {
        start_ip {
          value = cidrhost(each.value.cidr, 10)
        }
        end_ip {
          value = cidrhost(each.value.cidr, 250)
        }
      }
    }
  }
}
