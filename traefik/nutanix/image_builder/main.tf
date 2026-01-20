locals {
  image_filename = "traefik-hub-${var.arch}.qcow2"
}

resource "terraform_data" "build_image" {
  count            = var.image_path == null ? 1 : 0
  triggers_replace = [var.arch]

  provisioner "local-exec" {
    command = <<EOT
      cd ${path.module}/packer
      if [ ! -f images/${local.image_filename} ]; then
        make packer-build-${var.arch} HUB_DIR="${var.hub_dir != null ? var.hub_dir : ""}" HUB_VERSION="${var.hub_version}"
      fi
    EOT
  }
}

resource "nutanix_image" "traefik_hub" {
  name        = "traefik-hub_${var.arch}.qcow2"
  source_path = var.image_path != null ? var.image_path : "${path.module}/packer/images/${local.image_filename}"
  description = "Traefik Hub Pre-packaged Image"

  depends_on = [terraform_data.build_image]
}
