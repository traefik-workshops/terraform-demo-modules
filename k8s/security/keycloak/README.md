```bash
curl -L --insecure -s -X POST 'http://keycloak.traefik.localhost:8080/realms/traefik/protocol/openid-connect/token' \
   -H 'Content-Type: application/x-www-form-urlencoded' \
   --data-urlencode 'client_id=traefik' \
   --data-urlencode 'grant_type=password' \
   --data-urlencode 'client_secret=NoTgoLZpbrr5QvbNDIRIvmZOhe9wI0r0' \
   --data-urlencode 'scope=openid' \
   --data-urlencode 'username=admin@traefik.io' \
   --data-urlencode 'password=topsecretpassword' | jq -r '.access_token'
```

```bash
curl -L --insecure -s -X POST 'http://keycloak.traefik.localhost:8080/realms/traefik/protocol/openid-connect/token' \
   -H 'Content-Type: application/x-www-form-urlencoded' \
   --data-urlencode 'client_id=traefik' \
   --data-urlencode 'grant_type=password' \
   --data-urlencode 'client_secret=NoTgoLZpbrr5QvbNDIRIvmZOhe9wI0r0' \
   --data-urlencode 'scope=openid' \
   --data-urlencode 'username=developer@traefik.io' \
   --data-urlencode 'password=topsecretpassword' | jq -r '.access_token'
```