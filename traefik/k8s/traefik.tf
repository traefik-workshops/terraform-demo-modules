# =============================================================================
# K8s Traefik Deployment
# =============================================================================
# Uses module.config.helm_values as base configuration, merged with K8s-specific
# overrides (redis, knative, gateway, providers, RBAC).
# =============================================================================

locals {
  # K8s-specific CLI arguments (in addition to shared module args)
  k8s_arguments = concat(
    var.nginx_provider_enabled ? [
      "--configFile=/traefik-nginx-config/nginx.yaml"
    ] : []
  )

  # Combine shared arguments with K8s-specific ones
  additional_arguments = concat(module.config.cli_arguments, local.k8s_arguments)

  # K8s-specific volumes for file provider
  deployment_volumes = concat(
    var.file_provider_config != "" ? [{
      name      = "traefik-dynamic-config"
      configMap = { name = "traefik-dynamic-config" }
    }] : [],
    var.nginx_provider_enabled ? [{
      name      = "traefik-nginx-config"
      configMap = { name = "traefik-nginx-config" }
    }] : []
  )

  volume_mounts = concat(
    var.file_provider_config != "" ? [{
      name      = "traefik-dynamic-config"
      mountPath = "/etc/traefik"
    }] : [],
    var.nginx_provider_enabled ? [{
      name      = "traefik-nginx-config"
      mountPath = "/traefik-nginx-config"
    }] : []
  )

  # K8s-specific overrides to merge with shared helm_values
  k8s_overrides = {
    # Hub - extend with K8s-specific redis config for API Management
    hub = var.enable_api_gateway || var.enable_api_management ? merge(
      try(module.config.helm_values.hub, {}),
      merge(
        { token = "traefik-hub-license" },
        var.enable_api_management ? {
          apimanagement = { enabled = true }
        } : {}
      ),
      var.enable_api_management ? {
        redis = {
          endpoints = "traefik-redis.${var.namespace}.svc:6379"
          password  = var.redis_password
          database  = "0"
          sentinel  = { enabled = false }
          cluster   = false
        }
      } : {}
    ) : null

    # Deployment configuration
    deployment = {
      kind              = var.deploymentType
      replicas          = module.config.replica_count
      additionalVolumes = local.deployment_volumes
    }

    # Service configuration
    service = {
      kind = var.serviceType
    }

    # Environment variables - add USER env
    env = concat(
      [{ name = "USER", value = "traefiker" }],
      module.config.env_vars_list
    )

    # K8s providers (not in shared)
    providers = merge({
      kubernetesCRD = merge({
        allowCrossNamespace       = true
        allowExternalNameServices = true
        }, length(var.kubernetes_namespaces) > 0 ? {
        namespaces = var.kubernetes_namespaces
      } : {})
      kubernetesIngress = merge({
        allowExternalNameServices = true
        }, length(var.kubernetes_namespaces) > 0 ? {
        namespaces = var.kubernetes_namespaces
      } : {})
      kubernetesGateway = merge({
        enabled             = false
        experimentalChannel = false
        }, length(var.kubernetes_namespaces) > 0 ? {
        namespaces = var.kubernetes_namespaces
      } : {})
      }, var.enable_knative_provider ? {
      knative = {
        enabled = true
      }
    } : {}, var.custom_providers)

    experimental = {
      kubernetesGateway = { enabled = false }
      knative           = var.enable_knative_provider
    }

    # Gateway API listeners (K8s-specific)
    gateway = {
      listeners = {
        web = {
          port            = 80
          protocol        = "HTTP"
          namespacePolicy = { from = "All" }
        }
        traefik = {
          port            = 8080
          protocol        = "HTTP"
          namespacePolicy = { from = "All" }
        }
      }
    }

    # IngressRoute for dashboard (K8s-specific)
    ingressRoute = {
      dashboard = {
        enabled     = true
        matchRule   = var.dashboard_match_rule
        entryPoints = var.dashboard_entrypoints
      }
    }

    # Pod security (K8s-specific)
    podSecurityContext = {
      fsGroup             = 65532
      fsGroupChangePolicy = "OnRootMismatch"
    }

    # Resources and tolerations (K8s-specific)
    resources   = var.resources
    tolerations = var.tolerations

    # Additional arguments and volumes (K8s-specific)
    additionalArguments    = local.additional_arguments
    additionalVolumeMounts = local.volume_mounts
    extra_objects          = var.custom_objects
  }
}

# K8s Secrets
resource "kubernetes_secret_v1" "traefik-hub-license" {
  count = var.enable_api_gateway || var.enable_api_management ? 1 : 0

  metadata {
    name      = "traefik-hub-license"
    namespace = var.namespace
  }

  type = "Opaque"
  data = {
    token = var.traefik_hub_token
  }
}

# File provider ConfigMap
resource "kubernetes_config_map_v1" "traefik-dynamic-config" {
  count = var.file_provider_config != "" ? 1 : 0

  metadata {
    name      = "traefik-dynamic-config"
    namespace = var.namespace
  }

  data = {
    "dynamic.yaml" = var.file_provider_config
  }
}

# NGINX provider ConfigMap
resource "kubernetes_config_map_v1" "traefik-nginx-config" {
  count = var.nginx_provider_enabled ? 1 : 0

  metadata {
    name      = "traefik-nginx-config"
    namespace = var.namespace
  }

  data = {
    "nginx.yaml" = yamlencode({
      global = {
        checkNewVersion    = true
        sendAnonymousUsage = true
      }
      entryPoints = {
        web       = { address = ":80" }
        websecure = { address = ":443" }
      }
      providers = {
        kubernetesIngressNginx = { enabled = true }
      }
    })
  }
}

# Helm release - merge shared helm_values with K8s overrides
resource "helm_release" "traefik" {
  name             = var.name
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  version          = var.traefik_chart_version
  namespace        = var.namespace
  create_namespace = true
  atomic           = true
  wait             = true

  values = [
    # Base values from shared module
    yamlencode(module.config.helm_values),
    # K8s-specific overrides
    yamlencode(local.k8s_overrides),
    # User-provided extra values
    yamlencode(var.extra_values)
  ]

  depends_on = [
    kubernetes_secret_v1.traefik-hub-license,
    kubernetes_config_map_v1.traefik-dynamic-config,
    kubernetes_config_map_v1.traefik-nginx-config,
    helm_release.traefik-crds
  ]
}

# Redis for API Management
module "redis" {
  source = "../../tools/redis/k8s"
  count  = var.enable_api_management ? 1 : 0

  name         = "traefik-redis"
  namespace    = var.namespace
  password     = var.redis_password
  replicaCount = 1
}
