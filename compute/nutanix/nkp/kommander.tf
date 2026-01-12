locals {
  kommander_yaml_content = <<-EOF
    apiVersion: config.kommander.mesosphere.io/v1alpha1
    kind: Installation
    apps:
      ai-navigator-app:
        enabled: true
      dex:
        enabled: true
      dex-k8s-authenticator:
        enabled: true
      external-secrets:
        enabled: true
      gatekeeper:
        enabled: true
      git-operator:
        enabled: true
      grafana-logging:
        enabled: false
      grafana-loki:
        enabled: false
      kommander:
        enabled: true
      kommander-ui:
        enabled: true
      kube-prometheus-stack:
        enabled: false
      kubefed:
        enabled: true
      kubernetes-dashboard:
        enabled: true
      kubetunnel:
        enabled: true
      logging-operator:
        enabled: false
      nkp-insights-management:
        enabled: false
      prometheus-adapter:
        enabled: false
      reloader:
        enabled: true
      rook-ceph:
        enabled: false
      rook-ceph-cluster:
        enabled: false
      traefik:
        enabled: true
        values: |
${indent(10, var.traefik_values)}
      traefik-forward-auth-mgmt:
        enabled: true
      velero:
        enabled: false
    ageEncryptionSecretName: sops-age
    clusterHostname: ""
  EOF
}

resource "null_resource" "upload_kommander_config" {
  count = var.traefik_values != null && var.traefik_values != "" ? 1 : 0

  triggers = {
    bastion_vm_id = nutanix_virtual_machine.bastion_vm.metadata.uuid
    content_sha   = sha256(local.kommander_yaml_content)
  }

  connection {
    type     = "ssh"
    user     = var.bastion_vm_username
    password = var.bastion_vm_password
    host     = local.bastion_vm_ip
  }

  provisioner "file" {
    content     = local.kommander_yaml_content
    destination = "kommander.yaml"
  }
}

resource "null_resource" "install_kommander" {
  count = var.traefik_values != null && var.traefik_values != "" ? 1 : 0

  triggers = {
    bastion_vm_id = nutanix_virtual_machine.bastion_vm.metadata.uuid
    run_always    = timestamp()
  }

  connection {
    type     = "ssh"
    user     = var.bastion_vm_username
    password = nonsensitive(var.bastion_vm_password)
    host     = local.bastion_vm_ip
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Installing/Updating Kommander...'",
      "nkp install kommander --installer-config kommander.yaml --kubeconfig ~/${var.cluster_name}.conf --wait"
    ]
  }

  depends_on = [
    null_resource.upload_kommander_config,
    null_resource.nkp_create_cluster,
    null_resource.update_kubeconfig
    # null_resource.oci_patcher
  ]
}
