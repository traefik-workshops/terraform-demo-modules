#cloud-config

ssh_pwauth: true

users:
  - name: traefiker
    groups: sudo
    shell: /bin/bash
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    lock_passwd: false

chpasswd:
  expire: false
  list:
    - traefiker:topsecretpassword

write_files:
  - path: /etc/ssh/sshd_config.d/99-traefik.conf
    owner: root:root
    permissions: "0644"
    content: |
      PasswordAuthentication yes

  - path: /etc/sysctl.d/99-traefik-perf.conf
    owner: root:root
    permissions: "0644"
    content: |
      net.ipv4.tcp_tw_reuse = ${performance_tuning.tcp_tw_reuse}
      net.ipv4.tcp_timestamps = ${performance_tuning.tcp_timestamps}
      net.core.rmem_max = ${performance_tuning.rmem_max}
      net.core.wmem_max = ${performance_tuning.wmem_max}
      net.core.somaxconn = ${performance_tuning.somaxconn}
      net.core.netdev_max_backlog = ${performance_tuning.netdev_max_backlog}
      net.ipv4.ip_local_port_range = ${performance_tuning.ip_local_port_range}

  - path: /etc/systemd/system/traefik-hub.service
    owner: root:root
    permissions: "0644"
    content: |
      [Unit]
      Description=Traefik Hub
      After=network-online.target
      Wants=network-online.target

      [Service]
      Type=simple
      EnvironmentFile=-/etc/traefik-hub/env
      EnvironmentFile=-/etc/traefik-hub/dns-traefiker.env
      LimitNOFILE=${performance_tuning.limit_nofile}
      %{ if performance_tuning.gomaxprocs > 0 }
      Environment=GOMAXPROCS=${performance_tuning.gomaxprocs}
      %{ endif }
      Environment=GOGC=${performance_tuning.gogc}
      %{ if performance_tuning.numa_node >= 0 }
      NUMAPolicy=bind
      NUMAMask=${performance_tuning.numa_node}
      CPUAffinity=numa
      %{ endif }
      ExecStart=/usr/local/bin/traefik-hub --hub.token=$${HUB_TOKEN} ${join(" ", cli_arguments)}
      Restart=always
      RestartSec=10
      AmbientCapabilities=CAP_NET_BIND_SERVICE

      [Install]
      WantedBy=multi-user.target

%{ if dns_traefiker.enabled }
  - path: /etc/systemd/system/dns-traefiker.service
    owner: root:root
    permissions: "0644"
    content: |
      [Unit]
      Description=DNS Traefiker
      After=network-online.target docker.service
      Wants=network-online.target docker.service

      [Service]
      Type=simple
      EnvironmentFile=/etc/traefik-hub/dns-traefiker.env
      ExecStartPre=-/usr/bin/docker stop dns-traefiker
      ExecStartPre=-/usr/bin/docker rm dns-traefiker
      ExecStart=/usr/bin/docker run --rm --name dns-traefiker --net=host \
        -v /etc/traefik-hub:/etc/traefik-hub \
        --env-file /etc/traefik-hub/dns-traefiker.env \
        -e ENV_FILE_PATH=/etc/traefik-hub/dns-traefiker.env \
        zalbiraw/dns-traefiker:latest
      Restart=always
      RestartSec=30

      [Install]
      WantedBy=multi-user.target

  - path: /etc/traefik-hub/dns-traefiker.env
    owner: root:root
    permissions: "0600"
    content: |
      DOMAIN=${dns_traefiker.domain}
      UNIQUE_DOMAIN=${dns_traefiker.unique_domain}
      PROXIED=${dns_traefiker.proxied}
      ENABLE_AIRLINES_SUBDOMAIN=${dns_traefiker.enable_airlines_subdomain}
      IP_OVERRIDE=${dns_traefiker.ip_override}
%{ endif }

  - path: /etc/systemd/system/node_exporter.service
    owner: root:root
    permissions: "0644"
    content: |
      [Unit]
      Description=Node Exporter
      After=network.target

      [Service]
      User=root
      ExecStart=/usr/local/bin/node_exporter --collector.cpu --collector.schedstat --collector.perf --web.listen-address=:9102
      Restart=always

      [Install]
      WantedBy=multi-user.target

  - path: /etc/traefik-hub/env
    owner: root:root
    permissions: "0600"
    content: |
      %{ for env in env_vars ~}
      ${env.name}=${env.value}
      %{ endfor ~}

%{ if file_provider_config != "" ~}
  - path: /etc/traefik-hub/dynamic/dynamic.yaml
    owner: root:root
    permissions: "0644"
    content: |
      ${indent(6, file_provider_config)}
%{ endif ~}

%{ if dashboard_config != "" ~}
  - path: /etc/traefik-hub/dynamic/dashboard.yaml
    owner: root:root
    permissions: "0644"
    content: |
      ${indent(6, dashboard_config)}
%{ endif ~}

%{ if vip != "" ~}
  - path: /etc/keepalived/keepalived.conf
    owner: root:root
    permissions: "0644"
    content: |
      vrrp_instance VI_1 {
        state BACKUP
        interface ${network_interface}
        virtual_router_id 51
        priority ${keepalived_priority}
        advert_int 1
        authentication {
          auth_type PASS
          auth_pass 1111
        }
        virtual_ipaddress {
          ${vip}
        }
      }
%{ endif ~}

%{ if otlp_address != "" ~}
  - path: /etc/otelcol-contrib/config.yaml
    owner: root:root
    permissions: "0644"
    content: |
      receivers:
        prometheus:
          config:
            scrape_configs:
              - job_name: '${instance_name}'
                scrape_interval: 5s
                static_configs:
                  - targets: ['localhost:9101', 'localhost:9102']
      exporters:
        otlphttp:
          endpoint: "${otlp_address}"
          tls:
            insecure_skip_verify: true
      processors:
        resourcedetection:
          detectors: [env, system, ec2]
          timeout: 2s
          override: false
        batch:
          timeout: 5s
      service:
        pipelines:
          metrics:
            receivers: [prometheus]
            processors: [resourcedetection, batch]
            exporters: [otlphttp]
%{ endif ~}

runcmd:
  - sysctl -p /etc/sysctl.d/99-traefik-perf.conf
  - mkdir -p /etc/traefik-hub/dynamic
  - mkdir -p /data
  - touch /data/acme.json && chmod 600 /data/acme.json
  - chmod 666 /etc/traefik-hub/dns-traefiker.env
  - sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
  - sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
  - sysctl -w kernel.perf_event_paranoid=-1
  - echo "kernel.perf_event_paranoid = -1" > /etc/sysctl.d/99-perf.conf
  - systemctl restart ssh || systemctl restart sshd
  - |
    # Install Node Exporter v1.10.2
    if ! [ -f /usr/local/bin/node_exporter ]; then
      echo "Installing Node Exporter..."
      # Wait for network and retry download
      for i in {1..5}; do
        if curl -L --connect-timeout 10 --max-time 120 "https://github.com/prometheus/node_exporter/releases/download/v1.10.2/node_exporter-1.10.2.linux-amd64.tar.gz" -o /tmp/node_exporter.tar.gz; then
          mkdir -p /tmp/node_exporter-extract
          tar xvfz /tmp/node_exporter.tar.gz -C /tmp/node_exporter-extract
          BINARY=$(find /tmp/node_exporter-extract -type f -name "node_exporter" | head -n 1)
          if [ -n "$BINARY" ]; then
            mv "$BINARY" /usr/local/bin/node_exporter
            chmod +x /usr/local/bin/node_exporter
            echo "Node Exporter binary installed."
            break
          fi
        fi
        echo "Retrying Node Exporter download ($i/5)..."
        sleep 5
      done
      rm -rf /tmp/node_exporter-extract /tmp/node_exporter.tar.gz
    fi
    if [ -f /usr/local/bin/node_exporter ]; then
      systemctl daemon-reload
      systemctl enable node_exporter || true
      systemctl start node_exporter || true
    fi
  - |
    # Robust download and install
    ARCH="${arch}"
    VERSION="${traefik_hub_version}"
    [[ ! $VERSION =~ ^v ]] && VERSION="v$VERSION"
    DOWNLOAD_ARCH="amd64"
    [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]] && DOWNLOAD_ARCH="arm64"
    
    URL="https://github.com/traefik/hub/releases/download/$VERSION/traefik-hub_$${VERSION}_linux_$${DOWNLOAD_ARCH}.tar.gz"
    echo "Downloading Traefik Hub from $URL..."
    
    for i in {1..5}; do
      if curl -L --connect-timeout 10 --max-time 120 "$URL" -o /tmp/traefik-hub.tar.gz; then
        mkdir -p /tmp/traefik-hub-extract
        tar -xzf /tmp/traefik-hub.tar.gz -C /tmp/traefik-hub-extract
        BINARY=$(find /tmp/traefik-hub-extract -maxdepth 1 -type f -name "traefik-hub*" | head -n 1)
        if [ -n "$BINARY" ]; then
          mv "$BINARY" /usr/local/bin/traefik-hub
          chmod +x /usr/local/bin/traefik-hub
          echo "Traefik Hub binary installed."
          break
        fi
      fi
      echo "Retrying Traefik Hub download ($i/5)..."
      sleep 5
    done
    rm -rf /tmp/traefik-hub-extract /tmp/traefik-hub.tar.gz

    if [ ! -f /usr/local/bin/traefik-hub ]; then
      echo "ERROR: Failed to install Traefik Hub after retries"
      exit 1
    fi

%{ if vip != "" ~}
  - |
    # Install Keepalived
    apt-get update && apt-get install -y keepalived
    systemctl enable --now keepalived
%{ endif ~}

  - systemctl daemon-reload
  - |
    # Install Docker if dns-traefiker is enabled
    %{ if dns_traefiker.enabled }
    if ! command -v docker &> /dev/null; then
      echo "Installing Docker..."
      apt-get update
      apt-get install -y ca-certificates curl gnupg
      install -m 0755 -d /etc/apt/keyrings
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      chmod a+r /etc/apt/keyrings/docker.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
      apt-get update
      apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      systemctl enable --now docker
    fi
    systemctl enable --now dns-traefiker
    %{ endif }
  - systemctl enable --now traefik-hub
  - echo "Traefik Hub provisioning complete"

%{ if otlp_address != "" ~}
  # Install OTEL Collector
  - |
    echo "Installing OTEL Collector..."
    curl -sfLO https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.118.0/otelcol-contrib_0.118.0_linux_amd64.rpm || (echo "FAILED to download OTEL collector" && exit 1)
    rpm -ivh otelcol-contrib_0.118.0_linux_amd64.rpm || (echo "FAILED to install OTEL collector" && exit 1)
    systemctl enable --now otelcol-contrib
    systemctl restart otelcol-contrib
    echo "OTEL Collector status: $(systemctl is-active otelcol-contrib)"
%{ endif ~}
