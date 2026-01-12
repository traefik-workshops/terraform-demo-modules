
# resource "null_resource" "upload_oci_patcher_manifest" {
#   triggers = {
#     bastion_vm_id = nutanix_virtual_machine.bastion_vm.metadata.uuid
#     manifest_sha  = filesha256("${path.module}/oci-patcher-go/manifest.yaml")
#   }

#   connection {
#     type     = "ssh"
#     user     = var.bastion_vm_username
#     password = var.bastion_vm_password
#     host     = local.bastion_vm_ip
#   }

#   provisioner "file" {
#     source      = "${path.module}/oci-patcher-go/manifest.yaml"
#     destination = "oci-patcher-go-manifest.yaml"
#   }
# }

# resource "null_resource" "oci_patcher" {
#   triggers = {
#     bastion_vm_id = nutanix_virtual_machine.bastion_vm.metadata.uuid
#     run_always    = timestamp()
#   }

#   connection {
#     type     = "ssh"
#     user     = var.bastion_vm_username
#     password = var.bastion_vm_password
#     host     = local.bastion_vm_ip
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "echo 'Ensuring kubeconfig is available...'",
#       "for i in {1..50}; do if [ -f ~/${var.cluster_name}.conf ]; then break; fi; nkp get kubeconfig --cluster-name ${var.cluster_name} > ~/${var.cluster_name}.conf 2>/dev/null && break; echo \"Waiting for cluster ${var.cluster_name} to be ready for kubeconfig... (attempt $i/50)\"; sleep 10; done",
#       "export KUBECONFIG=~/${var.cluster_name}.conf",
#       "echo 'Applying Go-based OCI Patcher Operator manifests...'",
#       "kubectl apply -f oci-patcher-go-manifest.yaml",
#       "echo 'Restarting OCI Patcher to ensure latest image...'",
#       "kubectl rollout restart deployment oci-patcher -n oci-patcher || true",
#       "echo 'OCI Patcher Go Operator deployed successfully.'"
#     ]
#   }

#   depends_on = [
#     null_resource.upload_oci_patcher_manifest,
#     null_resource.update_kubeconfig
#   ]
# }
