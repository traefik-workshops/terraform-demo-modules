# Data source for latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  create_vpc = var.vpc_id == "" || length(var.subnet_ids) == 0 || length(var.security_group_ids) == 0

  instances = flatten([
    for app_name, app_config in var.apps : [
      for replica_idx in range(app_config.replicas) : {
        app_name       = app_name
        replica_number = replica_idx + 1
        subnet_ids     = app_config.subnet_ids
        instance_key   = "${app_name}-${replica_idx + 1}"
        port           = app_config.port
        docker_image   = app_config.docker_image
        docker_command = app_config.docker_command
        app_tags       = app_config.tags
      }
    ]
  ])
  
  # Convert to map for for_each with global index for even distribution
  instances_map = {
    for idx, inst in local.instances : inst.instance_key => merge(inst, {
      idx = idx
    })
  }
}

module "vpc" {
  count  = local.create_vpc ? 1 : 0
  source = "../vpc"

  name           = "ec2-vpc"
  cidr           = "10.0.0.0/16"
  public_subnets = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

# Create EC2 instances for each app replica
resource "aws_instance" "ec2" {
  for_each = local.instances_map
  
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = local.create_vpc ? module.vpc[0].public_subnet_ids[each.value.idx % length(module.vpc[0].public_subnet_ids)] : each.value.subnet_ids[each.value.idx % length(each.value.subnet_ids)]
  vpc_security_group_ids = local.create_vpc ? module.vpc[0].security_group_ids : var.security_group_ids
  
  # Generate user data with app-specific Docker settings
  user_data = <<-EOF
    #!/bin/bash
    set -e
    
    # Update system and install Docker
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    
    # Pull the Docker image
    docker pull ${each.value.docker_image}
    
    # Run the Docker container
    docker run -d \
      --name ${each.value.app_name}-${each.value.replica_number} \
      --restart always \
      -p ${each.value.port}:${each.value.port} \
      ${each.value.docker_command} \
      ${each.value.docker_image}
    
    # Log container status
    echo "Container ${each.value.app_name}-${each.value.replica_number} started successfully"
    docker ps
  EOF
  
  user_data_replace_on_change = true
  
  tags = merge(
    var.common_tags,
    each.value.app_tags
  )
}