locals {
  image_filename = "traefik-hub-${var.arch}.qcow2"

  image_registry = (
    var.custom_image_registry != "" ? var.custom_image_registry :
    var.enable_preview_mode ? "europe-west9-docker.pkg.dev/traefiklabs" : "traefik"
  )

  image_repository = (
    var.custom_image_repository != "" ? var.custom_image_repository :
    var.enable_preview_mode ? "traefik-hub/traefik-hub" : "hub-agent"
  )

  image_tag = (
    var.enable_preview_mode ? var.hub_preview_tag : var.hub_version
  )
}

resource "terraform_data" "build_image" {
  count            = var.image_path == null ? 1 : 0
  triggers_replace = [var.arch, local.image_registry, local.image_repository, local.image_tag]

  provisioner "local-exec" {
    command = <<EOT
      cd ${path.module}/packer
      if [ ! -f images/${local.image_filename} ]; then
        make packer-build-${var.arch} HUB_DIR="${var.hub_dir != null ? var.hub_dir : ""}" HUB_REGISTRY="${local.image_registry}" HUB_REPOSITORY="${local.image_repository}" HUB_VERSION="${local.image_tag}"
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
