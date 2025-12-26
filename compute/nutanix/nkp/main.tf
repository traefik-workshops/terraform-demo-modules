locals {
  bastion_vm_ip       = nutanix_floating_ip_v2.bastion_fip.floating_ip[0].ipv4[0].value
  cluster_subnets_str = join(",", var.cluster_subnets)
}

locals {
  bastion_vm_cloud_init = templatefile("${path.module}/templates/cloud-init.tpl", {
    hostname             = "${var.cluster_name}-nkp-bastion"
    bastion_vm_username  = var.bastion_vm_username
    bastion_vm_password  = var.bastion_vm_password
    registry_mirror_url  = var.registry_mirror_url
    registry_host        = split("/", replace(replace(var.registry_mirror_url, "https://", ""), "http://", ""))[0]
    registry_mirror_full = can(regex("^http", var.registry_mirror_url)) ? var.registry_mirror_url : "https://${var.registry_mirror_url}"
  })
}

resource "nutanix_virtual_machine" "bastion_vm" {
  name                 = "${var.cluster_name}-nkp-bastion"
  cluster_uuid         = var.nutanix_cluster_id
  num_vcpus_per_socket = 2
  num_sockets          = 1
  memory_size_mib      = 4 * 1024
  disk_list {
    data_source_reference = {
      kind = "image"
      uuid = var.nkp_image_uuid
    }
    device_properties {
      device_type = "DISK"
      disk_address = {
        device_index = 0
        adapter_type = "SCSI"
      }
    }
    disk_size_bytes = 131072 * 1024 * 1024
  }
  guest_customization_cloud_init_user_data = base64encode(local.bastion_vm_cloud_init)
  nic_list {
    subnet_uuid = var.bastion_subnet_uuid
  }
}

resource "nutanix_floating_ip_v2" "bastion_fip" {
  name                      = "${var.cluster_name}-bastion-fip"
  external_subnet_reference = var.external_subnet_uuid

  association {
    vm_nic_association {
      vm_nic_reference = nutanix_virtual_machine.bastion_vm.nic_list[0].uuid
    }
  }

  depends_on = [
    nutanix_virtual_machine.bastion_vm
  ]
}

resource "null_resource" "nkp_create_cluster" {
  triggers = {
    bastion_vm_ip       = local.bastion_vm_ip
    bastion_vm_username = var.bastion_vm_username
    bastion_vm_password = var.bastion_vm_password
    # Trigger recreation if key variables change
    cluster_name = var.cluster_name
  }

  connection {
    type     = "ssh"
    user     = self.triggers.bastion_vm_username
    password = self.triggers.bastion_vm_password
    host     = self.triggers.bastion_vm_ip
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait || (echo '--- daemon.json ---'; cat /etc/docker/daemon.json; echo '--- journalctl ---'; journalctl -xeu docker.service --no-pager; exit 1)"
    ]
  }

  provisioner "file" {
    destination = "variables.sh"
    content     = <<-EOF
      export PATH=$PATH:/usr/local/bin
      export NO_COLOR=1
      export CLUSTER_NAME=${var.cluster_name}
      export CONTROL_PLANE_ENDPOINT_IP=${var.control_plane_vip}
      export LB_IP_RANGE=${var.lb_ip_range}
      export NKP_VERSION=${var.nkp_version}
      export NUTANIX_ENDPOINT=${var.nutanix_endpoint}
      export NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME=${var.nkp_image_name}
      export NUTANIX_PASSWORD='${var.nutanix_password}'
      export NUTANIX_PORT=${var.nutanix_port}
      export NUTANIX_PRISM_ELEMENT_CLUSTER_NAME=${var.nutanix_prism_element_cluster_name}
      export NUTANIX_STORAGE_CONTAINER_NAME=${var.storage_container}
      export NUTANIX_SUBNETS="${local.cluster_subnets_str}"
      export NUTANIX_USER=${var.nutanix_username}
      export REGISTRY_MIRROR_URL=${var.registry_mirror_url}

      export CP_REPLICAS=${var.control_plane_replicas}
      export CP_MEM=${var.control_plane_memory_mib}
      export CP_CPU=${var.control_plane_vcpus}
      export WORKER_REPLICAS=${var.worker_replicas}
      export WORKER_MEM=${var.worker_memory_mib}
      export WORKER_CPU=${var.worker_vcpus}
    EOF
  }

  provisioner "remote-exec" {
    script = "${path.module}/scripts/nkp_create_cluster.sh"
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "source ~/variables.sh",
      "nkp delete cluster -c $CLUSTER_NAME --self-managed || true"
    ]
  }
}

# Fetch kubeconfig from bastion after cluster creation
resource "null_resource" "fetch_kubeconfig" {
  triggers = {
    cluster_created = null_resource.nkp_create_cluster.id
  }

  provisioner "local-exec" {
    command = <<-EOF
      mkdir -p ${path.root}/.kubeconfigs
      sshpass -p '${var.bastion_vm_password}' scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        ${var.bastion_vm_username}@${local.bastion_vm_ip}:~/${var.cluster_name}.conf \
        ${path.root}/.kubeconfigs/${var.cluster_name}.conf 2>/dev/null || true
    EOF
  }

  depends_on = [null_resource.nkp_create_cluster]
}

# Update local kubeconfig with cluster context
resource "null_resource" "update_kubeconfig" {
  count = var.update_kubeconfig ? 1 : 0

  triggers = {
    kubeconfig_fetched = null_resource.fetch_kubeconfig.id
  }

  provisioner "local-exec" {
    command = <<-EOF
      KUBECONFIG_PATH="${path.root}/.kubeconfigs/${var.cluster_name}.conf"
      if [ -f "$KUBECONFIG_PATH" ]; then
        # Merge kubeconfig into default config
        KUBECONFIG="$KUBECONFIG_PATH:$HOME/.kube/config" kubectl config view --flatten > /tmp/merged-kubeconfig
        mv /tmp/merged-kubeconfig $HOME/.kube/config
        chmod 600 $HOME/.kube/config

        # Rename context to cluster name
        kubectl config delete-context "${var.cluster_name}" 2>/dev/null || true
        kubectl config rename-context "$(kubectl config current-context --kubeconfig="$KUBECONFIG_PATH")" "${var.cluster_name}" 2>/dev/null || true
        kubectl config use-context "${var.cluster_name}"

        echo "Kubeconfig updated. Context '${var.cluster_name}' added."
      else
        echo "Kubeconfig file not found at $KUBECONFIG_PATH"
      fi
    EOF
  }

  depends_on = [null_resource.fetch_kubeconfig]
}
