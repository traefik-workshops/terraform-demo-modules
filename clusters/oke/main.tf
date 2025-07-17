# Generate SSH key pair
resource "tls_private_key" "traefik_demo" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

data "oci_identity_availability_domains" "traefik_demo" {
  compartment_id = var.compartment_id
}

data "oci_core_images" "traefik_demo" {
  compartment_id           = var.compartment_id
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = var.cluster_node_type
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Create VCN
resource "oci_core_vcn" "traefik_demo" {
  compartment_id = var.compartment_id
  display_name   = "${var.cluster_name}-vcn"
  cidr_blocks    = ["10.0.0.0/16"]
  dns_label      = "oke${replace(var.cluster_name, "-", "")}"
}

# Create Internet Gateway
resource "oci_core_internet_gateway" "traefik_demo" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.traefik_demo.id
  display_name   = "${var.cluster_name}-igw"
  enabled        = true
}

resource "oci_core_nat_gateway" "traefik_demo" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.traefik_demo.id
  display_name   = "${var.cluster_name}-natgw"
}

# Create Route Table
resource "oci_core_route_table" "traefik_demo" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.traefik_demo.id
  display_name   = "${var.cluster_name}-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.traefik_demo.id
  }
}

# Create Security List
resource "oci_core_security_list" "traefik_demo" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.traefik_demo.id
  display_name   = "${var.cluster_name}-sl"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    source   = "10.0.0.0/16"
    protocol = "all"
  }

  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = "6"
    tcp_options {
      min = 6443
      max = 6443
    }
  }
}

# Create Endpoint Subnet
resource "oci_core_subnet" "traefik_demo_endpoint" {
  compartment_id      = var.compartment_id
  vcn_id              = oci_core_vcn.traefik_demo.id
  display_name        = "${var.cluster_name}-endpoint-subnet"
  cidr_block          = "10.0.1.0/24"
  route_table_id      = oci_core_route_table.traefik_demo.id
  security_list_ids   = [oci_core_security_list.traefik_demo.id]
  dns_label           = "endpoint"
  prohibit_public_ip_on_vnic = false
}

# Create Node Subnet
resource "oci_core_subnet" "traefik_demo_nodes" {
  compartment_id      = var.compartment_id
  vcn_id              = oci_core_vcn.traefik_demo.id
  display_name        = "${var.cluster_name}-nodes-subnet"
  cidr_block          = "10.0.2.0/24"
  route_table_id      = oci_core_route_table.traefik_demo.id
  security_list_ids   = [oci_core_security_list.traefik_demo.id]
  dns_label           = "nodes"
  prohibit_public_ip_on_vnic = false
}

# Create Load Balancer Subnet
resource "oci_core_subnet" "traefik_demo_lb" {
  compartment_id      = var.compartment_id
  vcn_id              = oci_core_vcn.traefik_demo.id
  display_name        = "${var.cluster_name}-lb-subnet"
  cidr_block          = "10.0.3.0/24"
  route_table_id      = oci_core_route_table.traefik_demo.id
  security_list_ids   = [oci_core_security_list.traefik_demo.id]
  dns_label           = "lb"
  prohibit_public_ip_on_vnic = false
}

# Create OKE Cluster
resource "oci_containerengine_cluster" "traefik_demo" {
  compartment_id     = var.compartment_id
  kubernetes_version = var.oke_version
  name               = var.cluster_name
  vcn_id             = oci_core_vcn.traefik_demo.id

  cluster_pod_network_options {
    cni_type = "OCI_VCN_IP_NATIVE"
  }

  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.traefik_demo_endpoint.id
  }

  options {
    service_lb_subnet_ids = [oci_core_subnet.traefik_demo_lb.id]
    
    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }
    
    admission_controller_options {
      is_pod_security_policy_enabled = false
    }
    
    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
  }
}

# Create Node Pool
resource "oci_containerengine_node_pool" "traefik_demo" {
  cluster_id         = oci_containerengine_cluster.traefik_demo.id
  compartment_id     = var.compartment_id
  kubernetes_version = var.oke_version
  name               = "${var.cluster_name}-pool"
  node_shape         = var.cluster_node_type

  node_config_details {
    node_pool_pod_network_option_details {
      cni_type = "OCI_VCN_IP_NATIVE"
      pod_subnet_ids = [oci_core_subnet.traefik_demo_nodes.id]
    } 
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.traefik_demo.availability_domains[0].name
      subnet_id           = oci_core_subnet.traefik_demo_nodes.id
    }
    size = var.cluster_node_count
  }

  node_shape_config {
    ocpus         = 2
    memory_in_gbs = 16
  }

  node_source_details {
    image_id    = data.oci_core_images.traefik_demo.images[0].id
    source_type = "IMAGE"
  }

  ssh_public_key = tls_private_key.traefik_demo.public_key_openssh
}

data "oci_containerengine_cluster_kube_config" "kubeconfig" {
  token_version = "2.0.0"
  cluster_id    = oci_containerengine_cluster.traefik_demo.id
  endpoint      = "PUBLIC_ENDPOINT"

  depends_on = [oci_containerengine_node_pool.traefik_demo]
}

data "external" "cluster_token" {
  depends_on = [oci_containerengine_node_pool.traefik_demo]
  
  program = ["bash", "-c", <<-EOT
    token_response=$(oci ce cluster generate-token --cluster-id ${oci_containerengine_cluster.traefik_demo.id} --region ${var.cluster_location})
    token=$(echo "$token_response" | awk -F'"' '/"token":/ {print $4}')
    echo "{\"token\":\"$token\"}"
  EOT
  ]
}
