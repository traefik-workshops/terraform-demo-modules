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
