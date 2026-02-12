# =============================================================================
# EC2 Traefik Deployment
# =============================================================================
# Uses extracted config from traefik/shared module (via Helm template).
# =============================================================================

locals {
  # Use extracted CLI arguments from Helm template (includes file provider if configured)
  # Filter out placeholder token arg to avoid duplicates with manual injection in Systemd unit
  cli_arguments = [
    for arg in module.config.extracted_cli_args_cloud :
    arg if !startswith(arg, "--hub.token=")
  ]

  # Merge standard env vars with explicit HUB_TOKEN injection (Nutanix pattern)
  # Filter out K8s-specific env vars (like valueFrom maps) that don't belong on a VM
  env_vars_list = concat(
    module.config.env_vars_list,
    module.config.traefik_hub_token != "" ? [{ name = "HUB_TOKEN", value = module.config.traefik_hub_token }] : []
  )

  # Use shared module for image reference
  traefik_image = module.config.image_full

  # Normalize performance tuning with defaults
  performance_tuning = {
    limit_nofile        = coalesce(try(var.performance_tuning.limit_nofile, null), 500000)
    tcp_tw_reuse        = coalesce(try(var.performance_tuning.tcp_tw_reuse, null), 1)
    tcp_timestamps      = coalesce(try(var.performance_tuning.tcp_timestamps, null), 1)
    rmem_max            = coalesce(try(var.performance_tuning.rmem_max, null), 16777216)
    wmem_max            = coalesce(try(var.performance_tuning.wmem_max, null), 16777216)
    somaxconn           = coalesce(try(var.performance_tuning.somaxconn, null), 4096)
    netdev_max_backlog  = coalesce(try(var.performance_tuning.netdev_max_backlog, null), 4096)
    ip_local_port_range = coalesce(try(var.performance_tuning.ip_local_port_range, null), "1024 65535")
    gomaxprocs          = coalesce(try(var.performance_tuning.gomaxprocs, null), 0)
    gogc                = coalesce(try(var.performance_tuning.gogc, null), 100)
    numa_node           = coalesce(try(var.performance_tuning.numa_node, null), -1)
  }

  # Generate unique user_data for each replica
  user_data_overrides = {
    for i in range(module.config.replica_count) :
    "traefik-${i + 1}" => templatefile("${path.module}/../cloud-init/cloud-init.tpl", {
      traefik_hub_version   = module.config.image_tag
      arch                  = var.ami_architecture
      cli_arguments         = local.cli_arguments
      env_vars              = local.env_vars_list
      file_provider_config  = var.file_provider_config
      performance_tuning    = local.performance_tuning
      otlp_address          = module.config.otlp_endpoint
      instance_name         = "traefik-${i + 1}" # Explicit unique name as requested
      dashboard_config      = ""                 # Optional
      vip                   = ""                 # Optional
      keepalived_priority   = 100                # Optional
      network_interface     = "ens3"             # Optional
      dns_traefiker_enabled = var.dns_traefiker.enabled
    })
  }

  # Hash of performance tuning for lifestyle triggers
  performance_tuning_hash = sha256(jsonencode(local.performance_tuning))
}

module "ec2" {
  source = "../../compute/aws/ec2"

  apps = {
    traefik = {
      replicas   = module.config.replica_count
      subnet_ids = var.subnet_ids
    }
  }

  instance_type          = var.instance_type
  ami_architecture       = var.ami_architecture
  create_vpc             = var.create_vpc
  vpc_id                 = var.vpc_id
  security_group_ids     = var.security_group_ids
  iam_instance_profile   = var.iam_instance_profile
  enable_acme_setup      = module.config.cloudflare_dns.enabled
  root_block_device_size = var.root_block_device_size

  common_tags = merge(var.extra_tags, {
    "Name"                                                     = "traefik"
    "traefik.enable"                                           = "true"
    "traefik.http.routers.dashboard.rule"                      = module.config.dashboard_match_rule
    "traefik.http.routers.dashboard.entrypoints"               = module.config.dashboard_entrypoints[0]
    "traefik.http.services.dashboard.loadbalancer.server.port" = "8080"
    "traefik.performance_hash"                                 = local.performance_tuning_hash
  })

  # Pass per-instance user data overrides
  user_data_overrides = local.user_data_overrides
}

resource "aws_eip" "traefik" {
  for_each = var.create_eip ? module.ec2.instances : {}

  domain   = "vpc"
  instance = each.value.instance_id

  tags = merge(var.extra_tags, {
    Name = "traefik-eip-${each.key}"
  })

  depends_on = [module.ec2]
}

# Health check: wait for Traefik to be ready on port 80
resource "null_resource" "wait_for_traefik" {
  count = var.wait_for_ready ? 1 : 0

  triggers = {
    # Re-run when instances, EIPs, or other critical variables change
    instance_ids = join(",", [for i in module.ec2.instances : i.instance_id])
    eip_ids      = join(",", [for e in aws_eip.traefik : e.id])
  }

  provisioner "local-exec" {
    command = <<-EOF
      # Collect all potential IPs: EIPs > public_ips > private_ips
      EIP_IPS="${join(" ", [for e in aws_eip.traefik : e.public_ip])}"
      PUBLIC_IPS="${join(" ", values(module.ec2.public_ips))}"
      PRIVATE_IPS="${join(" ", values(module.ec2.private_ips))}"
      
      TRAEFIK_IPS="$EIP_IPS"
      if [ -z "$TRAEFIK_IPS" ]; then
        TRAEFIK_IPS="$PUBLIC_IPS"
      fi
      if [ -z "$TRAEFIK_IPS" ]; then
        TRAEFIK_IPS="$PRIVATE_IPS"
      fi

      TIMEOUT=${var.wait_timeout}
      
      if [ -z "$TRAEFIK_IPS" ]; then
        echo "WARNING: No IP addresses found to wait for. Skipping health check."
        exit 0
      fi

      for IP in $TRAEFIK_IPS; do
        echo "Waiting for Traefik at $IP..."
        
        # Wait for HTTP readiness (port 80)
        echo "  Checking HTTP readiness on port 80..."
        ELAPSED=0
        while [ $ELAPSED -lt $TIMEOUT ]; do
          HTTP_CODE=$(curl -s -o /dev/null -w "%%{http_code}" --connect-timeout 5 http://$IP:80/ 2>/dev/null || echo "000")
          if [ "$HTTP_CODE" = "404" ]; then
            echo "  Traefik at $IP is ready! (HTTP $HTTP_CODE)"
            break
          fi
          echo "  Waiting for HTTP 404... (Current: $HTTP_CODE, $ELAPSED s)"
          sleep 5
          ELAPSED=$((ELAPSED + 5))
        done

        if [ $ELAPSED -ge $TIMEOUT ]; then
          echo "ERROR: Traefik at $IP did not respond with 404 on port 80 within $TIMEOUT seconds"
          exit 1
        fi
      done
      
      echo "All Traefik instances are fully ready!"
    EOF
  }

  depends_on = [module.ec2]
}

