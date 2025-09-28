variable "runpod_api_key" {
  description = "RunPod API key"
  type        = string
  sensitive   = true
}

variable "ngc_token" {
  description = "NVIDIA NGC API token"
  type        = string
  sensitive   = true
}

variable "ngc_username" {
  description = "NVIDIA NGC username (usually '$oauthtoken' for API auth)"
  type        = string
  default     = "$oauthtoken"
}

variable "pod_type" {
  description = "The type of pod to deploy (e.g., NVIDIA L40, NVIDIA A100, etc.)"
  type        = string
  default     = "NVIDIA A40"
}

# Topic Control NIM
variable "topic_control_nim" {
  description = "Configuration for Topic Control NIM"
  type = object({
    enabled = bool
    image   = string
    tag     = string
  })
  default = {
    enabled = true
    image   = "nvcr.io/nim/nvidia/llama-3.1-nemoguard-8b-topic-control"
    tag     = "latest"
  }
}

# Content Safety NIM
variable "content_safety_nim" {
  description = "Configuration for Content Safety NIM"
  type = object({
    enabled = bool
    image   = string
    tag     = string
  })
  default = {
    enabled = false
    image   = "nvcr.io/nim/nvidia/llama-3.1-nemoguard-8b-content-safety"
    tag     = "latest"
  }
}

# Jailbreak Detection NIM
variable "jailbreak_detection_nim" {
  description = "Configuration for Jailbreak Detection NIM"
  type = object({
    enabled = bool
    image   = string
    tag     = string
  })
  default = {
    enabled = false
    image   = "nvcr.io/nim/nvidia/nemoguard-jailbreak-detect"
    tag     = "latest"
  }
}
