output "pods" {
  description = "Map of created pods with their details"
  
  # Return only the state file content if it exists, otherwise use the external data
  value = fileexists("${path.module}/terraform.tfstate.pods") ? (
    jsondecode(file("${path.module}/terraform.tfstate.pods"))
  ) : (
    { for k, v in data.external.pods : k => v.result }
  )
}
