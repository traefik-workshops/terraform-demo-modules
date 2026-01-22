packer {
  required_plugins {
    qemu = {
      version = "~> 1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "arch" {
  type    = string
  default = "arm64"
}

locals {
  qemu_binary = {
    "arm64" = "qemu-system-aarch64"
    "amd64" = "qemu-system-x86_64"
  }
  machine_type = {
    "arm64" = "virt"
    "amd64" = "q35"
  }
  cpu_model = {
    "arm64" = "host"
    "amd64" = "qemu64"
  }
  accelerator = {
    "arm64" = "hvf"
    "amd64" = "tcg"
  }
  iso_url = {
    "arm64" = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-arm64.img"
    "amd64" = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img"
  }
  efi_boot = {
    "arm64" = true
    "amd64" = false
  }
}

source "qemu" "traefik-hub" {
  # Dynamic QEMU Settings
  qemu_binary       = local.qemu_binary[var.arch]
  machine_type      = local.machine_type[var.arch]
  cpu_model         = local.cpu_model[var.arch]
  accelerator       = local.accelerator[var.arch]
  headless          = true
  
  iso_url           = local.iso_url[var.arch]
  iso_checksum      = "file:https://cloud-images.ubuntu.com/releases/24.04/release/SHA256SUMS"
  output_directory  = "images"
  shutdown_command  = "sudo shutdown -P now"
  disk_size         = "10G"
  format            = "qcow2"
  ssh_username      = "traefiker"
  ssh_password      = "topsecretpassword"
  ssh_timeout       = "2m"
  vm_name           = "traefik-hub-${var.arch}.qcow2"
  net_device        = "virtio-net"
  disk_interface    = "virtio"
  disk_image        = true
  use_backing_file  = false
  
  # Cloud-Init via NoCloud (CD-ROM)
  cd_files = ["http/user-data", "http/meta-data"]
  cd_label = "cidata"

  # Boot Command to bypass Grub hang
  boot_wait = "5s"
  boot_command = [
    "<enter><wait>"
  ]
}

build {
  sources = ["source.qemu.traefik-hub"]

  # 1. Upload Binary
  provisioner "file" {
    source      = "bin/${var.arch}/traefik-hub"
    destination = "/tmp/traefik-hub"
  }

  provisioner "shell" {
    inline = [
      # Move binary
      "sudo mv /tmp/traefik-hub /usr/local/bin/traefik-hub",
      "sudo chown root:root /usr/local/bin/traefik-hub",
      "sudo chmod 755 /usr/local/bin/traefik-hub",
      
      # Capabilities (Bind port 80/443 as non-root)
      "sudo setcap 'cap_net_bind_service=+ep' /usr/local/bin/traefik-hub",

      # Create User
      "sudo groupadd --system traefik-hub",
      "sudo useradd -g traefik-hub --no-user-group --home-dir /var/www --no-create-home --shell /usr/sbin/nologin --system traefik-hub",

      # Create Config Dir
      "sudo mkdir -p /etc/traefik-hub/dynamic",
      "sudo chown root:root /etc/traefik-hub",
      "sudo chown traefik-hub:traefik-hub /etc/traefik-hub/dynamic",

      # Create Log File
      "sudo touch /var/log/traefik-hub.log",
      "sudo chown traefik-hub:traefik-hub /var/log/traefik-hub.log",
      
      # Create Service File
      "echo '[Unit]' | sudo tee /etc/systemd/system/traefik-hub.service",
      "echo 'Description=Traefik Hub Agent' | sudo tee -a /etc/systemd/system/traefik-hub.service",
      "echo 'After=network-online.target' | sudo tee -a /etc/systemd/system/traefik-hub.service",
      "echo 'Wants=network-online.target' | sudo tee -a /etc/systemd/system/traefik-hub.service",
      "echo '' | sudo tee -a /etc/systemd/system/traefik-hub.service",
      "echo '[Service]' | sudo tee -a /etc/systemd/system/traefik-hub.service",
      "echo 'Type=simple' | sudo tee -a /etc/systemd/system/traefik-hub.service",
      "echo 'User=traefik-hub' | sudo tee -a /etc/systemd/system/traefik-hub.service",
      "echo 'Group=traefik-hub' | sudo tee -a /etc/systemd/system/traefik-hub.service",
      "echo 'ExecStart=/usr/local/bin/traefik-hub --configfile=/etc/traefik-hub/traefik-hub.yaml' | sudo tee -a /etc/systemd/system/traefik-hub.service",
      "echo 'Restart=on-failure' | sudo tee -a /etc/systemd/system/traefik-hub.service",
      "echo 'AmbientCapabilities=CAP_NET_BIND_SERVICE' | sudo tee -a /etc/systemd/system/traefik-hub.service",
      "echo '' | sudo tee -a /etc/systemd/system/traefik-hub.service",
      "echo '[Install]' | sudo tee -a /etc/systemd/system/traefik-hub.service",
      "echo 'WantedBy=multi-user.target' | sudo tee -a /etc/systemd/system/traefik-hub.service",

      # Finalize
      "sudo systemctl daemon-reload",
      "sudo systemctl enable traefik-hub.service"
    ]
  }

  post-processor "shell-local" {
    inline = [
      "echo 'Compressing image...'",
      "qemu-img convert -O qcow2 -c images/traefik-hub-${var.arch}.qcow2 images/traefik-hub-${var.arch}-compressed.qcow2",
      "mv images/traefik-hub-${var.arch}-compressed.qcow2 images/traefik-hub-${var.arch}.qcow2",
      "echo 'Compression complete.'"
    ]
  }
}
