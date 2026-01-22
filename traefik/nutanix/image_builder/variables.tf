variable "arch" {
  description = "Architecture for the image build (amd64 or arm64)"
  type        = string
  default     = "amd64"
}

variable "hub_dir" {
  description = "Path to the traefik-hub repository"
  type        = string
  default     = null
}

variable "hub_version" {
  description = "Traefik Hub version to build from"
  type        = string
  default     = "3.18.3"
}

variable "image_path" {
  description = "Optional path to a pre-existing image file (skips building but still uploads)"
  type        = string
  default     = null
}

variable "enable_preview_mode" {
  description = "Enable Traefik Hub preview mode"
  type        = bool
  default     = false
}

variable "hub_preview_tag" {
  description = "Tag to use when preview mode is enabled"
  type        = string
  default     = "latest-v3"
}

variable "custom_image_registry" {
  description = "Custom registry for Traefik Hub image"
  type        = string
  default     = ""
}

variable "custom_image_repository" {
  description = "Custom repository for Traefik Hub image"
  type        = string
  default     = ""
}
