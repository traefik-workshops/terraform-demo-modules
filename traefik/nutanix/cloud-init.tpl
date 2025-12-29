#cloud-config
write_files:
  # Write CLI arguments to a file that will be used by systemd
  - path: /etc/traefik-hub/cli-args
    content: |
%{ for arg in cli_arguments ~}
      ${arg}
%{ endfor ~}
    owner: traefik-hub:traefik-hub
    permissions: "0640"

  # Write environment variables for systemd
  - path: /etc/traefik-hub/env
    content: |
%{ for env in env_vars ~}
      ${env.name}=${env.value}
%{ endfor ~}
    owner: root:root
    permissions: "0644"

%{ if file_provider_config != "" ~}
  # Dynamic configuration for file provider
  - path: /etc/traefik-hub/dynamic/dynamic.yaml
    content: |
      ${indent(6, file_provider_config)}
    owner: traefik-hub:traefik-hub
    permissions: "0640"
%{ endif ~}

runcmd:
  # Create systemd override directory
  - mkdir -p /etc/systemd/system/traefik-hub.service.d

  # Configure systemd to use environment file and CLI args
  - |
    cat > /etc/systemd/system/traefik-hub.service.d/override.conf << 'EOF'
    [Service]
    EnvironmentFile=-/etc/traefik-hub/env
%{ for arg in cli_arguments ~}
    ExecStart=
    ExecStart=/usr/bin/traefik-hub ${join(" ", cli_arguments)}
%{ endfor ~}
    EOF

  - systemctl daemon-reload
  - systemctl restart traefik-hub
