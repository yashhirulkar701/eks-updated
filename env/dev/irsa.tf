resource "aws_iam_role" "aws_ebs_csi_driver_role" {
  name               = format("%s-aws-ebs-csi-role", local.grid)
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${module.eks.oidc_provider_arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${local.oidc_string}:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }
  ]
}
EOF
  description        = "Allows EBS CSI Driver ServiceAccount to access below policy."

  depends_on = [
    module.eks
  ]
}

resource "aws_iam_role_policy" "aws_ebs_csi_driver_role_policy" {
  name   = "AmazonEKS_EBS_CSI_Driver_Policy"
  role   = aws_iam_role.aws_ebs_csi_driver_role.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateSnapshot",
        "ec2:AttachVolume",
        "ec2:DetachVolume",
        "ec2:ModifyVolume",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DescribeVolumesModifications"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateTags"
      ],
      "Resource": [
        "arn:aws:ec2:*:*:volume/*",
        "arn:aws:ec2:*:*:snapshot/*"
      ],
      "Condition": {
        "StringEquals": {
          "ec2:CreateAction": [
            "CreateVolume",
            "CreateSnapshot"
          ]
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteTags"
      ],
      "Resource": [
        "arn:aws:ec2:*:*:volume/*",
        "arn:aws:ec2:*:*:snapshot/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/ebs.csi.aws.com/cluster": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/CSIVolumeName": "*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/kubernetes.io/cluster/*": "owned"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/CSIVolumeName": "*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/kubernetes.io/cluster/*": "owned"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteSnapshot"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/CSIVolumeSnapshotName": "*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteSnapshot"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
        }
      }
    }
  ]
}
EOF

  depends_on = [
    module.eks
  ]
}

# resource "aws_iam_role" "karpenter_irsa_role" {
#   name               = format("%s-karpenter-irsa-role", local.grid)
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Federated": "${module.eks.oidc_provider_arn}"
#       },
#       "Action": "sts:AssumeRoleWithWebIdentity",
#       "Condition": {
#         "StringEquals": {
#           "${local.oidc_string}:sub": "system:serviceaccount:karpenter:karpenter"
#         }
#       }
#     }
#   ]
# }
# EOF
#   description        = "Allows Karpenter ServiceAccount to access below policy."

#   depends_on = [
#     module.eks
#   ]
# }

# resource "aws_iam_role_policy" "karpenter_irsa_role_policy" {
#   name   = "Karpenter_Policy"
#   role   = aws_iam_role.karpenter_irsa_role.name
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "ec2:CreateFleet",
#         "ec2:CreateLaunchTemplate",
#         "ec2:CreateTags",
#         "ec2:DescribeAvailabilityZones",
#         "ec2:DescribeImages",
#         "ec2:DescribeInstances",
#         "ec2:TerminateInstances",
#         "ec2:RunInstances",
#         "ec2:DescribeInstanceTypeOfferings",
#         "ec2:DescribeInstanceTypes",
#         "ec2:DescribeLaunchTemplates",
#         "ec2:DescribeSecurityGroups",
#         "ec2:DescribeSpotPriceHistory",
#         "ec2:DescribeSubnets",
#         "ec2:DeleteLaunchTemplate",
#         "pricing:GetProducts",
#         "ssm:GetParameter",
#         "eks:DescribeCluster",
#         "kms:*"
#       ],
#       "Resource": "*"
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "iam:PassRole"
#       ],
#       "Resource": [
#         "${aws_iam_role.eks_node_role.arn}"
#       ]
#     }
#   ]
# }
# EOF

#   depends_on = [
#     module.eks
#   ]
# }

# resource "aws_iam_role" "shoora_backend_dev_irsa_role" {
#   name               = format("%s-shoora-backend-dev-irsa-role", local.grid)
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Federated": "${module.eks.oidc_provider_arn}"
#       },
#       "Action": "sts:AssumeRoleWithWebIdentity",
#       "Condition": {
#         "StringLike": {
#           "${local.oidc_string}:sub": "system:serviceaccount:dev:*"
#         }
#       }
#     }
#   ]
# }
# EOF
#   description        = "Allows AI-Studio Dev NS ServiceAccount to access below policy."

#   depends_on = [
#     module.eks
#   ]
# }

# resource "aws_iam_role_policy" "shoora_backend_dev_irsa_role_policy" {
#   name   = "shoora_Backend_Dev_Policy"
#   role   = aws_iam_role.shoora_backend_dev_irsa_role.name
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "kms:Decrypt"
#       ],
#       "Resource": "arn:aws:kms:ap-southeast-1:211125700310:key/657e574f-0ba1-4cb0-b95a-0ebe3f8a3b4f"
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "secretsmanager:GetSecretValue",
#         "secretsmanager:DescribeSecret"
#       ],
#       "Resource": [
#         "arn:aws:secretsmanager:ap-southeast-1:211125700310:secret:*"
#       ]
#     }
#   ]
# }
# EOF

#   depends_on = [
#     module.eks
#   ]
# }

# resource "aws_iam_role" "shoora_backend_staging_irsa_role" {
#   name               = format("%s-shoora-backend-staging-irsa-role", local.grid)
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Federated": "${module.eks.oidc_provider_arn}"
#       },
#       "Action": "sts:AssumeRoleWithWebIdentity",
#       "Condition": {
#         "StringLike": {
#           "${local.oidc_string}:sub": "system:serviceaccount:staging:*"
#         }
#       }
#     }
#   ]
# }
# EOF
#   description        = "Allows AI-Studio Staging NS ServiceAccount to access below policy."

#   depends_on = [
#     module.eks
#   ]
# }

# resource "aws_iam_role_policy" "shoora_backend_staging_irsa_role_policy" {
#   name   = "shoora_Backend_Staging_Policy"
#   role   = aws_iam_role.shoora_backend_staging_irsa_role.name
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "kms:Decrypt"
#       ],
#       "Resource": "arn:aws:kms:ap-southeast-1:211125700310:key/657e574f-0ba1-4cb0-b95a-0ebe3f8a3b4f"
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "secretsmanager:GetSecretValue",
#         "secretsmanager:DescribeSecret"
#       ],
#       "Resource": [
#         "arn:aws:secretsmanager:ap-southeast-1:211125700310:secret:*"
#       ]
#     }
#   ]
# }
# EOF

#   depends_on = [
#     module.eks
#   ]
# }

# resource "aws_iam_role" "shoora_frontend_dev_irsa_role" {
#   name               = format("%s-shoora-frontend-dev-irsa-role", local.grid)
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Federated": "${module.eks.oidc_provider_arn}"
#       },
#       "Action": "sts:AssumeRoleWithWebIdentity",
#       "Condition": {
#         "StringLike": {
#           "${local.oidc_string}:sub": "system:serviceaccount:dev:*"
#         }
#       }
#     }
#   ]
# }
# EOF
#   description        = "Allows AI-Studio Dev NS ServiceAccount to access below policy."

#   depends_on = [
#     module.eks
#   ]
# }

# resource "aws_iam_role_policy" "shoora_frontend_dev_irsa_role_policy" {
#   name   = "shoora_Frontend_Dev_Policy"
#   role   = aws_iam_role.shoora_frontend_dev_irsa_role.name
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "kms:Decrypt"
#       ],
#       "Resource": "arn:aws:kms:ap-southeast-1:211125700310:key/657e574f-0ba1-4cb0-b95a-0ebe3f8a3b4f"
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "secretsmanager:GetSecretValue",
#         "secretsmanager:DescribeSecret"
#       ],
#       "Resource": [
#         "arn:aws:secretsmanager:ap-southeast-1:211125700310:secret:*"
#       ]
#     },
#     {
# 			"Action": "s3:*",
# 			"Effect": "Allow",
# 			"Resource": [
# 				"arn:aws:s3:::shoora-dataset",
# 				"arn:aws:s3:::shoora-dataset/*"
# 			]
# 		}
#   ]
# }
# EOF

#   depends_on = [
#     module.eks
#   ]
# }

# resource "aws_iam_role" "shoora_frontend_staging_irsa_role" {
#   name               = format("%s-shoora-frontend-staging-irsa-role", local.grid)
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Federated": "${module.eks.oidc_provider_arn}"
#       },
#       "Action": "sts:AssumeRoleWithWebIdentity",
#       "Condition": {
#         "StringLike": {
#           "${local.oidc_string}:sub": "system:serviceaccount:staging:*"
#         }
#       }
#     }
#   ]
# }
# EOF
#   description        = "Allows AI-Studio Staging NS ServiceAccount to access below policy."

#   depends_on = [
#     module.eks
#   ]
# }

# resource "aws_iam_role_policy" "shoora_frontend_staging_irsa_role_policy" {
#   name   = "shoora_Frontend_Staging_Policy"
#   role   = aws_iam_role.shoora_frontend_staging_irsa_role.name
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "kms:Decrypt"
#       ],
#       "Resource": "arn:aws:kms:ap-southeast-1:211125700310:key/657e574f-0ba1-4cb0-b95a-0ebe3f8a3b4f"
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "secretsmanager:GetSecretValue",
#         "secretsmanager:DescribeSecret"
#       ],
#       "Resource": [
#         "arn:aws:secretsmanager:ap-southeast-1:211125700310:secret:*"
#       ]
#     },
#     {
# 			"Action": "s3:*",
# 			"Effect": "Allow",
# 			"Resource": [
# 				"arn:aws:s3:::shoora-dataset",
# 				"arn:aws:s3:::shoora-dataset/*"
# 			]
# 		}
#   ]
# }
# EOF

#   depends_on = [
#     module.eks
#   ]
# }

# resource "aws_iam_role" "cloud_script_server_dev_irsa_role" {
#   name               = format("%s-cloud-script-server-dev-irsa-role", local.grid)
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Federated": "${module.eks.oidc_provider_arn}"
#       },
#       "Action": "sts:AssumeRoleWithWebIdentity",
#       "Condition": {
#         "StringLike": {
#           "${local.oidc_string}:sub": "system:serviceaccount:dev:*"
#         }
#       }
#     }
#   ]
# }
# EOF
#   description        = "Allows Cloud-Script-Server Dev NS ServiceAccount to access below policy."

#   depends_on = [
#     module.eks
#   ]
# }

# resource "aws_iam_role_policy" "cloud_script_server_dev_irsa_role_policy" {
#   name   = "Cloud_Script_Server_Dev_Policy"
#   role   = aws_iam_role.cloud_script_server_dev_irsa_role.name
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "kms:Decrypt"
#       ],
#       "Resource": "arn:aws:kms:ap-southeast-1:211125700310:key/657e574f-0ba1-4cb0-b95a-0ebe3f8a3b4f"
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "secretsmanager:GetSecretValue",
#         "secretsmanager:DescribeSecret"
#       ],
#       "Resource": [
#         "arn:aws:secretsmanager:ap-southeast-1:211125700310:secret:*"
#       ]
#     }
#   ]
# }
# EOF

#   depends_on = [
#     module.eks
#   ]
# }

# resource "aws_iam_role" "content_ai_backend_dev_irsa_role" {
#   name               = format("%s-content-ai-backend-dev-irsa-role", local.grid)
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Federated": "${module.eks.oidc_provider_arn}"
#       },
#       "Action": "sts:AssumeRoleWithWebIdentity",
#       "Condition": {
#         "StringLike": {
#           "${local.oidc_string}:sub": "system:serviceaccount:dev:*"
#         }
#       }
#     }
#   ]
# }
# EOF
#   description        = "Allows Content-AI Dev NS ServiceAccount to access below policy."

#   depends_on = [
#     module.eks
#   ]
# }

# resource "aws_iam_role_policy" "content_ai_backend_dev_irsa_role_policy" {
#   name   = "Content_Ai_Backend_Dev_Policy"
#   role   = aws_iam_role.content_ai_backend_dev_irsa_role.name
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "kms:Decrypt"
#       ],
#       "Resource": "arn:aws:kms:ap-southeast-1:211125700310:key/657e574f-0ba1-4cb0-b95a-0ebe3f8a3b4f"
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "secretsmanager:GetSecretValue",
#         "secretsmanager:DescribeSecret"
#       ],
#       "Resource": [
#         "arn:aws:secretsmanager:ap-southeast-1:211125700310:secret:*"
#       ]
#     }
#   ]
# }
# EOF

#   depends_on = [
#     module.eks
#   ]
# }

# resource "aws_iam_role" "content_ai_frontend_dev_irsa_role" {
#   name               = format("%s-content-ai-frontend-dev-irsa-role", local.grid)
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Federated": "${module.eks.oidc_provider_arn}"
#       },
#       "Action": "sts:AssumeRoleWithWebIdentity",
#       "Condition": {
#         "StringLike": {
#           "${local.oidc_string}:sub": "system:serviceaccount:dev:*"
#         }
#       }
#     }
#   ]
# }
# EOF
#   description        = "Allows Content-AI Dev NS ServiceAccount to access below policy."

#   depends_on = [
#     module.eks
#   ]
# }

# resource "aws_iam_role_policy" "content_ai_frontend_dev_irsa_role_policy" {
#   name   = "Content_Ai_Frontend_Dev_Policy"
#   role   = aws_iam_role.content_ai_frontend_dev_irsa_role.name
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "kms:Decrypt"
#       ],
#       "Resource": "arn:aws:kms:ap-southeast-1:211125700310:key/657e574f-0ba1-4cb0-b95a-0ebe3f8a3b4f"
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "secretsmanager:GetSecretValue",
#         "secretsmanager:DescribeSecret"
#       ],
#       "Resource": [
#         "arn:aws:secretsmanager:ap-southeast-1:211125700310:secret:*"
#       ]
#     }
#   ]
# }
# EOF

#   depends_on = [
#     module.eks
#   ]
# }

# resource "aws_iam_role" "ev_user_service_staging_irsa_role" {
#   name               = format("%s-ev-user-service-staging-irsa-role", local.grid)
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Federated": "${module.eks.oidc_provider_arn}"
#       },
#       "Action": "sts:AssumeRoleWithWebIdentity",
#       "Condition": {
#         "StringLike": {
#           "${local.oidc_string}:sub": "system:serviceaccount:staging:*"
#         }
#       }
#     }
#   ]
# }
# EOF
#   description        = "Allows EV User Service Staging NS ServiceAccount to access below policy."

#   depends_on = [
#     module.eks
#   ]
# }

# resource "aws_iam_role_policy" "ev_user_service_staging_irsa_role_policy" {
#   name   = "ev_user_service_staging_policy"
#   role   = aws_iam_role.ev_user_service_staging_irsa_role.name
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "kms:Decrypt"
#       ],
#       "Resource": "arn:aws:kms:ap-southeast-1:211125700310:key/657e574f-0ba1-4cb0-b95a-0ebe3f8a3b4f"
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "secretsmanager:GetSecretValue",
#         "secretsmanager:DescribeSecret"
#       ],
#       "Resource": [
#         "arn:aws:secretsmanager:ap-southeast-1:211125700310:secret:*"
#       ]
#     }
#   ]
# }
# EOF

#   depends_on = [
#     module.eks
#   ]
# }

# resource "aws_iam_role" "aws_lb_controller_irsa_role" {
#   name               = format("%s-alb-lb-controller-irsa-role", local.grid)
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Federated": "${module.eks.oidc_provider_arn}"
#       },
#       "Action": "sts:AssumeRoleWithWebIdentity",
#       "Condition": {
#         "StringEquals": {
#           "${local.oidc_string}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
#         }
#       }
#     }
#   ]
# }
# EOF
#   description        = "Allows AWS LoadBalancer Controller ServiceAccount to access below policy."

#   depends_on = [
#     module.eks
#   ]
# }

# resource "aws_iam_role_policy" "aws_lb_controller_irsa_role_policy" {
#   name   = "AWS_LoadBalancer_Controller_Policy"
#   role   = aws_iam_role.aws_lb_controller_irsa_role.name
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#           "iam:CreateServiceLinkedRole"
#       ],
#       "Resource": "*",
#       "Condition": {
#           "StringEquals": {
#               "iam:AWSServiceName": "elasticloadbalancing.amazonaws.com"
#           }
#       }
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#           "ec2:DescribeAccountAttributes",
#           "ec2:DescribeAddresses",
#           "ec2:DescribeAvailabilityZones",
#           "ec2:DescribeInternetGateways",
#           "ec2:DescribeVpcs",
#           "ec2:DescribeVpcPeeringConnections",
#           "ec2:DescribeSubnets",
#           "ec2:DescribeSecurityGroups",
#           "ec2:DescribeInstances",
#           "ec2:DescribeNetworkInterfaces",
#           "ec2:DescribeTags",
#           "ec2:GetCoipPoolUsage",
#           "ec2:DescribeCoipPools",
#           "elasticloadbalancing:DescribeLoadBalancers",
#           "elasticloadbalancing:DescribeLoadBalancerAttributes",
#           "elasticloadbalancing:DescribeListeners",
#           "elasticloadbalancing:DescribeListenerCertificates",
#           "elasticloadbalancing:DescribeSSLPolicies",
#           "elasticloadbalancing:DescribeRules",
#           "elasticloadbalancing:DescribeTargetGroups",
#           "elasticloadbalancing:DescribeTargetGroupAttributes",
#           "elasticloadbalancing:DescribeTargetHealth",
#           "elasticloadbalancing:DescribeTags"
#       ],
#       "Resource": "*"
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#           "cognito-idp:DescribeUserPoolClient",
#           "acm:ListCertificates",
#           "acm:DescribeCertificate",
#           "iam:ListServerCertificates",
#           "iam:GetServerCertificate",
#           "waf-regional:GetWebACL",
#           "waf-regional:GetWebACLForResource",
#           "waf-regional:AssociateWebACL",
#           "waf-regional:DisassociateWebACL",
#           "wafv2:GetWebACL",
#           "wafv2:GetWebACLForResource",
#           "wafv2:AssociateWebACL",
#           "wafv2:DisassociateWebACL",
#           "shield:GetSubscriptionState",
#           "shield:DescribeProtection",
#           "shield:CreateProtection",
#           "shield:DeleteProtection"
#       ],
#       "Resource": "*"
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#           "ec2:AuthorizeSecurityGroupIngress",
#           "ec2:RevokeSecurityGroupIngress"
#       ],
#       "Resource": "*"
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#           "ec2:CreateSecurityGroup"
#       ],
#       "Resource": "*"
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#           "ec2:CreateTags"
#       ],
#       "Resource": "arn:aws:ec2:*:*:security-group/*",
#       "Condition": {
#           "StringEquals": {
#               "ec2:CreateAction": "CreateSecurityGroup"
#           },
#           "Null": {
#               "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
#           }
#       }
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#           "ec2:CreateTags",
#           "ec2:DeleteTags"
#       ],
#       "Resource": "arn:aws:ec2:*:*:security-group/*",
#       "Condition": {
#           "Null": {
#               "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
#               "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
#           }
#       }
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#           "ec2:AuthorizeSecurityGroupIngress",
#           "ec2:RevokeSecurityGroupIngress",
#           "ec2:DeleteSecurityGroup"
#       ],
#       "Resource": "*",
#       "Condition": {
#           "Null": {
#               "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
#           }
#       }
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#           "elasticloadbalancing:CreateLoadBalancer",
#           "elasticloadbalancing:CreateTargetGroup"
#       ],
#       "Resource": "*",
#       "Condition": {
#           "Null": {
#               "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
#           }
#       }
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#           "elasticloadbalancing:CreateListener",
#           "elasticloadbalancing:DeleteListener",
#           "elasticloadbalancing:CreateRule",
#           "elasticloadbalancing:DeleteRule"
#       ],
#       "Resource": "*"
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#           "elasticloadbalancing:AddTags",
#           "elasticloadbalancing:RemoveTags"
#       ],
#       "Resource": [
#           "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
#           "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
#           "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
#       ],
#       "Condition": {
#           "Null": {
#               "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
#               "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
#           }
#       }
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#           "elasticloadbalancing:AddTags",
#           "elasticloadbalancing:RemoveTags"
#       ],
#       "Resource": [
#           "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
#           "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
#           "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
#           "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
#       ]
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#           "elasticloadbalancing:ModifyLoadBalancerAttributes",
#           "elasticloadbalancing:SetIpAddressType",
#           "elasticloadbalancing:SetSecurityGroups",
#           "elasticloadbalancing:SetSubnets",
#           "elasticloadbalancing:DeleteLoadBalancer",
#           "elasticloadbalancing:ModifyTargetGroup",
#           "elasticloadbalancing:ModifyTargetGroupAttributes",
#           "elasticloadbalancing:DeleteTargetGroup"
#       ],
#       "Resource": "*",
#       "Condition": {
#           "Null": {
#               "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
#           }
#       }
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#           "elasticloadbalancing:AddTags"
#       ],
#       "Resource": [
#           "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
#           "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
#           "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
#       ],
#       "Condition": {
#           "StringEquals": {
#               "elasticloadbalancing:CreateAction": [
#                   "CreateTargetGroup",
#                   "CreateLoadBalancer"
#               ]
#           },
#           "Null": {
#               "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
#           }
#       }
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#           "elasticloadbalancing:RegisterTargets",
#           "elasticloadbalancing:DeregisterTargets"
#       ],
#       "Resource": "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#           "elasticloadbalancing:SetWebAcl",
#           "elasticloadbalancing:ModifyListener",
#           "elasticloadbalancing:AddListenerCertificates",
#           "elasticloadbalancing:RemoveListenerCertificates",
#           "elasticloadbalancing:ModifyRule"
#       ],
#       "Resource": "*"
#     }
#   ]
# }
# EOF

#   depends_on = [
#     module.eks
#   ]
# }

# resource "aws_iam_role" "ev_auth_service_staging_irsa_role" {
#   name               = format("%s-ev-auth-service-staging-irsa-role", local.grid)
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Federated": "${module.eks.oidc_provider_arn}"
#       },
#       "Action": "sts:AssumeRoleWithWebIdentity",
#       "Condition": {
#         "StringLike": {
#           "${local.oidc_string}:sub": "system:serviceaccount:staging:*"
#         }
#       }
#     }
#   ]
# }
# EOF
#   description        = "Allows EV Auth Service Staging NS ServiceAccount to access below policy."

#   depends_on = [
#     module.eks
#   ]
# }

# resource "aws_iam_role_policy" "ev_auth_service_staging_irsa_role_policy" {
#   name   = "ev_auth_service_staging_policy"
#   role   = aws_iam_role.ev_auth_service_staging_irsa_role.name
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "kms:Decrypt"
#       ],
#       "Resource": "arn:aws:kms:ap-southeast-1:211125700310:key/657e574f-0ba1-4cb0-b95a-0ebe3f8a3b4f"
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "secretsmanager:GetSecretValue",
#         "secretsmanager:DescribeSecret"
#       ],
#       "Resource": [
#         "arn:aws:secretsmanager:ap-southeast-1:211125700310:secret:*"
#       ]
#     }
#   ]
# }
# EOF

#   depends_on = [
#     module.eks
#   ]
# }

# resource "aws_iam_role" "ev_notification_service_staging_irsa_role" {
#   name               = format("%s-ev-notification-service-staging-irsa-role", local.grid)
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Federated": "${module.eks.oidc_provider_arn}"
#       },
#       "Action": "sts:AssumeRoleWithWebIdentity",
#       "Condition": {
#         "StringLike": {
#           "${local.oidc_string}:sub": "system:serviceaccount:staging:*"
#         }
#       }
#     }
#   ]
# }
# EOF
#   description        = "Allows EV Notification Service Staging NS ServiceAccount to access below policy."

#   depends_on = [
#     module.eks
#   ]
# }

# resource "aws_iam_role_policy" "ev_notification_service_staging_irsa_role_policy" {
#   name   = "ev_notification_service_staging_policy"
#   role   = aws_iam_role.ev_notification_service_staging_irsa_role.name
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "kms:Decrypt"
#       ],
#       "Resource": "arn:aws:kms:ap-southeast-1:211125700310:key/657e574f-0ba1-4cb0-b95a-0ebe3f8a3b4f"
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "secretsmanager:GetSecretValue",
#         "secretsmanager:DescribeSecret"
#       ],
#       "Resource": [
#         "arn:aws:secretsmanager:ap-southeast-1:211125700310:secret:*"
#       ]
#     }
#   ]
# }
# EOF

#   depends_on = [
#     module.eks
#   ]
# }

# #---------------

# resource "aws_iam_role" "shoora_pycompiler_dev_irsa_role" {
#   name               = format("%s-shoora-pycompiler-dev-irsa-role", local.grid)
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Federated": "${module.eks.oidc_provider_arn}"
#       },
#       "Action": "sts:AssumeRoleWithWebIdentity",
#       "Condition": {
#         "StringLike": {
#           "${local.oidc_string}:sub": "system:serviceaccount:dev:*"
#         }
#       }
#     }
#   ]
# }
# EOF
#   description        = "Allows shoora pycompiler Dev NS ServiceAccount to access below policy."

#   depends_on = [
#     module.eks
#   ]
# }

# resource "aws_iam_role_policy" "shoora_pycompiler_dev_irsa_role_policy" {
#   name   = "shoora_pycompiler_dev_policy"
#   role   = aws_iam_role.shoora_pycompiler_dev_irsa_role.name
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "kms:Decrypt"
#       ],
#       "Resource": "arn:aws:kms:ap-southeast-1:211125700310:key/657e574f-0ba1-4cb0-b95a-0ebe3f8a3b4f"
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "secretsmanager:GetSecretValue",
#         "secretsmanager:DescribeSecret"
#       ],
#       "Resource": [
#         "arn:aws:secretsmanager:ap-southeast-1:211125700310:secret:*"
#       ]
#     }
#   ]
# }
# EOF

#   depends_on = [
#     module.eks
#   ]
# }

# resource "aws_iam_role" "lets_connect_backend_dev_irsa_role" {
#   name               = format("%s-lets-connect-backend-dev-irsa-role", local.grid)
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Federated": "${module.eks.oidc_provider_arn}"
#       },
#       "Action": "sts:AssumeRoleWithWebIdentity",
#       "Condition": {
#         "StringLike": {
#           "${local.oidc_string}:sub": "system:serviceaccount:dev:*"
#         }
#       }
#     }
#   ]
# }
# EOF
#   description        = "Allows Lets Connect Backend Dev NS ServiceAccount to access below policy."

#   depends_on = [
#     module.eks
#   ]
# }

# resource "aws_iam_role_policy" "lets_connect_backend_dev_irsa_role_policy" {
#   name   = "lets_connect_backend_dev_policy"
#   role   = aws_iam_role.lets_connect_backend_dev_irsa_role.name
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "kms:Decrypt"
#       ],
#       "Resource": "arn:aws:kms:ap-southeast-1:211125700310:key/657e574f-0ba1-4cb0-b95a-0ebe3f8a3b4f"
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "secretsmanager:GetSecretValue",
#         "secretsmanager:DescribeSecret"
#       ],
#       "Resource": [
#         "arn:aws:secretsmanager:ap-southeast-1:211125700310:secret:*"
#       ]
#     }
#   ]
# }
# EOF

#   depends_on = [
#     module.eks
#   ]
# }

# resource "aws_iam_role" "ev_api_gateway_staging_irsa_role" {
#   name               = format("%s-ev-api-gateway-staging-irsa-role", local.grid)
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Federated": "${module.eks.oidc_provider_arn}"
#       },
#       "Action": "sts:AssumeRoleWithWebIdentity",
#       "Condition": {
#         "StringLike": {
#           "${local.oidc_string}:sub": "system:serviceaccount:staging:*"
#         }
#       }
#     }
#   ]
# }
# EOF
#   description        = "Allows EV API Gateway Staging NS ServiceAccount to access below policy."

#   depends_on = [
#     module.eks
#   ]
# }

# resource "aws_iam_role_policy" "ev_api_gateway_staging_irsa_role_policy" {
#   name   = "ev_api_gateway_staging_policy"
#   role   = aws_iam_role.ev_api_gateway_staging_irsa_role.name
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "kms:Decrypt"
#       ],
#       "Resource": "arn:aws:kms:ap-southeast-1:211125700310:key/657e574f-0ba1-4cb0-b95a-0ebe3f8a3b4f"
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "secretsmanager:GetSecretValue",
#         "secretsmanager:DescribeSecret"
#       ],
#       "Resource": [
#         "arn:aws:secretsmanager:ap-southeast-1:211125700310:secret:*"
#       ]
#     }
#   ]
# }
# EOF

#   depends_on = [
#     module.eks
#   ]
# }
