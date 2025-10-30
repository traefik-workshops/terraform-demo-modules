# Wait for realm import job to complete
resource "null_resource" "wait_for_realm_import" {
  provisioner "local-exec" {
    command = <<-EOT
      #!/bin/bash
      set -e
      
      echo "Waiting for Keycloak operator to create realm import job..."
      
      # Wait for job to be created (up to 5 minutes)
      TIMEOUT=300
      ELAPSED=0
      while [ $ELAPSED -lt $TIMEOUT ]; do
        JOB_COUNT=$(kubectl get jobs -n ${var.namespace} \
          -l app=keycloak-realm-import,job-name=traefik \
          --no-headers 2>/dev/null | wc -l)
        
        if [ "$JOB_COUNT" -gt 0 ]; then
          echo "✓ Realm import job found"
          break
        fi
        
        echo "Waiting for job to be created... ($ELAPSED/$TIMEOUT seconds)"
        sleep 5
        ELAPSED=$((ELAPSED + 5))
      done
      
      if [ $ELAPSED -ge $TIMEOUT ]; then
        echo "ERROR: Timeout waiting for realm import job to be created"
        exit 1
      fi
      
      # Now wait for the job to complete
      echo "Waiting for realm import job to complete..."
      kubectl wait --for=condition=complete \
        --timeout=300s \
        -n ${var.namespace} \
        job -l app=keycloak-realm-import,job-name=traefik || exit 1
      
      echo "✓ Realm import job completed successfully"
    EOT
  }

  depends_on = [kubectl_manifest.keycloak_crd]
}

# Validate Keycloak deployment readiness
resource "null_resource" "validate_keycloak_deployment" {
  provisioner "local-exec" {
    command = <<-EOT
      #!/bin/bash
      set -e
      
      echo "Validating Keycloak deployment..."
      
      # Check if realm import job pod exists and is completed
      REALM_IMPORT_POD=$(kubectl get pods -n ${var.namespace} \
        -l app=keycloak-realm-import,batch.kubernetes.io/job-name=traefik \
        -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
      
      if [ -z "$REALM_IMPORT_POD" ]; then
        echo "ERROR: Realm import job pod not found"
        exit 1
      fi
      
      REALM_IMPORT_STATUS=$(kubectl get pod -n ${var.namespace} $REALM_IMPORT_POD \
        -o jsonpath='{.status.phase}')
      
      if [ "$REALM_IMPORT_STATUS" != "Succeeded" ]; then
        echo "ERROR: Realm import job pod status is $REALM_IMPORT_STATUS, expected Succeeded"
        exit 1
      fi
      
      REALM_IMPORT_TIME=$(kubectl get pod -n ${var.namespace} $REALM_IMPORT_POD \
        -o jsonpath='{.metadata.creationTimestamp}')
      
      echo "✓ Realm import job completed: $REALM_IMPORT_POD (created at $REALM_IMPORT_TIME)"
      
      # Check if Keycloak pod exists and is running
      KEYCLOAK_POD=$(kubectl get pods -n ${var.namespace} \
        -l app=keycloak,statefulset.kubernetes.io/pod-name=keycloak-0 \
        -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
      
      if [ -z "$KEYCLOAK_POD" ]; then
        echo "ERROR: Keycloak pod not found"
        exit 1
      fi
      
      KEYCLOAK_STATUS=$(kubectl get pod -n ${var.namespace} $KEYCLOAK_POD \
        -o jsonpath='{.status.phase}')
      
      if [ "$KEYCLOAK_STATUS" != "Running" ]; then
        echo "ERROR: Keycloak pod status is $KEYCLOAK_STATUS, expected Running"
        exit 1
      fi
      
      KEYCLOAK_TIME=$(kubectl get pod -n ${var.namespace} $KEYCLOAK_POD \
        -o jsonpath='{.metadata.creationTimestamp}')
      
      echo "✓ Keycloak pod running: $KEYCLOAK_POD (created at $KEYCLOAK_TIME)"
      
      # Validate that Keycloak pod is newer than realm import pod
      REALM_IMPORT_EPOCH=$(date -u -d "$REALM_IMPORT_TIME" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$REALM_IMPORT_TIME" +%s)
      KEYCLOAK_EPOCH=$(date -u -d "$KEYCLOAK_TIME" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$KEYCLOAK_TIME" +%s)
      
      if [ $KEYCLOAK_EPOCH -le $REALM_IMPORT_EPOCH ]; then
        echo "ERROR: Keycloak pod ($KEYCLOAK_TIME) is not newer than realm import pod ($REALM_IMPORT_TIME)"
        exit 1
      fi
      
      AGE_DIFF=$((KEYCLOAK_EPOCH - REALM_IMPORT_EPOCH))
      echo "✓ Keycloak pod is $AGE_DIFF seconds newer than realm import pod"
      
      echo "✓ All validation checks passed!"
    EOT
  }

  depends_on = [null_resource.wait_for_realm_import]
}
