#cloud-config
write_files:
  - path: /etc/traefik-hub/traefik-hub.yaml
    content: |
      # Base Config provided by user (if any)
      ${indent(6, traefik_config)}

      # --- Ported Configuration ---
      %{ if traefik_hub_token != "" }
      hub:
        token: ${traefik_hub_token}
      %{ endif }

      log:
        level: ${log_level}

      %{ if enable_prometheus || (otlp_address != "" && enable_otlp_metrics) }
      metrics:
        %{ if enable_prometheus }
        prometheus:
          entryPoint: metrics
        %{ endif }
        %{ if otlp_address != "" && enable_otlp_metrics }
        otlp:
          enabled: true
          serviceName: ${otlp_service_name}
          http:
            endpoint: "${otlp_address}/v1/metrics"
            tls:
              insecureSkipVerify: true
        %{ endif }
      %{ endif }

      %{ if enable_otlp_traces && otlp_address != "" }
      tracing:
        serviceName: ${otlp_service_name}
        otlp:
          http:
            endpoint: "${otlp_address}/v1/traces"
            tls:
              insecureSkipVerify: true
      %{ endif }

      api:
        dashboard: ${enable_dashboard}
        insecure: ${dashboard_insecure}

      entryPoints:
      %{ for name, ep in entry_points }
        ${name}:
          address: ${ep.address}
      %{ endfor }
      %{ if enable_prometheus }
        metrics:
          address: :${metrics_port}
      %{ endif }

      %{ if length(custom_plugins) > 0 }
      experimental:
        plugins:
      %{ for name, plugin in custom_plugins }
          ${name}:
            moduleName: ${plugin.moduleName}
            version: ${plugin.version}
      %{ endfor }
      %{ endif }

      providers:
        file:
          directory: /etc/traefik-hub/dynamic
          watch: true

    owner: traefik-hub:traefik-hub
    permissions: "0640"

  # %{ if file_provider_config != "" }
  - path: /etc/traefik-hub/dynamic/dynamic.yaml
    content: |
      ${indent(6, file_provider_config)}
    owner: traefik-hub:traefik-hub
    permissions: "0640"
  # %{ endif }

  # Write Environment Variables for Systemd
  - path: /etc/traefik-hub/env
    content: |
      # %{ for env in custom_envs }
      ${env.name}=${env.value}
      # %{ endfor }
    owner: root:root
    permissions: "0644"

runcmd:
  # Update systemd service to load env file if not present
  - mkdir -p /etc/systemd/system/traefik-hub.service.d
  - echo "[Service]" > /etc/systemd/system/traefik-hub.service.d/override.conf
  - echo "EnvironmentFile=-/etc/traefik-hub/env" >> /etc/systemd/system/traefik-hub.service.d/override.conf

  # Configure CLI args for logs if enabled
  # %{ if enable_otlp_access_logs && otlp_address != "" }
  - echo "Environment=TRAEFIK_EXPERIMENTAL_OTLPLOGS=true" >> /etc/systemd/system/traefik-hub.service.d/override.conf
  - echo "Environment=TRAEFIK_ACCESSLOG_OTLP_HTTP_ENDPOINT=${otlp_address}/v1/logs" >> /etc/systemd/system/traefik-hub.service.d/override.conf
  # %{ endif }

  # %{ if enable_otlp_application_logs && otlp_address != "" }
  - echo "Environment=TRAEFIK_EXPERIMENTAL_OTLPLOGS=true" >> /etc/systemd/system/traefik-hub.service.d/override.conf
  - echo "Environment=TRAEFIK_LOG_OTLP_HTTP_ENDPOINT=${otlp_address}/v1/logs" >> /etc/systemd/system/traefik-hub.service.d/override.conf
  # %{ endif }

  - systemctl daemon-reload
  - systemctl restart traefik-hub
