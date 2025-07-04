data "aws_availability_zones" "traefik_demo" {}

data "aws_eks_cluster_auth" "eks" {
  name = var.cluster_name
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name                 = "${var.cluster_name}-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.traefik_demo.names
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.eks_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  create_cloudwatch_log_group = false

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  node_security_group_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = null
  }
}

module "eks_node_groups" {
  source   = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version  = "~> 20.0"

  name            = "${var.cluster_name}-ng"
  cluster_name    = module.eks.cluster_name
  cluster_version = module.eks.cluster_version

  subnet_ids                        = module.vpc.private_subnets
  cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
  vpc_security_group_ids            = [module.eks.node_security_group_id]
  cluster_service_cidr              = module.eks.cluster_service_cidr

  ami_type       = var.cluster_machine_ami_type
  instance_types = [var.cluster_node_type]
  desired_size   = var.cluster_node_count
}

module "ebs_csi_controller_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.0"

  create_role                   = true
  role_name                     = "${module.eks.cluster_name}-ebs-csi-controller"
  provider_url                  = module.eks.cluster_oidc_issuer_url
  role_policy_arns              = ["arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

resource "aws_eks_addon" "traefik_demo" {
  cluster_name                = module.eks.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  resolve_conflicts_on_create = "OVERWRITE"
  service_account_role_arn    = module.ebs_csi_controller_role.iam_role_arn

  configuration_values = jsonencode({
    defaultStorageClass = {
      enabled = true
    }
  })

  depends_on = [module.eks, module.eks_node_groups]
}