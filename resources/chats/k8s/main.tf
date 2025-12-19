# Create ArgoCD Application for chats resources using Helm
resource "kubectl_manifest" "chats" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = var.name
      namespace = var.namespace
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/traefik-workshops/traefik-demo-resources"
        targetRevision = var.git_ref
        path           = "chats/helm"
        helm = {
          values = yamlencode({
            domain      = var.domain
            components  = var.components
            protocol    = var.protocol
            entryPoints = var.entrypoints
            keycloak = {
              adminId     = var.keycloak_admin_id
              developerId = var.keycloak_developer_id
              agentId     = var.keycloak_agent_id
            }
            oidc = {
              clientId     = var.oidc_client_id
              clientSecret = var.oidc_client_secret
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
              llmGuards = {
                enabled     = var.llm_guards_enabled
                useHubChain = var.llm_guards_use_hub_chain
                topicControlGuard = {
                  enabled = var.llm_guards_topic_control_guard
                  podId   = var.nim_tc_pod_id
                }
                contentSafetyGuard = {
                  enabled = var.llm_guards_content_safety_guard
                  podId   = var.nim_cs_pod_id
                }
                jailbreakDetectionGuard = {
                  enabled = var.llm_guards_jailbreak_detection_guard
                  podId   = var.nim_jb_pod_id
                }
                graniteGuard = {
                  enabled = var.llm_guards_granite_guardian
                  podId   = var.nim_jb_pod_id
                }
              }
              semanticCache = {
                enabled = var.semantic_cache_enabled
              }
              contentGuard = {
                enabled = var.content_guard_enabled
              }
            }
          })
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
      }
      syncPolicy = {
        automated = {
          prune      = true
          selfHeal   = true
          allowEmpty = true
        }
        syncOptions = [
          "CreateNamespace=true",
          "PruneLast=true"
        ]
      }
    }
  })
}
