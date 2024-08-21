## EKS Cluster Outputs

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = module.eks.cluster_arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = module.eks.cluster_endpoint
}

output "cluster_id" {
  description = "The name/id of the EKS cluster"
  value       = module.eks.cluster_id
}

output "cluster_version" {
  description = "EKS cluster version"
  value       = var.cluster_version
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

output "cluster_primary_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster"
  value       = module.eks.cluster_primary_security_group_id
}

output "cluster_security_group_id" {
  description = "ID of the cluster security group"
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "ID of the node shared security group"
  value       = module.eks.node_security_group_id
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if `enable_irsa = true`"
  value       = module.eks.oidc_provider_arn
}

output "aws_ebs_csi_driver_role_arn" {
  description = "AWS EBS CSI Driver IAM Role ARN for ServiceAccount"
  value       = aws_iam_role.aws_ebs_csi_driver_role.arn
}

# output "karpenter_irsa_role_arn" {
#   description = "AWS Karpenter IAM Role ARN for ServiceAccount"
#   value       = aws_iam_role.karpenter_irsa_role.arn
# }

## EKS Managed Node Group Outputs

output "launch_template_id" {
  description = "The ID of the launch template"
  value = {
    for k, v in module.eks_managed_node_group : k => v.launch_template_id
  }
}

output "launch_template_arn" {
  description = "The ARN of the launch template"
  value = {
    for k, v in module.eks_managed_node_group : k => v.launch_template_arn
  }
}

output "launch_template_latest_version" {
  description = "The latest version of the launch template"
  value = {
    for k, v in module.eks_managed_node_group : k => v.launch_template_latest_version
  }
}

output "node_group_id" {
  description = "The node group id"
  value = {
    for k, v in module.eks_managed_node_group : k => v.node_group_id
  }
}

output "node_group_arn" {
  description = "The ARN for this node group"
  value = {
    for k, v in module.eks_managed_node_group : k => v.node_group_arn
  }
}