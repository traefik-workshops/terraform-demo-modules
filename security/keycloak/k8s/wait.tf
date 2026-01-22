# Validate Keycloak deployment readiness
resource "null_resource" "validate_keycloak_deployment" {
  provisioner "local-exec" {
    command = <<-EOT
      #!/bin/bash
      set -e
      
      echo "=== Validating Keycloak Deployment ==="
      
      # Configure isolated kubectl context
      if [ -n "${var.host}" ]; then
        KUBECONFIG_FILE=$(mktemp)
        CERT_FILE=$(mktemp)
        KEY_FILE=$(mktemp)
        
        echo "${var.client_certificate}" > "$CERT_FILE"
        echo "${var.client_key}" > "$KEY_FILE"
        
        export KUBECONFIG="$KUBECONFIG_FILE"
        kubectl config set-cluster remote --server="${var.host}" --insecure-skip-tls-verify=true >/dev/null
        kubectl config set-credentials admin --client-certificate="$CERT_FILE" --client-key="$KEY_FILE" >/dev/null
        kubectl config set-context remote --cluster=remote --user=admin >/dev/null
        kubectl config use-context remote >/dev/null
        
        # Ensure cleanup on exit
        trap 'rm -f "$KUBECONFIG_FILE" "$CERT_FILE" "$KEY_FILE"' EXIT
      fi
      
      # Wait for realm import job pod to complete
      echo "Checking realm import job pod..."
      TIMEOUT=300
      ELAPSED=0
      
      while [ $ELAPSED -lt $TIMEOUT ]; do
        REALM_POD=$(kubectl get pods -n ${var.namespace} \
          -l batch.kubernetes.io/job-name=traefik \
          -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
        
        if [ -n "$REALM_POD" ]; then
          REALM_STATUS=$(kubectl get pod -n ${var.namespace} $REALM_POD -o jsonpath='{.status.phase}')
          if [ "$REALM_STATUS" = "Succeeded" ]; then
            REALM_TIME=$(kubectl get pod -n ${var.namespace} $REALM_POD -o jsonpath='{.metadata.creationTimestamp}')
            REALM_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$REALM_TIME" +%s 2>/dev/null || date -d "$REALM_TIME" +%s)
            echo "✓ Realm import job completed at $REALM_TIME (epoch: $REALM_EPOCH)"
            break
          fi
          echo "Realm import job status: $REALM_STATUS, waiting... ($ELAPSED/$TIMEOUT)"
        else
          echo "Realm import job pod not found, waiting... ($ELAPSED/$TIMEOUT)"
        fi
        
        sleep 5
        ELAPSED=$((ELAPSED + 5))
      done
      
      if [ $ELAPSED -ge $TIMEOUT ]; then
        echo "ERROR: Timeout waiting for realm import job to complete"
        exit 1
      fi
      
      # Wait for Keycloak pod to restart and be newer than realm import
      echo ""
      echo "Waiting for Keycloak pod to restart after realm import..."
      TIMEOUT=600
      ELAPSED=0
      
      while [ $ELAPSED -lt $TIMEOUT ]; do
        KC_POD=$(kubectl get pods -n ${var.namespace} \
          -l app=keycloak,statefulset.kubernetes.io/pod-name=keycloak-0 \
          -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
        
        if [ -z "$KC_POD" ]; then
          echo "Keycloak pod not found, waiting... ($ELAPSED/$TIMEOUT)"
          sleep 5
          ELAPSED=$((ELAPSED + 5))
          continue
        fi
        
        KC_STATUS=$(kubectl get pod -n ${var.namespace} $KC_POD -o jsonpath='{.status.phase}')
        KC_READY=$(kubectl get pod -n ${var.namespace} $KC_POD -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
        KC_TIME=$(kubectl get pod -n ${var.namespace} $KC_POD -o jsonpath='{.metadata.creationTimestamp}')
        KC_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$KC_TIME" +%s 2>/dev/null || date -d "$KC_TIME" +%s)
        
        echo "Keycloak pod: $KC_POD | Status: $KC_STATUS | Ready: $KC_READY | Created: $KC_TIME (epoch: $KC_EPOCH)"
        
        # Pod exists but is older than realm import - waiting for restart
        if [ $KC_EPOCH -le $REALM_EPOCH ]; then
          echo "  → Pod is older than realm import, waiting for operator to restart it... ($ELAPSED/$TIMEOUT)"
          sleep 5
          ELAPSED=$((ELAPSED + 5))
          continue
        fi
        
        # Pod is restarting - wait for Running
        if [ "$KC_STATUS" != "Running" ]; then
          echo "  → Pod is restarting (status: $KC_STATUS), waiting... ($ELAPSED/$TIMEOUT)"
          sleep 5
          ELAPSED=$((ELAPSED + 5))
          continue
        fi
        
        # Pod is Running but not Ready yet
        if [ "$KC_READY" != "True" ]; then
          echo "  → Pod is Running but not Ready yet, waiting... ($ELAPSED/$TIMEOUT)"
          sleep 5
          ELAPSED=$((ELAPSED + 5))
          continue
        fi
        
        # Pod is Running, Ready, AND newer than realm import - SUCCESS
        AGE_DIFF=$((KC_EPOCH - REALM_EPOCH))
        echo "  → Pod is Running, Ready, and $AGE_DIFF seconds newer than realm import ✓"
        echo ""
        echo "✓ All validation checks passed!"
        exit 0
      done
      
      echo "ERROR: Timeout waiting for Keycloak pod to restart and become ready"
      exit 1
    EOT
  }
}
