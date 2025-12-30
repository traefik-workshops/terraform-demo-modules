#cloud-config
write_files:
  - path: /etc/traefik-hub/cli-args
    content: |
%{ for arg in cli_arguments ~}
      ${arg}
%{ endfor ~}
    owner: traefik-hub:traefik-hub
    permissions: "0640"
  - path: /etc/traefik-hub/env
    content: |
%{ for env in env_vars ~}
      ${env.name}=${env.value}
%{ endfor ~}
    owner: root:root
    permissions: "0644"
%{ if file_provider_config != "" ~}
  - path: /etc/traefik-hub/dynamic/dynamic.yaml
    content: |
      ${indent(6, file_provider_config)}
    owner: traefik-hub:traefik-hub
    permissions: "0640"
%{ endif ~}

runcmd:
  # Configure firewall to allow Traefik ports
%{ for port in ports_to_open ~}
  - firewall-cmd --permanent --add-port=${port}/tcp
%{ endfor ~}
  - firewall-cmd --reload

  # Create systemd override directory
  - mkdir -p /etc/systemd/system/traefik-hub.service.d
%{ if cloudflare_dns_enabled ~}

  # Create ACME storage directory and file (only when using Cloudflare DNS for certificates)
  - mkdir -p /data
  - touch /data/acme.json
  - chmod 600 /data/acme.json
  - chown -R traefik-hub:traefik-hub /data || chown -R root:root /data
%{ endif ~}

  # Configure systemd to use environment file and CLI args
  - |
    cat > /etc/systemd/system/traefik-hub.service.d/override.conf << 'EOF'
    [Service]
    EnvironmentFile=-/etc/traefik-hub/env
    ExecStart=
    ExecStart=/usr/local/bin/traefik-hub --hub.token=$${HUB_TOKEN} ${join(" ", cli_arguments)}
    EOF

  - systemctl daemon-reload
  - systemctl restart traefik-hub
