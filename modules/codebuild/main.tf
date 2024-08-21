
data "aws_iam_policy_document" "codebuild_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codebuild_iam_role" {
  name               = var.codebuild_iam_role_name
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role_policy.json

  managed_policy_arns = [
    "arn:aws:iam::211125700310:policy/EKSFullAccess",
    "arn:aws:iam::211125700310:policy/STSAssumeRole",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
  ]

}

resource "aws_iam_role_policy" "codebuild_iam_role_policy" {
  role   = aws_iam_role.codebuild_iam_role.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "SidLogGroup",
      "Effect": "Allow",
      "Resource": [
        "arn:aws:logs:ap-southeast-1:211125700310:log-group:/aws/codebuild/${var.codebuild_project_name}",
        "arn:aws:logs:ap-southeast-1:211125700310:log-group:/aws/codebuild/${var.codebuild_project_name}:*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Sid": "SidCodePipelineS3",
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::codepipeline-ap-southeast-1-*"
      ],
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketAcl",
        "s3:GetBucketLocation"
      ]
    },
    {
      "Sid": "SidCodeStarConnections",
      "Effect": "Allow",
      "Resource": [
        "arn:aws:codestar-connections:ap-southeast-1:211125700310:connection*",
        "arn:aws:codeconnections:ap-southeast-1:211125700310:connection*"
      ],
      "Action": [
        "codestar-connections:UseConnection",
        "codestar-connections:GetConnection"
      ]
    },
    {
      "Sid": "SidReportGroup",
      "Effect": "Allow",
      "Action": [
        "codebuild:CreateReportGroup",
        "codebuild:CreateReport",
        "codebuild:UpdateReport",
        "codebuild:BatchPutTestCases",
        "codebuild:BatchPutCodeCoverages"
      ],
      "Resource": [
        "arn:aws:codebuild:ap-southeast-1:211125700310:report-group/${var.codebuild_project_name}-*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
          "ec2:CreateNetworkInterfacePermission"
        ],
        "Resource": "arn:aws:ec2:ap-southeast-1:211125700310:network-interface/*",
        "Condition": {
          "StringLike": {
            "ec2:Subnet": [
              "arn:aws:ec2:ap-southeast-1:211125700310:subnet/*"
            ],
            "ec2:AuthorizedService": "codebuild.amazonaws.com"
          }
        }
    }
  ]
}
EOF
}

resource "aws_codebuild_project" "codebuild_infra" {
  name           = var.codebuild_project_name
  description    = var.codebuild_project_description
  build_timeout  = "60"
  source_version = var.codebuild_source_version
  service_role   = aws_iam_role.codebuild_iam_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type    = var.environment_compute_type
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    dynamic "environment_variable" {
      for_each = var.environment_variable

      content {
        name  = try(environment_variable.value.name, null)
        value = try(environment_variable.value.value, null)
        type  = try(environment_variable.value.type, null)
      }
    }
  }

  source {
    type            = var.codebuild_source.type
    location        = var.codebuild_source.location
    buildspec       = var.codebuild_source.buildspec
    git_clone_depth = 0
  }

  logs_config {
    cloudwatch_logs {
      group_name  = format("/aws/codebuild/%s", var.codebuild_project_name)
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config

    content {
      vpc_id             = try(vpc_config.value.vpc_id, null)
      subnets            = try(vpc_config.value.subnets, null)
      security_group_ids = try(vpc_config.value.security_group_ids, null)
    }
  }

  tags = var.tags
}
