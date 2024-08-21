data "aws_caller_identity" "current" {}

locals {
  grid        = "shoora-eks-${var.env}"
  oidc_string = trimprefix(module.eks.cluster_oidc_issuer_url, "https://")
}

data "aws_kms_key" "shoora" {
  key_id = "alias/${var.shoora_kms_key_alias}"
}

data "aws_ami" "eks_default" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-1.30-v20240605"]
  }
}

data "aws_iam_policy_document" "vpc_flow_logs_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "vpc_flow_logs_log_group" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role" "shoora_vpc_flow_logs" {
  name               = "${local.grid}-vpc-flow-logs"
  assume_role_policy = data.aws_iam_policy_document.vpc_flow_logs_assume_role.json
}

resource "aws_iam_role_policy" "shoora_vpc_flow_logs" {
  name   = "${local.grid}-vpc-flow-logs"
  role   = aws_iam_role.shoora_vpc_flow_logs.id
  policy = data.aws_iam_policy_document.vpc_flow_logs_log_group.json
}

module "vpc" {
  source = "../../modules/vpc"

  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  subnet_tag = local.grid

  private_subnet_enabled = true

  log_group_prefix       = "${local.grid}-"
  vpc_log_iam_role_arn   = aws_iam_role.shoora_vpc_flow_logs.arn
  aws_availability_zones = var.aws_availability_zones

  tags = {
    Name      = "${local.grid}"
    Env       = var.env
    Terraform = "true"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "karpenter.sh/discovery"          = "${local.grid}"
  }
}

module "eks" {
  source = "../../modules/eks"

  cluster_name                            = local.grid
  vpc_id                                  = module.vpc.vpc_id
  create_iam_role                         = true
  iam_role_name                           = format("%s-eks-master-role", local.grid)
  iam_role_use_name_prefix                = var.eks_iam_role_use_name_prefix
  cluster_version                         = var.cluster_version
  cluster_enabled_log_types               = var.cluster_enabled_log_types
  subnet_ids                              = [module.vpc.private_subnet_id[0], module.vpc.private_subnet_id[1], module.vpc.private_subnet_id[2]]
  cluster_endpoint_private_access         = var.cluster_endpoint_private_access
  cluster_endpoint_public_access          = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs    = var.cluster_endpoint_public_access_cidrs
  cluster_security_group_additional_rules = var.cluster_security_group_additional_rules
  cluster_security_group_use_name_prefix  = var.cluster_security_group_use_name_prefix
  cloudwatch_log_group_retention_in_days  = var.cloudwatch_log_group_retention_in_days
  enable_irsa                             = var.create_oidc_provider_eks

  cluster_encryption_config = [
    {
      provider_key_arn = data.aws_kms_key.shoora.arn
      resources        = ["secrets"]
    }
  ]

  create_node_security_group           = true
  node_security_group_additional_rules = var.node_security_group_additional_rules
  node_security_group_use_name_prefix  = var.node_security_group_use_name_prefix

  tags = var.tags
}

resource "aws_iam_role" "eks_node_role" {
  name               = format("%s-eks-node-role", local.grid)
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "eks_node_role_policy_attachment" {
  count = length(var.eks_node_policies)

  policy_arn = var.eks_node_policies[count.index]
  role       = aws_iam_role.eks_node_role.name
}

module "eks_managed_node_group" {
  source = "../../modules/eks/modules/eks-managed-node-group"

  for_each = { for k, v in var.eks_managed_node_groups : k => v }

  ## User Data
  cluster_name               = module.eks.cluster_id
  cluster_endpoint           = module.eks.cluster_endpoint
  cluster_auth_base64        = module.eks.cluster_certificate_authority_data
  enable_bootstrap_user_data = true
  pre_bootstrap_user_data    = try(each.value.pre_bootstrap_user_data, var.eks_managed_node_group_defaults.pre_bootstrap_user_data, "")
  bootstrap_extra_args       = try(each.value.bootstrap_extra_args, var.eks_managed_node_group_defaults.bootstrap_extra_args, "")

  ## Launch Template
  create_launch_template      = try(each.value.create_launch_template, var.eks_managed_node_group_defaults.create_launch_template, false)
  launch_template_name        = try(each.value.launch_template_name, format("%s-%s", local.grid, each.key))
  launch_template_version     = try(each.value.launch_template_version, var.eks_managed_node_group_defaults.launch_template_version, "$Default")
  launch_template_description = try(each.value.launch_template_description, var.eks_managed_node_group_defaults.launch_template_description, null)

  ebs_optimized   = try(each.value.ebs_optimized, var.eks_managed_node_group_defaults.ebs_optimized, true)
  ami_id          = data.aws_ami.eks_default.image_id
  key_name        = try(each.value.key_name, var.eks_managed_node_group_defaults.key_name, null)
  cluster_version = var.cluster_version

  create_security_group                  = var.create_node_security_group
  vpc_security_group_ids                 = compact(concat([module.eks.node_security_group_id], try(each.value.vpc_security_group_ids, var.eks_managed_node_group_defaults.vpc_security_group_ids, [])))
  cluster_security_group_id              = var.create_node_security_group ? var.cluster_security_group_id : null
  update_launch_template_default_version = try(each.value.update_launch_template_default_version, var.eks_managed_node_group_defaults.update_launch_template_default_version, true)

  block_device_mappings = try(each.value.block_device_mappings, var.eks_managed_node_group_defaults.block_device_mappings, [])
  network_interfaces    = try(each.value.network_interfaces, var.eks_managed_node_group_defaults.network_interfaces, [])

  launch_template_tags = merge(
    {
      "Name" = format("%s-%s", local.grid, each.key)
    },
    try(each.value.launch_template_tags, var.eks_managed_node_group_defaults.launch_template_tags, {})
  )

  ## IAM Role
  create_iam_role = false
  iam_role_arn    = aws_iam_role.eks_node_role.arn

  ## Security Group
  vpc_id = var.create_node_security_group ? module.vpc.vpc_id : null

  ## Node Group
  name = try(each.value.node_group_name, format("%s-%s", local.grid, each.key))

  subnet_ids = try(each.value.subnet_ids, var.eks_managed_node_group_defaults.subnet_ids, [module.vpc.private_subnet_id[0], module.vpc.private_subnet_id[1], module.vpc.private_subnet_id[2]])

  min_size      = try(each.value.min_size, var.eks_managed_node_group_defaults.min_size, 1)
  desired_size  = try(each.value.desired_size, var.eks_managed_node_group_defaults.desired_size, 1)
  max_size      = try(each.value.max_size, var.eks_managed_node_group_defaults.max_size, 1)
  capacity_type = try(each.value.capacity_type, var.eks_managed_node_group_defaults.capacity_type, "ON_DEMAND")

  instance_types = try(each.value.instance_types, var.eks_managed_node_group_defaults.instance_types, null)

  labels = try(each.value.node_labels, var.eks_managed_node_group_defaults.node_labels, null)

  taints = try(each.value.node_taints, var.eks_managed_node_group_defaults.node_taints, {})

  ## Below tag applies to both launch template and node group if specified
  tags = merge(var.tags, try(each.value.tags, var.eks_managed_node_group_defaults.tags, {}))

  depends_on = [
    module.eks
  ]
}

resource "aws_security_group" "shoora" {
  name   = format("%s-vpn-sg", local.grid)
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group_rule" "ingress_rule" {
  for_each = var.shoora_vpn_ingress_rule

  type                     = "ingress"
  description              = each.value.description
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  self                     = try(each.value.self, null)
  cidr_blocks              = try(each.value.cidr_blocks, null)
  source_security_group_id = try(each.value.source_security_group_id, null)
  security_group_id        = aws_security_group.shoora.id
}

resource "aws_security_group_rule" "egress_rule" {
  for_each = var.shoora_vpn_egress_rule

  type                     = "egress"
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = try(each.value.cidr_blocks, null)
  source_security_group_id = try(each.value.source_security_group_id, null)
  security_group_id        = aws_security_group.shoora.id
}

module "codebuild" {
  source = "../../modules/codebuild"

  for_each = var.codebuild_projects

  codebuild_iam_role_name       = format("%s-codebuild-role", each.key)
  codebuild_project_name        = each.key
  codebuild_project_description = "Managed by Terraform"

  environment_compute_type = each.value.environment_compute_type

  environment_variable = [
    {
      name  = "REPOSITORY_URI"
      value = "211125700310.dkr.ecr.ap-southeast-1.amazonaws.com/${each.key}"
      type  = "PLAINTEXT"
    },
    {
      name  = "AWS_REGION"
      value = "ap-southeast-1"
      type  = "PLAINTEXT"
    },
    {
      name  = "AWS_ACCOUNT_ID"
      value = "211125700310"
      type  = "PLAINTEXT"
    },
    {
      name  = "EKS_CLUSTER_NAME"
      value = "shoora-eks-prod"
      type  = "PLAINTEXT"
    },
    {
      name  = "ROLE_ARN"
      value = "arn:aws:iam::211125700310:role/AI-Studio-Assume-Role"
      type  = "PLAINTEXT"
    },
    {
      name  = "HELM_RELEASE_NAME"
      value = each.key
      type  = "PLAINTEXT"
    }
  ]

  codebuild_source         = each.value.codebuild_source
  codebuild_source_version = each.value.codebuild_source_version

  vpc_config = [
    {
      vpc_id             = module.vpc.vpc_id
      subnets            = [module.vpc.private_subnet_id[0], module.vpc.private_subnet_id[1], module.vpc.private_subnet_id[2]]
      security_group_ids = [module.eks.node_security_group_id, module.eks.cluster_security_group_id]
    }
  ]

  tags = {
    Name      = each.key
    Terraform = "true"
  }
}

module "ecr" {
  source = "../../modules/ecr"

  for_each = var.codebuild_projects

  ecr_repository_name = each.key
}

module "secret_manager" {
  source = "../../modules/secret-manager"

  for_each = var.codebuild_projects

  secret_manager_name = each.key

  tags = {
    Name      = each.key
    Terraform = "true"
  }
}