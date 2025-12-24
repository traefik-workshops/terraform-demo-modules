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
    "arm64" = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-arm64.img"
    "amd64" = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
  }
  efi_boot = {
    "arm64" = true
    "amd64" = false
  }
}

source "qemu" "whoami" {
  qemu_binary       = local.qemu_binary[var.arch]
  machine_type      = local.machine_type[var.arch]
  cpu_model         = local.cpu_model[var.arch]
  accelerator       = local.accelerator[var.arch]
  headless          = true

  iso_url           = local.iso_url[var.arch]
  iso_checksum      = "file:https://cloud-images.ubuntu.com/releases/22.04/release/SHA256SUMS"
  output_directory  = "images"
  shutdown_command  = "sudo shutdown -P now"
  disk_size         = "10G"
  format            = "qcow2"
  ssh_username      = "traefiker"
  ssh_password      = "topsecretpassword"
  ssh_timeout       = "2m"
  vm_name           = "whoami-${var.arch}.qcow2"
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
  sources = ["source.qemu.whoami"]

  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "sudo apt-get update",
      "sudo apt-get install -y ca-certificates curl"
    ]
  }

  provisioner "file" {
    source      = "bin/${var.arch}/whoami"
    destination = "/tmp/whoami"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /tmp/whoami /usr/local/bin/whoami",
      "sudo chmod +x /usr/local/bin/whoami",
      
      # Capabilities (Bind port 80 as non-root)
      "sudo setcap 'cap_net_bind_service=+ep' /usr/local/bin/whoami",
      
      # Create Systemd Service
      "echo '[Unit]' | sudo tee /etc/systemd/system/whoami.service",
      "echo 'Description=Traefik Whoami Service' | sudo tee -a /etc/systemd/system/whoami.service",
      "echo 'After=network.target' | sudo tee -a /etc/systemd/system/whoami.service",
      "echo '' | sudo tee -a /etc/systemd/system/whoami.service",
      "echo '[Service]' | sudo tee -a /etc/systemd/system/whoami.service",
      "echo 'ExecStart=/usr/local/bin/whoami --port 80' | sudo tee -a /etc/systemd/system/whoami.service",
      "echo 'Restart=always' | sudo tee -a /etc/systemd/system/whoami.service",
      "echo 'User=nobody' | sudo tee -a /etc/systemd/system/whoami.service",
      "echo '' | sudo tee -a /etc/systemd/system/whoami.service",
      "echo '[Install]' | sudo tee -a /etc/systemd/system/whoami.service",
      "echo 'WantedBy=multi-user.target' | sudo tee -a /etc/systemd/system/whoami.service",
      
      "sudo systemctl enable whoami.service"
    ]
  }

  post-processor "shell-local" {
    inline = [
      "echo 'Compressing image...'",
      "qemu-img convert -O qcow2 -c images/whoami-${var.arch}.qcow2 images/whoami-${var.arch}-compressed.qcow2",
      "mv images/whoami-${var.arch}-compressed.qcow2 images/whoami-${var.arch}.qcow2",
      "echo 'Compression complete.'"
    ]
  }
}
