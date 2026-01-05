locals {
  bastion_vm_ip       = nutanix_floating_ip_v2.bastion_fip.floating_ip[0].ipv4[0].value
  cluster_subnets_str = join(",", var.cluster_subnets)

  bastion_vm_cloud_init = templatefile("${path.module}/templates/cloud-init.tpl", {
    hostname             = "${var.cluster_name}-nkp-bastion"
    bastion_vm_username  = var.bastion_vm_username
    bastion_vm_password  = var.bastion_vm_password
    registry_mirror_url  = var.registry_mirror_url
    registry_host        = split("/", replace(replace(var.registry_mirror_url, "https://", ""), "http://", ""))[0]
    registry_mirror_full = can(regex("^http", var.registry_mirror_url)) ? var.registry_mirror_url : "https://${var.registry_mirror_url}"
  })

  control_plane_fip = nutanix_floating_ip_v2.control_plane_fip.floating_ip[0].ipv4[0].value
}

resource "nutanix_virtual_machine" "bastion_vm" {
  name                 = "${var.cluster_name}-bastion"
  cluster_uuid         = var.nutanix_cluster_id
  num_vcpus_per_socket = 8
  num_sockets          = 1
  memory_size_mib      = 16 * 1024
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

resource "nutanix_floating_ip_v2" "control_plane_fip" {
  name                      = "${var.cluster_name}-control-plane-fip"
  external_subnet_reference = var.external_subnet_uuid

  association {
    private_ip_association {
      vpc_reference = var.vpc_uuid
      private_ip {
        ipv4 {
          value = var.control_plane_vip
        }
      }
    }
  }

  depends_on = [null_resource.nkp_create_cluster]
}

resource "null_resource" "nkp_create_cluster" {
  triggers = {
    bastion_vm_id       = nutanix_virtual_machine.bastion_vm.metadata.uuid
    bastion_vm_ip       = local.bastion_vm_ip
    bastion_vm_username = var.bastion_vm_username
    bastion_vm_password = var.bastion_vm_password
    cluster_name        = var.cluster_name
    control_plane_vip   = var.control_plane_vip
    lb_ip_range         = var.lb_ip_range
    create_script_hash  = filesha256("${path.module}/scripts/nkp_create_cluster.sh")
    delete_script_hash  = filesha256("${path.module}/scripts/cleanup_nutanix_resources.py")
    nutanix_endpoint    = var.nutanix_endpoint
    nutanix_port        = var.nutanix_port
    nutanix_username    = var.nutanix_username
    nutanix_password    = var.nutanix_password
    storage_container   = var.storage_container
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
    export NUTANIX_USER="${var.nutanix_username}"
    export NUTANIX_PASSWORD="${var.nutanix_password}"
    export NUTANIX_ENDPOINT="${var.nutanix_endpoint}"
    export NUTANIX_PORT="${var.nutanix_port}"
    export NUTANIX_INSECURE="${var.nutanix_insecure}"
    export NUTANIX_PRISM_ELEMENT_CLUSTER_NAME="${var.nutanix_prism_element_cluster_name}"
    export NUTANIX_SUBNETS="${join(",", var.cluster_subnets)}"
    export NUTANIX_CLUSTER_NAME="${var.cluster_name}"
    export CLUSTER_NAME="${var.cluster_name}"
    export NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME="${var.nkp_image_name}"
    export NUTANIX_STORAGE_CONTAINER_NAME="${var.storage_container}"
    export CONTROL_PLANE_ENDPOINT_IP="${var.control_plane_vip}"
    export LB_IP_RANGE="${var.lb_ip_range}"
    export NKP_VERSION="${var.nkp_version}"
    export REGISTRY_MIRROR_URL="${var.registry_mirror_url}"
    export BASTION_IMAGE_NAME="${var.bastion_image_name}"
    export CP_REPLICAS="${var.control_plane_replicas}"
    export WORKER_REPLICAS="${var.worker_replicas}"
    export CP_MEM="${var.control_plane_memory_mib}"
    export CP_CPU="${var.control_plane_vcpus}"
    export WORKER_MEM="${var.worker_memory_mib}"
    export WORKER_CPU="${var.worker_vcpus}"
    export KUBERNETES_VERSION="${var.kubernetes_version}"
    EOF
  }

  provisioner "remote-exec" {
    script = "${path.module}/scripts/nkp_create_cluster.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/cleanup_nutanix_resources.py"
    destination = "cleanup_nutanix_resources.py"
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "pip3 install 'ntnx-vmm-py-client<4.2' 'ntnx-volumes-py-client<4.2' requests --quiet",
      "NUTANIX_ENDPOINT=${self.triggers.nutanix_endpoint} NUTANIX_PORT=${self.triggers.nutanix_port} NUTANIX_USERNAME=${self.triggers.nutanix_username} NUTANIX_PASSWORD=${self.triggers.nutanix_password} python3 cleanup_nutanix_resources.py --vm-pattern '^(?!.*-bastion$).*${self.triggers.cluster_name}.*' --storage-container ${self.triggers.storage_container}"
    ]
  }

  depends_on = [nutanix_floating_ip_v2.bastion_fip]
}

# Fetch kubeconfig content from bastion and store in terraform state
resource "terraform_data" "kubeconfig" {
  triggers_replace = [null_resource.nkp_create_cluster.id, nutanix_floating_ip_v2.control_plane_fip.id]

  provisioner "local-exec" {
    command = <<-EOF
      # Fetch kubeconfig from bastion
      sshpass -p '${var.bastion_vm_password}' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        ${var.bastion_vm_username}@${local.bastion_vm_ip} "cat ~/${var.cluster_name}.conf" \
        > /tmp/${var.cluster_name}-kubeconfig-orig.tmp

      # Replace internal VIP with external FIP and add insecure-skip-tls-verify
      if [ -f /tmp/${var.cluster_name}-kubeconfig-orig.tmp ]; then
        sed -e 's/${var.control_plane_vip}/${local.control_plane_fip}/g' \
            -e 's/certificate-authority-data:.*/insecure-skip-tls-verify: true/' \
          /tmp/${var.cluster_name}-kubeconfig-orig.tmp \
          > /tmp/${var.cluster_name}-kubeconfig.tmp
        rm -f /tmp/${var.cluster_name}-kubeconfig-orig.tmp
      fi
    EOF
  }

  input = {
    cluster_name      = var.cluster_name
    bastion_ip        = local.bastion_vm_ip
    control_plane_fip = local.control_plane_fip
  }

  depends_on = [null_resource.nkp_create_cluster, nutanix_floating_ip_v2.control_plane_fip]
}

# Read the kubeconfig content (with FIP address)
data "local_file" "kubeconfig" {
  filename   = "/tmp/${var.cluster_name}-kubeconfig.tmp"
  depends_on = [terraform_data.kubeconfig]
}

# Update local kubeconfig with cluster context
resource "null_resource" "update_kubeconfig" {
  count = var.update_kubeconfig ? 1 : 0

  triggers = {
    kubeconfig_fetched = terraform_data.kubeconfig.id
  }

  provisioner "local-exec" {
    command = <<-EOF
      set -e
      KUBECONFIG_CONTENT='${try(data.local_file.kubeconfig.content, "")}'
      CLUSTER_NAME="${var.cluster_name}"
      KUBECONFIG_DIR="$HOME/.kube"
      KUBECONFIG_FILE="$KUBECONFIG_DIR/config"
      LOCK_FILE="$KUBECONFIG_DIR/.config.lock"
      TEMP_FILE="/tmp/$${CLUSTER_NAME}.conf"

      if [ -z "$KUBECONFIG_CONTENT" ]; then
        echo "Kubeconfig content not available for $CLUSTER_NAME"
        exit 0
      fi

      # Ensure .kube directory exists
      mkdir -p "$KUBECONFIG_DIR"

      # Write cluster kubeconfig to temp file
      echo "$KUBECONFIG_CONTENT" > "$TEMP_FILE"

      # Use flock for atomic merge (macOS compatible with perl fallback)
      (
        # Try flock, fall back to a simple lock file approach for macOS
        if command -v flock >/dev/null 2>&1; then
          flock -x 200
        else
          # Simple spinlock for macOS
          while ! mkdir "$LOCK_FILE" 2>/dev/null; do
            sleep 0.1
          done
          trap "rmdir '$LOCK_FILE' 2>/dev/null" EXIT
        fi

        # Merge kubeconfigs
        if [ -f "$KUBECONFIG_FILE" ]; then
          KUBECONFIG="$TEMP_FILE:$KUBECONFIG_FILE" kubectl config view --flatten > "$KUBECONFIG_FILE.new"
          mv "$KUBECONFIG_FILE.new" "$KUBECONFIG_FILE"
        else
          cp "$TEMP_FILE" "$KUBECONFIG_FILE"
        fi
        chmod 600 "$KUBECONFIG_FILE"

        # Get original context name and rename to cluster name
        ORIG_CONTEXT=$(kubectl config current-context --kubeconfig="$TEMP_FILE" 2>/dev/null || echo "")
        if [ -n "$ORIG_CONTEXT" ] && [ "$ORIG_CONTEXT" != "$CLUSTER_NAME" ]; then
          kubectl config rename-context "$ORIG_CONTEXT" "$CLUSTER_NAME" 2>/dev/null || true
        fi

      ) 200>"$KUBECONFIG_DIR/.config.flock"

      rm -f "$TEMP_FILE"
      echo "Kubeconfig updated. Context '$CLUSTER_NAME' added with FIP ${local.control_plane_fip}."
    EOF
  }

  depends_on = [terraform_data.kubeconfig, data.local_file.kubeconfig]
}

resource "null_resource" "install_kommander" {
  count = var.traefik_values != null && var.traefik_values != "" ? 1 : 0

  triggers = {
    bastion_vm_id  = nutanix_virtual_machine.bastion_vm.metadata.uuid
    traefik_values = var.traefik_values
  }

  connection {
    type     = "ssh"
    user     = var.bastion_vm_username
    password = var.bastion_vm_password
    host     = local.bastion_vm_ip
  }

  provisioner "remote-exec" {
    inline = [
      "cat <<EOF > kommander.yaml",
      "apiVersion: config.kommander.mesosphere.io/v1alpha1",
      "kind: Installation",
      "apps:",
      "  ai-navigator-app:",
      "    enabled: true",
      "  dex:",
      "    enabled: true",
      "  dex-k8s-authenticator:",
      "    enabled: true",
      "  external-secrets:",
      "    enabled: true",
      "  gatekeeper:",
      "    enabled: true",
      "  git-operator:",
      "    enabled: true",
      "  grafana-logging:",
      "    enabled: true",
      "  grafana-loki:",
      "    enabled: true",
      "  kommander:",
      "    enabled: true",
      "  kommander-ui:",
      "    enabled: true",
      "  kube-prometheus-stack:",
      "    enabled: true",
      "  kubefed:",
      "    enabled: true",
      "  kubernetes-dashboard:",
      "    enabled: true",
      "  kubetunnel:",
      "    enabled: true",
      "  logging-operator:",
      "    enabled: true",
      "  nkp-insights-management:",
      "    enabled: true",
      "  prometheus-adapter:",
      "    enabled: true",
      "  reloader:",
      "    enabled: true",
      "  rook-ceph:",
      "    enabled: true",
      "  rook-ceph-cluster:",
      "    enabled: true",
      "  traefik:",
      "    enabled: true",
      "    values: |",
      "$(echo '${var.traefik_values}' | sed 's/^/      /')",
      "  traefik-forward-auth-mgmt:",
      "    enabled: true",
      "  velero:",
      "    enabled: true",
      "ageEncryptionSecretName: sops-age",
      "clusterHostname: \"\"",
      "EOF",

      # Install/Update Kommander
      "echo 'Installing/Updating Kommander...'",
      "nkp install kommander --installer-config kommander.yaml --kubeconfig ~/${var.cluster_name}.conf --wait"
    ]
  }

  # Ensure cluster is created and kubeconfig is fetched before installing Kommander
  depends_on = [
    null_resource.nkp_create_cluster,
    null_resource.update_kubeconfig
  ]
}
