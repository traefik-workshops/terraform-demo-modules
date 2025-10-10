output "users" {
  description = "All users with their IDs, emails, groups, and claims"
  value = [
    for user in local.all_users : {
      id       = uuidv5("dns", user.username)
      username = user.username
      email    = user.email
      groups   = user.groups
      claims   = user.claims
      password = user.password
    }
  ]
}
