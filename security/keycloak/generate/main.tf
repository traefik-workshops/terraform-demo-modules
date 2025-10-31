terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Fetch JWT tokens as resources (only runs when created/replaced)
resource "null_resource" "keycloak_token" {
  for_each = { for idx, user in var.users : idx => user }

  # Only triggers if username/password changes or file doesn't exist
  triggers = {
    username = each.value.username
    password = each.value.password
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      
      # Fetch token from Keycloak
      RESPONSE=$$(curl -sk -X POST "${var.keycloak_url}/realms/${var.realm}/protocol/openid-connect/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "client_id=${urlencode(var.client_id)}" \
        -d "grant_type=password" \
        -d "client_secret=${urlencode(var.client_secret)}" \
        -d "scope=openid" \
        -d "username=${urlencode(each.value.username)}" \
        -d "password=${urlencode(each.value.password)}")
      
      # Extract access token
      TOKEN=$$(echo "$$RESPONSE" | jq -r '.access_token // empty')
      
      if [ -z "$$TOKEN" ]; then
        echo "Failed to fetch token for ${each.value.username}" >&2
        echo "Response: $$RESPONSE" >&2
        exit 1
      fi
      
      # Decode JWT to get expiration
      PAYLOAD=$$(echo "$$TOKEN" | cut -d'.' -f2 | sed 's/-/+/g;s/_/\//g')
      while [ $$(($${#PAYLOAD} % 4)) -ne 0 ]; do
        PAYLOAD="$${PAYLOAD}="
      done
      EXP=$$(echo "$$PAYLOAD" | base64 -d 2>/dev/null | jq -r '.exp // 0' 2>/dev/null || echo "0")
      
      # Store token and expiration
      jq -n --arg token "$$TOKEN" --arg exp "$$EXP" '{token: $$token, exp: ($$exp | tonumber)}' > "${path.module}/.token_${each.key}.json"
    EOT
  }
}

# Read token data from stored JSON files
locals {
  # Load token data for each user
  token_data = {
    for idx, user in var.users : idx => (
      fileexists("${path.module}/.token_${idx}.json") ?
        jsondecode(file("${path.module}/.token_${idx}.json")) :
        { token = "", exp = 0 }
    )
  }
  
  # Output tokens (stable across applies unless expired)
  tokens = {
    for idx, user in var.users :
    user.username => local.token_data[idx].token
  }
}
