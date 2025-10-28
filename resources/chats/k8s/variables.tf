variable "domain" {
  description = "Base domain for all services"
  type        = string
  default     = "demo.traefikhub.dev"
}

variable "git_ref" {
  description = "Git reference (branch, tag, or commit) for traefik-demo-resources"
  type        = string
  default     = "main"
}

variable "components" {
  description = "List of components to include (openai, gpt-oss)"
  type        = list(string)
  default     = ["openai", "gpt-oss"]
}

variable "oidc_client_id" {
  description = "OIDC client ID"
  type        = string
}

variable "oidc_client_secret" {
  description = "OIDC client secret"
  type        = string
  sensitive   = true
}

# User ID Variables
variable "keycloak_admin_id" {
  description = "Admin user ID from Keycloak"
  type        = string
}

variable "keycloak_developer_id" {
  description = "Developer user ID from Keycloak"
  type        = string
}

variable "keycloak_agent_id" {
  description = "Agent user ID from Keycloak"
  type        = string
}

# NIM Endpoint Variables (RunPod pod IDs)
variable "nim_tc_pod_id" {
  description = "NVIDIA NIM Topic Control RunPod pod ID"
  type        = string
}

variable "nim_cs_pod_id" {
  description = "NVIDIA NIM Content Safety RunPod pod ID"
  type        = string
}

variable "nim_jb_pod_id" {
  description = "NVIDIA NIM Jailbreak Detection RunPod pod ID"
  type        = string
}

# AI Services Variables
variable "presidio_host" {
  description = "Presidio PII detection service endpoint"
  type        = string
}

variable "ollama_base_url" {
  description = "Ollama embedding service endpoint"
  type        = string
}

variable "milvus_address" {
  description = "Milvus vector database address"
  type        = string
}

variable "openai_auth_header" {
  description = "OpenAI API authorization header"
  type        = string
  sensitive   = true
}

# GPT-OSS Component Variables
variable "gpt_oss_pod_id" {
  description = "GPT-OSS RunPod pod ID"
  type        = string
}
