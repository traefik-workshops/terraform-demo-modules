#cloud-config

write_files:
  - path: /etc/systemd/system/traefik-hub.service
    content: |
      [Unit]
      Description=Traefik Hub
      After=docker.service network-online.target
      Wants=network-online.target

      [Service]
      EnvironmentFile=-/etc/traefik-hub/env
      # Binary extracted to /usr/local/bin
      ExecStart=/usr/local/bin/traefik-hub --hub.token=$${HUB_TOKEN} ${join(" ", cli_arguments)}
      Restart=always
      RestartSec=10

      [Install]
      WantedBy=multi-user.target
    owner: root:root
    permissions: "0644"

  - path: /etc/traefik-hub/env
    content: |
%{ for env in env_vars ~}
      ${env.name}=${env.value}
%{ endfor ~}
    owner: root:root
    permissions: "0600"

%{ if file_provider_config != "" ~}
  - path: /etc/traefik-hub/dynamic/dynamic.yaml
    content: |
      ${indent(6, file_provider_config)}
    owner: root:root
    permissions: "0644"
%{ endif ~}

%{ if otlp_address != "" ~}
  - path: /etc/systemd/system/node_exporter.service
    content: |
      [Unit]
      Description=Node Exporter
      After=network.target

      [Service]
      User=root
      Group=root
      Type=simple
      ExecStartPre=/usr/bin/chmod +x /usr/local/bin/node_exporter
      ExecStart=/usr/local/bin/node_exporter --web.listen-address=:9101
      Restart=always
      RestartSec=5

      [Install]
      WantedBy=multi-user.target
    owner: root:root
    permissions: "0644"

  - path: /etc/otelcol-contrib/config.yaml
    content: |
      receivers:
        prometheus:
          config:
            scrape_configs:
              - job_name: 'node-exporter'
                scrape_interval: 5s
                static_configs:
                  - targets: ['localhost:9101']
              - job_name: 'traefik'
                scrape_interval: 5s
                static_configs:
                  - targets: ['localhost:9100']
      exporters:
        otlphttp:
          endpoint: "${otlp_address}"
          tls:
            insecure_skip_verify: true
      processors:
        batch:
          timeout: 5s
      service:
        pipelines:
          metrics:
            receivers: [prometheus]
            processors: [batch]
            exporters: [otlphttp]
    owner: root:root
    permissions: "0644"
%{ endif ~}

runcmd:
  # Install Docker to pull image
  - yum update -y
  - yum install -y docker
  - systemctl start docker
  - systemctl enable docker

  # Create directories
  - mkdir -p /etc/traefik-hub/dynamic
  - mkdir -p /data
  - touch /data/acme.json && chmod 600 /data/acme.json

  # Extract binary from image
  - echo "Pulling image ${traefik_image}"
  - docker pull ${traefik_image}
  - id=$(docker create ${traefik_image})
  - echo "Extracting binary..."
  - docker cp $id:/traefik-hub /usr/local/bin/traefik-hub || docker cp $id:/usr/local/bin/traefik /usr/local/bin/traefik-hub
  - docker rm -v $id
  - chmod +x /usr/local/bin/traefik-hub
  
  # Start Traefik Service
  - systemctl daemon-reload
  - systemctl enable --now traefik-hub

%{ if otlp_address != "" ~}
  # Install Node Exporter
  - |
    echo "Installing Node Exporter..."
    curl -sfLO https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz || (echo "FAILED to download node_exporter" && exit 1)
    tar xvfz node_exporter-1.7.0.linux-amd64.tar.gz || (echo "FAILED to extract node_exporter" && exit 1)
    cp node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/
    chmod +x /usr/local/bin/node_exporter
    rm -rf node_exporter*
    systemctl daemon-reload
    systemctl enable --now node_exporter || (journalctl -u node_exporter | tail -n 20)
    echo "Node Exporter status: $(systemctl is-active node_exporter)"

  # Install OTEL Collector
  - |
    echo "Installing OTEL Collector..."
    curl -sfLO https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.118.0/otelcol-contrib_0.118.0_linux_amd64.rpm || (echo "FAILED to download OTEL collector" && exit 1)
    rpm -ivh otelcol-contrib_0.118.0_linux_amd64.rpm || (echo "FAILED to install OTEL collector" && exit 1)
    systemctl enable --now otelcol-contrib
    systemctl restart otelcol-contrib
    echo "OTEL Collector status: $(systemctl is-active otelcol-contrib)"
%{ endif ~}
