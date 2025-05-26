# Get default domain
data "azuread_domains" "traefik_demo" {
  only_default = true
}

# Create users
resource "azuread_user" "traefik_demo" {
  for_each = toset(var.users)

  user_principal_name     = "${each.value}@${data.azuread_domains.traefik_demo.domains[0].domain_name}"
  display_name            = each.value
  password                = "topsecretpassword"
  force_password_change   = false
  disable_strong_password = true
}

# Create groups
resource "azuread_group" "traefik_demo" {
  for_each = toset(var.users)

  display_name     = each.value
  security_enabled = true
}

# Add users to their respective groups
resource "azuread_group_member" "traefik_demo" {
  for_each = toset(var.users)

  group_object_id  = azuread_group.traefik_demo[each.value].object_id
  member_object_id = azuread_user.traefik_demo[each.value].object_id
}

# Create permission scope uuid
resource "random_uuid" "traefik_demo_permission_scope_id" {}

# Create app registration
resource "azuread_application" "traefik_demo" {
  display_name = "traefik_demo"
  
  # Configure optional claims and group membership claims
  optional_claims {
    access_token {
      name      = "groups"
      essential = true
    }
  }
  
  group_membership_claims = ["All"]

  web {
    redirect_uris = [
      "http://localhost/*"
    ]
    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
    resource_access {
      id   = "37f7f235-527c-4136-accd-4a02d197296e" # openid
      type = "Scope"
    }
    resource_access {
      id   = "7427e0e9-2fba-42fe-b0c0-848c9e6a8182" # offline_access
      type = "Scope"
    }
    resource_access {
      id   = "62a82d76-70ea-41e2-9197-370581804d09" # Group.Read.All
      type = "Role"
    }
  }

  # Add API scope
  api {
    mapped_claims_enabled = true
    known_client_applications = []

    oauth2_permission_scope {
      admin_consent_description  = "Allow the application to access group membership information"
      admin_consent_display_name = "Access Groups"
      enabled                   = true
      id                        = random_uuid.traefik_demo_permission_scope_id.id
      type                      = "User"
      user_consent_description  = "Allow this application to access your group membership information"
      user_consent_display_name = "Access your groups"
      value                     = "groups"
    }
  }
}

resource "random_uuid" "traefik_demo_app_role_id" {
  for_each = toset(var.users)
}

# Create app roles
resource "azuread_application_app_role" "traefik_demo" {
  for_each = toset(var.users)

  application_id = azuread_application.traefik_demo.id
  role_id        = random_uuid.traefik_demo_app_role_id[each.value].id

  allowed_member_types = ["User", "Application"]
  description          = "${title(each.value)} role for full access"
  display_name         = "${title(each.value)}"
  value                = "${each.value}"
}

# Create client secret
resource "azuread_application_password" "traefik_demo" {
  application_id = azuread_application.traefik_demo.id
  display_name   = "traefik-demo-secret"
  end_date       = "2050-12-31T00:00:00Z"  # Set expiry date
}

# Create service principal for the application
resource "azuread_service_principal" "traefik_demo" {
  client_id = azuread_application.traefik_demo.client_id
}

# Assign roles to users
resource "azuread_app_role_assignment" "traefik_demo" {
  for_each = toset(var.users)

  app_role_id         = azuread_application_app_role.traefik_demo[each.value].role_id
  principal_object_id = azuread_user.traefik_demo[each.value].object_id
  resource_object_id  = azuread_service_principal.traefik_demo.object_id
}