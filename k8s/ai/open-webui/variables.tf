variable "name" {
  type        = string
  description = "The name of the open-webui release"
  default     = "open-webui"
}

variable "namespace" {
  type        = string
  description = "The namespace of the milvus release"
  default     = "milvus"
}

variable "openai_api_base_urls" {
  type        = list(string)
  default     = []
  description = "OpenAI API base URLs"
}

variable "openai_api_keys" {
  type        = list(string)
  default     = []
  description = "OpenAI API keys"
}

variable "ingress" {
  type        = bool
  default     = false
  description = "Enable ingress for the open-webui release"
}

variable "extraValues" {
  type        = any
  description = "Extra values to pass to the Grafana deployment."
  default     = {}
}
