locals {
  image_filename = "whoami-${var.arch}.qcow2"
}

resource "terraform_data" "build_image" {
  triggers_replace = [var.arch]

  provisioner "local-exec" {
    command = <<EOT
      cd ${path.module}/packer
      if [ ! -f images/${local.image_filename} ]; then
        make packer-build-${var.arch}
      fi
    EOT
  }
}

resource "nutanix_image" "whoami" {
  name        = "whoami_${var.arch}.qcow2"
  source_path = "${path.module}/packer/images/${local.image_filename}"
  description = "Traefik Whoami Pre-packaged Image"

  depends_on = [terraform_data.build_image]
}
