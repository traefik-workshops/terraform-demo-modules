# Keycloak Security Module

This module deploys Keycloak with support for both simple and advanced user configurations.

## User Configuration

### Simple Users (Basic)

Use the `users` variable for simple user creation with auto-generated groups:

```hcl
users = ["admin", "developer"]
```

This creates users with:
- Email: `{username}@traefik.io`
- Password: `topsecretpassword`
- Groups: `["{username}s"]`

### Advanced Users (Detailed)

Use the `advanced_users` variable for detailed user configuration with custom groups and claims:

```hcl
advanced_users = [{
  username = "officer"
  email    = "officer@traefik.io"
  password = "topsecretpassword"
  groups   = ["police", "public-works"]
  claims   = {
    "tools" = ["road_closures", "outages", "donught_finder"]
  }
}, {
  username = "student-counselor"
  email    = "student-counselor@traefik.io"
  password = "topsecretpassword"
  groups   = ["support", "higher-education"]
  claims   = {
    "tools" = ["spenddesk", "hrdesk", "scholarship", "housing", "financial-aid"]
  }
}, {
  username = "admin"
  email    = "admin@traefik.io"
  password = "topsecretpassword"
  groups   = ["admin"]
  claims   = {
    "tools" = ["all"]
    "roles" = ["admin"]
  }
}]
```

Both `users` and `advanced_users` can be used together. The module will merge them automatically.

## Claims in JWT Tokens

Custom claims defined in the `claims` map will automatically be:
1. Stored as user attributes in Keycloak
2. Mapped to JWT token claims via protocol mappers
3. Included in the access token, ID token, and userinfo endpoint

For example, the `tools` and `roles` claims from the advanced users will appear in the JWT token:

```json
{
  "tools": ["road_closures", "outages", "donught_finder"],
  "roles": ["admin"],
  "group": ["police", "public-works"]
}
```

The module automatically creates protocol mappers for all unique claim keys found across all users.

## Outputs

The module provides three outputs:

### `users`
Complete user information including IDs, usernames, emails, groups, and claims:
```hcl
[
  {
    id       = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
    username = "officer"
    email    = "officer@traefik.io"
    groups   = ["police", "public-works"]
    claims   = { tools = ["road_closures", "outages", "donught_finder"] }
  }
]
```

### `user_ids`
Map of usernames to their Keycloak UUIDs:
```hcl
{
  "officer"           = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
  "student-counselor" = "b2c3d4e5-f6a7-8901-bcde-f12345678901"
  "admin"             = "c3d4e5f6-a7b8-9012-cdef-123456789012"
}
```

### `user_credentials` (sensitive)
User credentials marked as sensitive output:
```hcl
{
  "officer" = {
    email    = "officer@traefik.io"
    password = "topsecretpassword"
  }
}
```

**Note:** User IDs are deterministically generated using `uuidv5` based on the username, ensuring consistency across Terraform runs.

## Testing Authentication

```bash
curl -L --insecure -s -X POST 'http://keycloak.localhost:8080/realms/traefik/protocol/openid-connect/token' \
   -H 'Content-Type: application/x-www-form-urlencoded' \
   --data-urlencode 'client_id=traefik' \
   --data-urlencode 'grant_type=password' \
   --data-urlencode 'client_secret=NoTgoLZpbrr5QvbNDIRIvmZOhe9wI0r0' \
   --data-urlencode 'scope=openid' \
   --data-urlencode 'username=admin@traefik.io' \
   --data-urlencode 'password=topsecretpassword' | jq -r '.access_token'
```

```bash
curl -L --insecure -s -X POST 'http://keycloak.localhost:8080/realms/traefik/protocol/openid-connect/token' \
   -H 'Content-Type: application/x-www-form-urlencoded' \
   --data-urlencode 'client_id=traefik' \
   --data-urlencode 'grant_type=password' \
   --data-urlencode 'client_secret=NoTgoLZpbrr5QvbNDIRIvmZOhe9wI0r0' \
   --data-urlencode 'scope=openid' \
   --data-urlencode 'username=developer@traefik.io' \
   --data-urlencode 'password=topsecretpassword' | jq -r '.access_token'
```