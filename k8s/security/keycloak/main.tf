# PostgreSQL for Keycloak
module "keycloak_postgres" {
  source = "../../tools/postgresql"

  name      = "keycloak-postgres"
  namespace = var.namespace
  database  = "keycloak-db"
  password  = "topsecretpassword"
}

resource "kubernetes_secret" "keycloak_db_secret" {
  metadata {
    name = "keycloak-db-secret"
    namespace = var.namespace
    labels = {
      "operator.keycloak.org/component" = "watched-secret"
    }
  }

  type = "Opaque"
  data = {
    username = "postgres"
    password = "topsecretpassword"
  }
}

resource "kubernetes_secret" "keycloak_secret" {
  metadata {
    name = "keycloak-secret"
    namespace = var.namespace
  }

  type = "kubernetes.io/basic-auth"
  data = {
    username = "traefik"
    password = "topsecretpassword"
  }
}

# Keycloak Operator and CRDs
resource "kubectl_manifest" "keycloak_operator_deployment" {
  override_namespace = var.namespace
  wait = true
  yaml_body = file("${path.module}/kubernetes/keycloak-operator-deployment.yml")
}

resource "kubectl_manifest" "keycloak_operator_role_binding" {
  override_namespace = var.namespace
  wait = true
  yaml_body = file("${path.module}/kubernetes/keycloak-operator-role-binding.yml")
}

resource "kubectl_manifest" "keycloak_operator_role" {
  override_namespace = var.namespace
  wait = true
  yaml_body = file("${path.module}/kubernetes/keycloak-operator-role.yml")
}

resource "kubectl_manifest" "keycloak_operator_service_account" {
  override_namespace = var.namespace
  wait = true
  yaml_body = file("${path.module}/kubernetes/keycloak-operator-service-account.yml")
}

resource "kubectl_manifest" "keycloak_operator_service" {
  override_namespace = var.namespace
  wait = true
  yaml_body = file("${path.module}/kubernetes/keycloak-operator-service.yml")
}

resource "kubectl_manifest" "keycloak_operator_view_role_binding" {
  override_namespace = var.namespace
  wait = true
  yaml_body = file("${path.module}/kubernetes/keycloak-operator-view-role-binding.yml")
}

resource "kubectl_manifest" "keycloakcontroller_cluster_role" {
  override_namespace = var.namespace
  wait = true
  yaml_body = file("${path.module}/kubernetes/keycloakcontroller-cluster-role.yml")
}

resource "kubectl_manifest" "keycloakcontroller_role_binding" {
  override_namespace = var.namespace
  wait = true
  yaml_body = file("${path.module}/kubernetes/keycloakcontroller-role-binding.yml")
}

resource "kubectl_manifest" "keycloakrealmimportcontroller_cluster_role" {
  override_namespace = var.namespace
  wait = true
  yaml_body = file("${path.module}/kubernetes/keycloakrealmimportcontroller-cluster-role.yml")
}

resource "kubectl_manifest" "keycloakrealmimportcontroller_role_binding" {
  override_namespace = var.namespace
  wait = true
  yaml_body = file("${path.module}/kubernetes/keycloakrealmimportcontroller-role-binding.yml")
}

# Keycloak CRDs
resource "kubectl_manifest" "keycloak_crds" {
  override_namespace = var.namespace
  wait = true
  yaml_body = file("${path.module}/kubernetes/keycloaks.k8s.keycloak.org-v1.yml")
}

# Keycloak Realm Import CRDs
resource "kubectl_manifest" "keycloak_realm_import_crds" {
  override_namespace = var.namespace
  wait = true
  yaml_body = file("${path.module}/kubernetes/keycloakrealmimports.k8s.keycloak.org-v1.yml")
}

resource "kubectl_manifest" "keycloak_crd" {
  depends_on = [module.keycloak_postgres, kubernetes_secret.keycloak_db_secret, kubernetes_secret.keycloak_secret, kubectl_manifest.keycloak_crds, kubectl_manifest.keycloak_realm_import_crds]

  wait = true

  yaml_body = <<YAML
apiVersion: k8s.keycloak.org/v2alpha1
kind: Keycloak
metadata:
  name: keycloak
  namespace: ${var.namespace}
spec:
  instances: 1
  bootstrapAdmin:
    user:
      secret: keycloak-secret
  db:
    vendor: postgres
    host: keycloak-postgres
    port: 5432
    database: keycloak-db
    usernameSecret:
      name: keycloak-db-secret
      key: username
    passwordSecret:
      name: keycloak-db-secret
      key: password
  http:
    httpEnabled: true
  hostname:
    strict: false
  proxy:
    headers: xforwarded
  ingress:
    enabled: false
YAML
}

resource "kubernetes_ingress_v1" "keycloak-traefik" {
  metadata {
    name = "keycloak"
    namespace = var.namespace
    annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints" = var.ingress_entrypoint
      "traefik.ingress.kubernetes.io/router.observability.accesslogs" = "false"
      "traefik.ingress.kubernetes.io/router.observability.metrics" = "false"
      "traefik.ingress.kubernetes.io/router.observability.tracing" = "false"
    }
  }

  spec {
    rule {
      host = "keycloak-traefik.${var.ingress_domain}"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "keycloak-service"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
    rule {
      host = "keycloak.traefik.localhost"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "keycloak-service"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
    rule {
      host = "keycloak-service.${var.namespace}.svc"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "keycloak-service"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }

  count = var.ingress == true ? 1 : 0
  depends_on = [kubectl_manifest.keycloak_crd]
}

resource "kubernetes_ingress_v1" "keycloak-internal-traefik" {
  metadata {
    name = "keycloak-internal"
    namespace = var.namespace
    annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints" = "traefik"
      "traefik.ingress.kubernetes.io/router.observability.accesslogs" = "false"
      "traefik.ingress.kubernetes.io/router.observability.metrics" = "false"
      "traefik.ingress.kubernetes.io/router.observability.tracing" = "false"
    }
  }

  spec {
    rule {
      host = "keycloak.traefik.localhost"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "keycloak-service"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
    rule {
      host = "keycloak-service.${var.namespace}.svc"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "keycloak-service"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }

  count = var.ingress == true && var.ingress_internal == true ? 1 : 0
  depends_on = [kubectl_manifest.keycloak_crd]
}
