terraform {
  required_providers {
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

# Generate JWT tokens for each user
data "http" "keycloak_token" {
  for_each = { for idx, user in var.users : idx => user }

  url      = "${var.keycloak_url}/realms/${var.realm}/protocol/openid-connect/token"
  method   = "POST"
  insecure = true

  request_headers = {
    Content-Type = "application/x-www-form-urlencoded"
  }

  request_body = join("&", [
    "client_id=${urlencode(var.client_id)}",
    "grant_type=password",
    "client_secret=${urlencode(var.client_secret)}",
    "scope=openid",
    "username=${urlencode(each.value.username)}",
    "password=${urlencode(each.value.password)}"
  ])

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Failed to obtain JWT token for user ${each.value.username}: HTTP ${self.status_code}"
    }
  }
}

locals {
  # Parse the JWT tokens from the responses
  tokens = {
    for idx, response in data.http.keycloak_token :
    var.users[idx].username => jsondecode(response.response_body).access_token
  }
}
