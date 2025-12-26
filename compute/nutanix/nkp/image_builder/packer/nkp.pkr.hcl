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

source "qemu" "nkp" {
  qemu_binary       = local.qemu_binary[var.arch]
  machine_type      = local.machine_type[var.arch]
  cpu_model         = local.cpu_model[var.arch]
  accelerator       = local.accelerator[var.arch]
  headless          = true

  iso_url           = local.iso_url[var.arch]
  iso_checksum      = "file:https://cloud-images.ubuntu.com/releases/24.04/release/SHA256SUMS"
  output_directory  = "images"
  shutdown_command  = "sudo shutdown -P now"
  disk_size         = "20G"
  format            = "qcow2"
  ssh_username      = "traefiker"
  ssh_password      = "topsecretpassword"
  ssh_timeout       = "2m"
  vm_name           = "nkp-${var.arch}.qcow2"
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
  sources = ["source.qemu.nkp"]

  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "sudo apt-get update",
      "sudo apt-get install -y ca-certificates curl gnupg lsb-release",
      
      # Install Docker
      "sudo mkdir -m 0755 -p /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      "sudo usermod -aG docker traefiker", # Add build user to docker group
      "id -u ubuntu &>/dev/null && sudo usermod -aG docker ubuntu || echo 'User ubuntu not found, skipping docker group addition'",

      # Install Kubectl
      "curl -LO \"https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${var.arch}/kubectl\"",
      "sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl",
      "rm kubectl",

      # Install Helm
      "curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
    ]
  }

  # Copy NKP Binary
  provisioner "file" {
    source      = "bin/${var.arch}/nkp"
    destination = "/tmp/nkp"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /tmp/nkp /usr/local/bin/nkp",
      "sudo chmod +x /usr/local/bin/nkp"
    ]
  }

  post-processor "shell-local" {
    inline = [
      "echo 'Compressing image...'",
      "qemu-img convert -O qcow2 -c images/nkp-${var.arch}.qcow2 images/nkp-${var.arch}-compressed.qcow2",
      "mv images/nkp-${var.arch}-compressed.qcow2 images/nkp-${var.arch}.qcow2",
      "echo 'Compression complete.'"
    ]
  }
}
