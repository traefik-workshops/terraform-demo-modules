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
    enabled: true
  grafana-loki:
    enabled: true
  kommander:
    enabled: true
  kommander-ui:
    enabled: true
  kube-prometheus-stack:
    enabled: true
  kubefed:
    enabled: true
  kubernetes-dashboard:
    enabled: true
  kubetunnel:
    enabled: true
  logging-operator:
    enabled: true
  nkp-insights-management:
    enabled: true
  prometheus-adapter:
    enabled: true
  reloader:
    enabled: true
  rook-ceph:
    enabled: true
  rook-ceph-cluster:
    enabled: true
  traefik:
    enabled: true
    values: |
      ${replace(traefik_values, "\n", "\n      ")}
  traefik-forward-auth-mgmt:
    enabled: true
  velero:
    enabled: true
ageEncryptionSecretName: sops-age
clusterHostname: "${control_plane_fip}"
