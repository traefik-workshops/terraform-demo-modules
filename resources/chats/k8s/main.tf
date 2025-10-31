# Create ArgoCD Application for chats resources using Helm
resource "argocd_application" "chats" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }

  spec {
    project = "default"

    source {
      repo_url        = "https://github.com/traefik-workshops/traefik-demo-resources"
      target_revision = var.git_ref
      path            = "chats/helm"
      
      helm {
        values = yamlencode({
          domain = var.domain
          
          components = var.components
          
          keycloak = {
            adminId     = var.keycloak_admin_id
            developerId = var.keycloak_developer_id
            agentId     = var.keycloak_agent_id
          }
          
          oidc = {
            clientId     = var.oidc_client_id
            clientSecret = var.oidc_client_secret
          }
          
          nim = {
            topicControl = {
              podId = var.nim_tc_pod_id
            }
            contentSafety = {
              podId = var.nim_cs_pod_id
            }
            jailbreakDetection = {
              podId = var.nim_jb_pod_id
            }
          }
          
          presidio = {
            host = var.presidio_host
          }
          
          ollama = {
            baseUrl = var.ollama_base_url
          }
          
          weaviate = {
            address = var.weaviate_address
          }
          
          openai = {
            authHeader = "Bearer ${var.openai_auth_header}"
          }
          
          gptOss = {
            podId = var.gpt_oss_pod_id
          }

          middlewares = {
            # LLM Guards (topic control, content safety, jailbreak detection)
            llmGuards = {
              enabled = var.llm_guards_enabled
            }
            # Semantic cache for response caching
            semanticCache = {
              enabled = var.semantic_cache_enabled
            }
            # Content guard (PII detection with Presidio)
            contentGuard = {
              enabled = var.content_guard_enabled
            }
          }
        })
      }
    }

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "default"
    }

    sync_policy {
      automated {
        prune       = true
        self_heal   = true
        allow_empty = true
      }
      
      sync_options = [
        "CreateNamespace=true",
        "PruneLast=true"
      ]
    }

    cascade = true
    wait    = true
  }
}
