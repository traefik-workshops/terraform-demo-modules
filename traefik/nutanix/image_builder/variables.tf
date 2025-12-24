variable "arch" {
  description = "Architecture for the image build (amd64 or arm64)"
  type        = string
  default     = "amd64"
}

variable "hub_dir" {
  description = "Path to the traefik-hub repository"
  type        = string
  default     = "../../../../../traefik-hub"
}
