terraform {
  required_providers {
    kubernetes = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}
