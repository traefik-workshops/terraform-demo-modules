terraform {
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2.0"
    }
  }
}

# Fetch tokens using external - runs once per resource lifecycle
data "external" "fetch_token" {
  for_each = { for idx, user in var.users : idx => user }

  program = ["bash", "-c", <<-EOT
    curl -sk -X POST "${var.keycloak_url}/realms/${var.realm}/protocol/openid-connect/token" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "client_id=${urlencode(var.client_id)}" \
      -d "grant_type=password" \
      -d "client_secret=${urlencode(var.client_secret)}" \
      -d "scope=openid" \
      -d "username=${urlencode(each.value.username)}" \
      -d "password=${urlencode(each.value.password)}" | \
    jq '{token: .access_token}'
  EOT
  ]
}

# Calculate rotation window based on current time and rotation hours
locals {
  current_timestamp = timestamp()
  current_hour      = formatdate("hh", local.current_timestamp)
  current_date      = formatdate("YYYY-MM-DD", local.current_timestamp)

  # Calculate which rotation window we're in (e.g., if rotation_hours=4: 0-3, 4-7, 8-11, etc.)
  rotation_window = "${local.current_date}-${floor(parseint(local.current_hour, 10) / var.token_rotation_hours)}"
}

# Store tokens in terraform_data - rotates based on time window
resource "terraform_data" "tokens" {
  for_each = { for idx, user in var.users : idx => user }

  triggers_replace = {
    rotation_window = local.rotation_window
  }

  input = data.external.fetch_token[each.key].result.token
}

locals {
  # Output tokens from state (stable across applies)
  tokens = {
    for idx, user in var.users :
    user.username => terraform_data.tokens[idx].output
  }
}
