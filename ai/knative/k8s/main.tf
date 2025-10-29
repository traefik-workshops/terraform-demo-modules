resource "helm_release" "knative_operator" {
  name       = var.name
  namespace  = var.namespace
  repository = "https://knative.github.io/operator"
  chart      = "knative-operator"
  version    = "v1.19.0"
  timeout    = 900
  atomic     = true
}

resource "kubernetes_namespace" "knative_serving" {
  metadata {
    name = "knative-serving"
  }
}

resource "kubectl_manifest" "knative_serving" {
  depends_on = [kubernetes_namespace.knative_serving, helm_release.knative_operator]

  yaml_body = <<YAML
apiVersion: operator.knative.dev/v1beta1
kind: KnativeServing
metadata:
  name: knative-serving
  namespace: knative-serving
spec:
  config:
    network:
      ingress-class: "traefik.ingress.networking.knative.dev"
YAML
}