output "tokens" {
  description = "Map of username to JWT access token"
  value       = local.tokens
  sensitive   = true
}

output "token_list" {
  description = "List of JWT access tokens in the same order as input users"
  value       = [for user in var.users : local.tokens[user.username]]
  sensitive   = true
}

output "count" {
  description = "Number of tokens generated"
  value       = length(local.tokens)
}
