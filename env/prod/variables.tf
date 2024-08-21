variable "region" {
  type    = string
  default = ""
}

variable "vpc_cidr_block" {
  type    = string
  default = ""
}

variable "domain" {
  type    = string
  default = ""
}

variable "certificate_arn" {
  type    = string
  default = ""
}

variable "zone_id" {
  type    = string
  default = ""
}

variable "aws_availability_zones" {
  type    = list(string)
  default = [""]
}

variable "profile" {
  type    = string
  default = ""
}

variable "elb_account_id" {
  type    = string
  default = ""
}

variable "shoora_frontend_env" {
  type    = any
  default = {}
}

variable "env" {
  type    = string
  default = ""
}

variable "eks_iam_role_use_name_prefix" {
  default = false
  type    = bool
}

variable "cluster_version" {
  default = ""
  type    = string
}

variable "shoora_kms_key_alias" {
  type    = string
  default = ""
}

variable "cluster_enabled_log_types" {
  default = [""]
  type    = list(string)
}

variable "cluster_security_group_use_name_prefix" {
  default = false
  type    = bool
}

variable "cluster_endpoint_private_access" {
  default = false
  type    = bool
}

variable "cluster_endpoint_public_access" {
  default = false
  type    = bool
}

variable "cluster_endpoint_public_access_cidrs" {
  default = ["0.0.0.0/0"]
  type    = list(string)
}

variable "cluster_security_group_additional_rules" {
  default = {}
  type    = any
}

variable "node_security_group_use_name_prefix" {
  default = false
  type    = bool
}

variable "node_security_group_additional_rules" {
  default = {}
  type    = any
}

variable "cloudwatch_log_group_retention_in_days" {
  default = 7
  type    = number
}

variable "create_oidc_provider_eks" {
  default = false
  type    = bool
}

variable "cluster_name" {
  default = ""
  type    = string
}

variable "create_node_security_group" {
  default = false
  type    = bool
}

variable "cluster_security_group_id" {
  default = ""
  type    = string
}

variable "ami_id" {
  default = ""
  type    = string
}

variable "eks_managed_node_group_defaults" {
  default = {}
  type    = any
}

variable "eks_managed_node_groups" {
  default = {}
  type    = any
}

variable "eks_node_policies" {
  default = [""]
  type    = list(string)
}

variable "shoora_vpn_ingress_rule" {
  default = {}
  type    = any
}

variable "shoora_vpn_egress_rule" {
  default = {}
  type    = any
}

variable "codebuild_projects" {
  default = {}
  type    = any
}

variable "tags" {
  default = {}
  type    = map(string)
}
