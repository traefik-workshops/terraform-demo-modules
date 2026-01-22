#cloud-config
packages:
  - keepalived
  - procps-ng

write_files:
  - path: /etc/keepalived/keepalived.conf
    content: |
      vrrp_script chk_traefik {
          script "pkill -0 traefik-hub"
          interval 2
          weight 2
          fall 2
          rise 2
          user root
      }

      vrrp_instance VI_1 {
          state BACKUP
          interface ${network_interface}
          virtual_router_id 51
          priority ${keepalived_priority}
          advert_int 1
          authentication {
              auth_type PASS
              auth_pass topsecre
          }
          virtual_ipaddress {
              ${vip}
          }
          track_script {
              chk_traefik
          }
      }
    owner: root:root
    permissions: "0644"

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
%{ if dashboard_config != "" ~}
  - path: /etc/traefik-hub/dynamic/dashboard.yaml
    content: |
      ${indent(6, dashboard_config)}
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
  - systemctl enable --now keepalived
  - systemctl restart traefik-hub
