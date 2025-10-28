data "kustomization_overlay" "chats" {
  resources = [
    "github.com/traefik-workshops/traefik-demo-resources//chats/base/common?ref=${var.git_ref}"
  ]
  
  components = [
    for component in var.components : 
      "github.com/traefik-workshops/traefik-demo-resources//chats/components/${component}?ref=${var.git_ref}"
  ]
  
  config_map_generator {
    name = "env-config"
    
    literals = [
      "KEYCLOAK_JWKS_URL=https://keycloak.traefik.${var.domain}/realms/traefik/protocol/openid-connect/certs",
      "KEYCLOAK_ISSUER_URL=https://keycloak.traefik.${var.domain}/realms/traefik",
      "OIDC_CLIENT_ID=${var.oidc_client_id}",
      "OIDC_CLIENT_SECRET=${var.oidc_client_secret}",
      "KEYCLOAK_ADMIN_ID=${var.keycloak_admin_id}",
      "KEYCLOAK_DEVELOPER_ID=${var.keycloak_developer_id}",
      "KEYCLOAK_AGENT_ID=${var.keycloak_agent_id}",
      "NIM_TC_ENDPOINT=https://${var.nim_tc_pod_id}-8000.proxy.runpod.net/v1/chat/completions",
      "NIM_CS_ENDPOINT=https://${var.nim_cs_pod_id}-8000.proxy.runpod.net/v1/chat/completions",
      "NIM_JB_ENDPOINT=https://${var.nim_jb_pod_id}-8000.proxy.runpod.net/v1/classify",
      "PORTAL_URL=https://chats.portal.${var.domain}",
      "PORTAL_HOST_MATCH=Host(`chats.portal.${var.domain}`)",
      "PRESIDIO_HOST=${var.presidio_host}",
      "OLLAMA_BASE_URL=${var.ollama_base_url}",
      "MILVUS_ADDRESS=${var.milvus_address}",
      "OPENAI_API_URL=https://openai.${var.domain}",
      "OPENAI_HOST_MATCH=Host(`openai.${var.domain}`)",
      "OPENAI_HOST_MATCH_COMPLETIONS=Host(`openai.${var.domain}`) && PathPrefix(`/v1/chat/completions`)",
      "OPENAI_AUTH_HEADER=${var.openai_auth_header}",
      "GPT_OSS_EXTERNAL_NAME=${var.gpt_oss_pod_id}-8000.proxy.runpod.net",
      "GPT_OSS_API_URL=https://gpt.${var.domain}",
      "GPT_OSS_HOST_MATCH=Host(`gpt.${var.domain}`)",
      "GPT_OSS_HOST_MATCH_COMPLETIONS=Host(`gpt.${var.domain}`) && PathPrefix(`/v1/chat/completions`)",
    ]
    
    options {
      disable_name_suffix_hash = true
    }
  }
  
  replacements = [
    {
      source = {
        kind       = "ConfigMap"
        name       = "env-config"
        field_path = "data.KEYCLOAK_JWKS_URL"
      }
      targets = [{
        select = {
          kind = "APIAuth"
          name = "jwt-auth"
        }
        field_paths = ["spec.jwt.jwksUrl"]
      }]
    },
    {
      source = {
        kind       = "ConfigMap"
        name       = "env-config"
        field_path = "data.KEYCLOAK_ISSUER_URL"
      }
      targets = [{
        select = {
          kind = "APIPortalAuth"
          name = "oidc-portal-auth"
        }
        field_paths = ["spec.oidc.issuerUrl"]
      }]
    },
    {
      source = {
        kind       = "ConfigMap"
        name       = "env-config"
        field_path = "data.OIDC_CLIENT_ID"
      }
      targets = [{
        select = {
          kind = "Secret"
          name = "oidc-credentials"
        }
        field_paths = ["stringData.clientId"]
      }]
    },
    {
      source = {
        kind       = "ConfigMap"
        name       = "env-config"
        field_path = "data.OIDC_CLIENT_SECRET"
      }
      targets = [{
        select = {
          kind = "Secret"
          name = "oidc-credentials"
        }
        field_paths = ["stringData.clientSecret"]
      }]
    },
    {
      source = {
        kind       = "ConfigMap"
        name       = "env-config"
        field_path = "data.KEYCLOAK_ADMIN_ID"
      }
      targets = [{
        select = {
          kind = "ManagedApplication"
          name = "admin-application"
        }
        field_paths = ["spec.owner"]
      }]
    },
    {
      source = {
        kind       = "ConfigMap"
        name       = "env-config"
        field_path = "data.KEYCLOAK_DEVELOPER_ID"
      }
      targets = [{
        select = {
          kind = "ManagedApplication"
          name = "developer-application"
        }
        field_paths = ["spec.owner"]
      }]
    },
    {
      source = {
        kind       = "ConfigMap"
        name       = "env-config"
        field_path = "data.KEYCLOAK_AGENT_ID"
      }
      targets = [{
        select = {
          kind = "ManagedApplication"
          name = "agent-application"
        }
        field_paths = ["spec.owner"]
      }]
    },
    {
      source = {
        kind       = "ConfigMap"
        name       = "env-config"
        field_path = "data.NIM_TC_ENDPOINT"
      }
      targets = [{
        select = {
          kind = "Middleware"
          name = "cc-topic-control-guard"
        }
        field_paths = ["spec.plugin.chat-completion-llm-guard.endpoint"]
      }]
    },
    {
      source = {
        kind       = "ConfigMap"
        name       = "env-config"
        field_path = "data.NIM_CS_ENDPOINT"
      }
      targets = [{
        select = {
          kind = "Middleware"
          name = "cc-content-safety-guard"
        }
        field_paths = ["spec.plugin.chat-completion-llm-guard.endpoint"]
      }]
    },
    {
      source = {
        kind       = "ConfigMap"
        name       = "env-config"
        field_path = "data.NIM_JB_ENDPOINT"
      }
      targets = [{
        select = {
          kind = "Middleware"
          name = "cc-jailbreak-detection-guard"
        }
        field_paths = ["spec.plugin.chat-completion-llm-guard-custom.endpoint"]
      }]
    },
    {
      source = {
        kind       = "ConfigMap"
        name       = "env-config"
        field_path = "data.PORTAL_URL"
      }
      targets = [{
        select = {
          kind = "APIPortal"
          name = "chats-portal"
        }
        field_paths = ["spec.trustedUrls.0"]
      }]
    },
    {
      source = {
        kind       = "ConfigMap"
        name       = "env-config"
        field_path = "data.PORTAL_HOST_MATCH"
      }
      targets = [{
        select = {
          kind = "IngressRoute"
          name = "chats-portal"
        }
        field_paths = ["spec.routes.0.match"]
      }]
    },
    {
      source = {
        kind       = "ConfigMap"
        name       = "env-config"
        field_path = "data.PRESIDIO_HOST"
      }
      targets = [{
        select = {
          kind = "Middleware"
          name = "cc-content-guard"
        }
        field_paths = ["spec.plugin.chat-completion-content-guard.engine.presidio.host"]
      }]
    },
    {
      source = {
        kind       = "ConfigMap"
        name       = "env-config"
        field_path = "data.OLLAMA_BASE_URL"
      }
      targets = [{
        select = {
          kind = "Middleware"
          name = "cc-semantic-cache"
        }
        field_paths = ["spec.plugin.chat-completion-semantic-cache.vectorizer.ollama.baseUrl"]
      }]
    },
    {
      source = {
        kind       = "ConfigMap"
        name       = "env-config"
        field_path = "data.MILVUS_ADDRESS"
      }
      targets = [{
        select = {
          kind = "Middleware"
          name = "cc-semantic-cache"
        }
        field_paths = ["spec.plugin.chat-completion-semantic-cache.vectorDB.milvus.clientConfig.address"]
      }]
    },
  ]
}

# Apply all resources
resource "kustomization_resource" "chats" {
  for_each = data.kustomization_overlay.chats.ids
  
  manifest = data.kustomization_overlay.chats.manifests[each.value]
}
