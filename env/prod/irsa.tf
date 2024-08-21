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

resource "aws_iam_role" "karpenter_irsa_role" {
  name               = format("%s-karpenter-irsa-role", local.grid)
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
          "${local.oidc_string}:sub": "system:serviceaccount:karpenter:karpenter"
        }
      }
    }
  ]
}
EOF
  description        = "Allows Karpenter ServiceAccount to access below policy."

  depends_on = [
    module.eks
  ]
}

resource "aws_iam_role_policy" "karpenter_irsa_role_policy" {
  name   = "Karpenter_Policy"
  role   = aws_iam_role.karpenter_irsa_role.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateFleet",
        "ec2:CreateLaunchTemplate",
        "ec2:CreateTags",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeImages",
        "ec2:DescribeInstances",
        "ec2:TerminateInstances",
        "ec2:RunInstances",
        "ec2:DescribeInstanceTypeOfferings",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeLaunchTemplates",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSpotPriceHistory",
        "ec2:DescribeSubnets",
        "ec2:DeleteLaunchTemplate",
        "pricing:GetProducts",
        "ssm:GetParameter",
        "eks:DescribeCluster",
        "kms:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:PassRole"
      ],
      "Resource": [
        "${aws_iam_role.eks_node_role.arn}"
      ]
    }
  ]
}
EOF

  depends_on = [
    module.eks
  ]
}

resource "aws_iam_role" "shoora_backend_prod_irsa_role" {
  name               = format("%s-shoora-backend-prod-irsa-role", local.grid)
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
        "StringLike": {
          "${local.oidc_string}:sub": "system:serviceaccount:prod:*"
        }
      }
    }
  ]
}
EOF
  description        = "Allows AI-Studio prod NS ServiceAccount to access below policy."

  depends_on = [
    module.eks
  ]
}

resource "aws_iam_role_policy" "shoora_backend_prod_irsa_role_policy" {
  name   = "shoora_Backend_Prod_Policy"
  role   = aws_iam_role.shoora_backend_prod_irsa_role.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "arn:aws:kms:ap-southeast-1:211125700310:key/657e574f-0ba1-4cb0-b95a-0ebe3f8a3b4f"
    },
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": [
        "arn:aws:secretsmanager:ap-southeast-1:211125700310:secret:*"
      ]
    }
  ]
}
EOF

  depends_on = [
    module.eks
  ]
}

resource "aws_iam_role" "shoora_frontend_prod_irsa_role" {
  name               = format("%s-shoora-frontend-prod-irsa-role", local.grid)
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
        "StringLike": {
          "${local.oidc_string}:sub": "system:serviceaccount:prod:*"
        }
      }
    }
  ]
}
EOF
  description        = "Allows AI-Studio prod NS ServiceAccount to access below policy."

  depends_on = [
    module.eks
  ]
}

resource "aws_iam_role_policy" "shoora_frontend_prod_irsa_role_policy" {
  name   = "shoora_Frontend_Prod_Policy"
  role   = aws_iam_role.shoora_frontend_prod_irsa_role.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "arn:aws:kms:ap-southeast-1:211125700310:key/657e574f-0ba1-4cb0-b95a-0ebe3f8a3b4f"
    },
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": [
        "arn:aws:secretsmanager:ap-southeast-1:211125700310:secret:*"
      ]
    },
    {
			"Action": "s3:*",
			"Effect": "Allow",
			"Resource": [
				"arn:aws:s3:::shoora-dataset",
				"arn:aws:s3:::shoora-dataset/*"
			]
		}
  ]
}
EOF

  depends_on = [
    module.eks
  ]
}

resource "aws_iam_role" "cloud_script_server_prod_irsa_role" {
  name               = format("%s-cloud-script-server-prod-irsa-role", local.grid)
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
        "StringLike": {
          "${local.oidc_string}:sub": "system:serviceaccount:prod:*"
        }
      }
    }
  ]
}
EOF
  description        = "Allows Cloud-Script-Server Prod NS ServiceAccount to access below policy."

  depends_on = [
    module.eks
  ]
}

resource "aws_iam_role_policy" "cloud_script_server_prod_irsa_role_policy" {
  name   = "Cloud_Script_Server_Prod_Policy"
  role   = aws_iam_role.cloud_script_server_prod_irsa_role.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "arn:aws:kms:ap-southeast-1:211125700310:key/657e574f-0ba1-4cb0-b95a-0ebe3f8a3b4f"
    },
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": [
        "arn:aws:secretsmanager:ap-southeast-1:211125700310:secret:*"
      ]
    }
  ]
}
EOF

  depends_on = [
    module.eks
  ]
}

resource "aws_iam_role" "content_ai_frontend_prod_irsa_role" {
  name               = format("%s-content-ai-frontend-prod-irsa-role", local.grid)
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
        "StringLike": {
          "${local.oidc_string}:sub": "system:serviceaccount:prod:*"
        }
      }
    }
  ]
}
EOF
  description        = "Allows Content-AI-Frontend Prod NS ServiceAccount to access below policy."

  depends_on = [
    module.eks
  ]
}

resource "aws_iam_role_policy" "content_ai_frontend_prod_irsa_role_policy" {
  name   = "Content_Ai_Frontend_Prod_Policy"
  role   = aws_iam_role.content_ai_frontend_prod_irsa_role.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "arn:aws:kms:ap-southeast-1:211125700310:key/657e574f-0ba1-4cb0-b95a-0ebe3f8a3b4f"
    },
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": [
        "arn:aws:secretsmanager:ap-southeast-1:211125700310:secret:*"
      ]
    }
  ]
}
EOF

  depends_on = [
    module.eks
  ]
}

resource "aws_iam_role" "content_ai_backend_prod_irsa_role" {
  name               = format("%s-content-ai-backend-prod-irsa-role", local.grid)
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
        "StringLike": {
          "${local.oidc_string}:sub": "system:serviceaccount:prod:*"
        }
      }
    }
  ]
}
EOF
  description        = "Allows Content-AI-Backend Prod NS ServiceAccount to access below policy."

  depends_on = [
    module.eks
  ]
}

resource "aws_iam_role_policy" "content_ai_backend_prod_irsa_role_policy" {
  name   = "Content_Ai_Backend_Prod_Policy"
  role   = aws_iam_role.content_ai_backend_prod_irsa_role.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "arn:aws:kms:ap-southeast-1:211125700310:key/657e574f-0ba1-4cb0-b95a-0ebe3f8a3b4f"
    },
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": [
        "arn:aws:secretsmanager:ap-southeast-1:211125700310:secret:*"
      ]
    }
  ]
}
EOF

  depends_on = [
    module.eks
  ]
}

resource "aws_iam_role" "shoora_pycompiler_prod_irsa_role" {
  name               = format("%s-shoora-pycompiler-prod-irsa-role", local.grid)
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
        "StringLike": {
          "${local.oidc_string}:sub": "system:serviceaccount:prod:*"
        }
      }
    }
  ]
}
EOF
  description        = "Allows shoora pycompiler Production NS ServiceAccount to access below policy."

  depends_on = [
    module.eks
  ]
}

resource "aws_iam_role_policy" "shoora_pycompiler_prod_irsa_role_policy" {
  name   = "shoora_pycompiler_prod_policy"
  role   = aws_iam_role.shoora_pycompiler_prod_irsa_role.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "arn:aws:kms:ap-southeast-1:211125700310:key/657e574f-0ba1-4cb0-b95a-0ebe3f8a3b4f"
    },
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": [
        "arn:aws:secretsmanager:ap-southeast-1:211125700310:secret:*"
      ]
    }
  ]
}
EOF

  depends_on = [
    module.eks
  ]
}

resource "aws_iam_role" "lets_connect_backend_prod_irsa_role" {
  name               = format("%s-lets-connect-backend-prod-irsa-role", local.grid)
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
        "StringLike": {
          "${local.oidc_string}:sub": "system:serviceaccount:prod:*"
        }
      }
    }
  ]
}
EOF
  description        = "Allows Lets Connect Backend Prod NS ServiceAccount to access below policy."

  depends_on = [
    module.eks
  ]
}

resource "aws_iam_role_policy" "lets_connect_backend_prod_irsa_role_policy" {
  name   = "lets_connect_backend_prod_policy"
  role   = aws_iam_role.lets_connect_backend_prod_irsa_role.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "arn:aws:kms:ap-southeast-1:211125700310:key/657e574f-0ba1-4cb0-b95a-0ebe3f8a3b4f"
    },
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": [
        "arn:aws:secretsmanager:ap-southeast-1:211125700310:secret:*"
      ]
    }
  ]
}
EOF

  depends_on = [
    module.eks
  ]
}

resource "aws_iam_role" "lets_connect_ui_prod_irsa_role" {
  name               = format("%s-lets-connect-ui-prod-irsa-role", local.grid)
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
        "StringLike": {
          "${local.oidc_string}:sub": "system:serviceaccount:prod:*"
        }
      }
    }
  ]
}
EOF
  description        = "Allows Lets Connect UI Prod NS ServiceAccount to access below policy."

  depends_on = [
    module.eks
  ]
}

resource "aws_iam_role_policy" "lets_connect_ui_prod_irsa_role_policy" {
  name   = "lets_connect_ui_prod_policy"
  role   = aws_iam_role.lets_connect_ui_prod_irsa_role.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "arn:aws:kms:ap-southeast-1:211125700310:key/657e574f-0ba1-4cb0-b95a-0ebe3f8a3b4f"
    },
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": [
        "arn:aws:secretsmanager:ap-southeast-1:211125700310:secret:*"
      ]
    }
  ]
}
EOF

  depends_on = [
    module.eks
  ]
}

resource "aws_iam_role" "lets_connect_landing_ui_prod_irsa_role" {
  name               = format("%s-lets-connect-landing-ui-prod-irsa-role", local.grid)
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
        "StringLike": {
          "${local.oidc_string}:sub": "system:serviceaccount:prod:*"
        }
      }
    }
  ]
}
EOF
  description        = "Allows Lets Connect Landing UI Prod NS ServiceAccount to access below policy."

  depends_on = [
    module.eks
  ]
}

resource "aws_iam_role_policy" "lets_connect_landing_ui_prod_irsa_role_policy" {
  name   = "lets_connect_landing_ui_prod_policy"
  role   = aws_iam_role.lets_connect_landing_ui_prod_irsa_role.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "arn:aws:kms:ap-southeast-1:211125700310:key/657e574f-0ba1-4cb0-b95a-0ebe3f8a3b4f"
    },
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": [
        "arn:aws:secretsmanager:ap-southeast-1:211125700310:secret:*"
      ]
    }
  ]
}
EOF

  depends_on = [
    module.eks
  ]
}
