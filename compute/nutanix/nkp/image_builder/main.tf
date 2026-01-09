locals {
  image_filename = "nkp-${var.arch}.qcow2"
}

resource "terraform_data" "build_image" {
  triggers_replace = [
    var.arch,
    fileexists("${path.module}/packer/images/${local.image_filename}")
  ]

  provisioner "local-exec" {
    command = <<EOT
      cd ${path.module}/packer
      if [ ! -f images/${local.image_filename} ]; then
        make packer-build-${var.arch}
      fi
    EOT
  }
}

resource "nutanix_image" "nkp" {
  name        = "ubuntu_nkp_${var.arch}.qcow2"
  source_path = "${path.module}/packer/images/${local.image_filename}"
  description = "NKP Bastion Image"

  depends_on = [terraform_data.build_image]
}
