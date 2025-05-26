variable "entraid_users" {
  type        = list(string)
  default     = ["admin", "support"]
  description = "EntraID users to be created"
}
