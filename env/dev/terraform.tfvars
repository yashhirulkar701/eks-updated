region  = "ap-south-1"
profile = "shoora_assume_role"
env     = "dev"

vpc_cidr_block = "10.1.0.0/16"

aws_availability_zones = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]

cluster_version                        = "1.30"
cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
cluster_endpoint_private_access        = true
cloudwatch_log_group_retention_in_days = 7
create_oidc_provider_eks               = true
cluster_service_ipv4_cidr              = "192.168.0.0/20"
eks_auth_mode                          = "API_AND_CONFIG_MAP"
shoora_kms_key_alias                   = "shoora-kms-key"

cluster_security_group_additional_rules = {
  allow_from_vpn_and_self = {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    type        = "ingress"
    cidr_blocks = ["10.1.0.0/16"]
    description = "Allow from VPN CIDR"
  },
  ingress_from_node = {
    description                = "Ingress all traffic from node security group"
    protocol                   = "-1"
    from_port                  = 0
    to_port                    = 65535
    type                       = "ingress"
    source_node_security_group = true
  },
  egress_to_node = {
    description                = "Egress all traffic to node security group"
    protocol                   = "-1"
    from_port                  = 0
    to_port                    = 65535
    type                       = "egress"
    source_node_security_group = true
  }
}

node_security_group_additional_rules = {
  ingress_from_cluster = {
    description                   = "Ingress all traffic from master security group"
    protocol                      = "-1"
    from_port                     = 0
    to_port                       = 65535
    type                          = "ingress"
    source_cluster_security_group = true
  },
  egress_to_cluster = {
    description                   = "Egress all traffic from master security group"
    protocol                      = "-1"
    from_port                     = 0
    to_port                       = 65535
    type                          = "egress"
    source_cluster_security_group = true
  },
  ingress_self = {
    description = "Allow node to communicate with each other"
    protocol    = "-1"
    from_port   = 0
    to_port     = 65535
    type        = "ingress"
    self        = true
  },
  egress_self = {
    description = "Allow node to communicate with each other"
    protocol    = "-1"
    from_port   = 0
    to_port     = 65535
    type        = "egress"
    self        = true
  },
  ingress_all = {
    description = "Allow inbound traffic from VPC CIDR"
    protocol    = "-1"
    from_port   = 0
    to_port     = 65535
    type        = "ingress"
    cidr_blocks = ["10.1.0.0/16"]
  },
  egress_all = {
    description = "Allow outbound traffic to all CIDRS"
    protocol    = "-1"
    from_port   = 0
    to_port     = 65535
    type        = "egress"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

eks_managed_node_group_defaults = {
  ebs_optimized                          = true
  key_name                               = "d-aws-key"
  update_launch_template_default_version = true
}

eks_node_policies = [
  "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
  "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
  "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds",
  "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
]

eks_managed_node_groups = {

  node_group_infra = {

    ## Node Group Configuration
    min_size     = 1
    desired_size = 1
    max_size     = 2

    capacity_type  = "ON_DEMAND"
    instance_types = ["t3.xlarge"]

    ## Launch Template Configuration
    create_launch_template  = true
    launch_template_version = "1"

    pre_bootstrap_user_data = <<-EOT
      if ! grep -q imageGCHighThresholdPercent /etc/kubernetes/kubelet/kubelet-config.json; 
      then 
          sed -i '/"apiVersion*/a \ \ "imageGCHighThresholdPercent": 70,' /etc/kubernetes/kubelet/kubelet-config.json
      fi
      # Inject imageGCLowThresholdPercent value unless it has already been set.
      if ! grep -q imageGCLowThresholdPercent /etc/kubernetes/kubelet/kubelet-config.json; 
      then 
          sed -i '/"imageGCHigh*/a \ \ "imageGCLowThresholdPercent": 50,' /etc/kubernetes/kubelet/kubelet-config.json
      fi
    EOT

    bootstrap_extra_args = "--kubelet-extra-args --node-labels=shoora-common=infra"

    block_device_mappings = [
      {
        device_name = "/dev/xvda"

        ebs = {
          delete_on_termination = true
          encrypted             = false
          volume_size           = 50
          volume_type           = "gp3"
        }
      }
    ]
  },
}

shoora_vpn_ingress_rule = {
  self_ingress = {
    description = "Allow all inbound traffic originating from resources in this security group"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  },
  allow_from_all = {
    protocol    = "-1"
    from_port   = 443
    to_port     = 443
    type        = "ingress"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow from all on port 443"
  },
}

shoora_vpn_egress_rule = {
  all_egress = {
    description = "Allow all outbound traffic"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
}


shoora_alb_ingress_rule = {
  allow_from_80 = {
    protocol    = "TCP"
    from_port   = 80
    to_port     = 80
    type        = "ingress"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow from all on port 80"
  }
}

shoora_alb_egress_rule = {
  all_egress = {
    description = "Allow all outbound traffic"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
}