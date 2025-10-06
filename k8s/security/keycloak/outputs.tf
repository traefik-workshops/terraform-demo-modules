output "users" {
  value = [for username in var.users : {
    email    = "${username}@traefik.io"
    password = "topsecretpassword"
  }]
}