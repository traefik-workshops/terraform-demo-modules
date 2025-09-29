resource "null_resource" "pods" {
  for_each = local.nims

  triggers = {
    always_run       = "${timestamp()}"
    name             = each.value.name
    image            = each.value.image
    tag              = each.value.tag
    runpod_api_key   = var.runpod_api_key
    ngc_token        = var.ngc_token
    pod_type         = var.pod_type
  }

  provisioner "local-exec" {
    command = <<-EOT
      bash ${path.module}/scripts/manage_pod.sh \
        --name "${self.triggers.name}" \
        --image "${self.triggers.image}" \
        --tag "${self.triggers.tag}" \
        --runpod-api-key "${self.triggers.runpod_api_key}" \
        --ngc-token "${self.triggers.ngc_token}" \
        --pod-type "${self.triggers.pod_type}" \
        --registry-auth-id "${data.external.registry_auth.result.id}" \
        --output-file "${path.module}/terraform.tfstate.pods"
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      runpodctl remove pods ${self.triggers.name} || true
      rm ${path.module}/terraform.tfstate.pods || true
    EOT
  }

  depends_on = [data.external.registry_auth]
}

output "pods" {
  value       = fileexists("${path.module}/terraform.tfstate.pods") ? jsondecode(file("${path.module}/terraform.tfstate.pods")) : {}
  description = "Information about the created pods"

  depends_on = [ null_resource.pods ]
}
