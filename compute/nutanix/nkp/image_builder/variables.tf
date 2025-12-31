variable "arch" {
  description = "Architecture for the image build (amd64 or arm64)"
  type        = string
  default     = "amd64"
}

variable "vm_name" {
  description = "Name prefix for the image"
  type        = string
  default     = "whoami"
}


