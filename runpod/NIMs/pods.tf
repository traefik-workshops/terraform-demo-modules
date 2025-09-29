data "external" "pods" {
  for_each = local.nims
  
  program = ["bash", "${path.module}/scripts/manage_pod.sh"]

  query = {
    action           = "create"
    name             = each.value.name
    image            = each.value.image
    tag              = each.value.tag
    runpod_api_key   = var.runpod_api_key
    ngc_token        = var.ngc_token
    pod_type         = var.pod_type
    registry_auth_id = data.external.registry_auth.result.id
    output_file      = "${path.module}/terraform.tfstate.pods"
  }
}

# Clean up pods when destroyed
resource "null_resource" "pods_cleanup" {
  for_each = local.nims
  
  triggers = {
    name           = each.value.name
    runpod_api_key = var.runpod_api_key
    output_file    = "${path.module}/terraform.tfstate.pods"
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      runpodctl remove pods ${self.triggers.name} || true
      rm -f ${self.triggers.output_file} || true
    EOT
  }

  depends_on = [data.external.pods]
}

output "pods" {
  description = "Map of created pods with their details"
  
  # Return only the state file content if it exists, otherwise use the external data
  value = fileexists("${path.module}/terraform.tfstate.pods") ? (
    jsondecode(file("${path.module}/terraform.tfstate.pods"))
  ) : (
    { for k, v in data.external.pods : k => v.result }
  )
}
