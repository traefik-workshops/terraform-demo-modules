variable "name" {
  type        = string
  description = "The name of the airlines release"
  default     = "airlines"
}

variable "namespace" {
  type        = string
  description = "Namespace for the airlines deployment"
}

variable "domain" {
  description = "Base domain for all services"
  type        = string
  default     = "triple-gate.traefik.ai"
}

variable "git_ref" {
  description = "Git reference (branch, tag, or commit) for traefik-demo-resources"
  type        = string
  default     = "main"
}

variable "jwt_tokens" {
  description = "Map of JWT tokens for MCP servers (ticketing, userAssistance, partnerAssistance)"
  type = object({
    ticketing         = string
    userAssistance    = string
    partnerAssistance = string
  })
}
