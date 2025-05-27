locals {
  tags            = var.default_tags
  current_account = var.current_account_id
  ecr_principals  = [for account_id in values(var.account_ids) : "arn:aws:iam::${account_id}:root"]
  project         = lower(var.project)
}

# --- AWS Elastic Container Registry Configurations ---
resource "aws_ecr_repository" "this" {
  name                 = var.github-repo
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = local.tags
}

# --- AWS ECR Lifecycle Policy ---
resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name
  policy = jsonencode({
    rules = [
      // --- Production and Staging Images rule priority 1 to 20 ---
      {
        rulePriority = 1,
        description  = "Keep last 15 ODC prod/staging images (vX.Y.Z, vX.Y.Z-betaN)",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["odc-v"],
          countType     = "imageCountMoreThan",
          countNumber   = 15
        },
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2,
        description  = "Keep last 10 Jupyter prod/staging images (vX.Y.Z, vX.Y.Z-betaN)",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["jupyter-v"],
          countType     = "imageCountMoreThan",
          countNumber   = 10
        },
        action = {
          type = "expire"
        }
      },

      // --- Development Images rule priority 21 to 40 ---
      {
        rulePriority = 21,
        description  = "Expire ODC dev branch images not updated in 45 days",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["odc-feature-", "odc-develop-", "odc-main-", "odc-dev-"],
          countType     = "sinceImagePushed",
          countUnit     = "days",
          countNumber   = 45
        },
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 22,
        description  = "Expire Jupyter dev branch images not updated in 30 days",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["jupyter-feature-", "jupyter-develop-", "jupyter-main-", "jupyter-dev-"],
          countType     = "sinceImagePushed",
          countUnit     = "days",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      },

      // --- Other rules ---
      {
        rulePriority = 90
        description  = "Expire untagged images older than 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 99, # Ensure this is the last rule
        description  = "Expire any other tagged images not matching above rules after 60 days",
        selection = {
          tagStatus      = "tagged",
          tagPatternList = ["*"],
          countType      = "sinceImagePushed",
          countUnit      = "days",
          countNumber    = 60
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# --- ECR Repository Policy for Cross Account Access ---
resource "aws_ecr_repository_policy" "this" {
  repository = aws_ecr_repository.this.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GithubActionsAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.current_account}:role/${local.project}-ecr-github-actions"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages"
        ]
      },
      {
        Sid    = "EKSNodeAccess"
        Effect = "Allow"
        Principal = {
          AWS = local.ecr_principals
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })
}

# --- OIDC Provider for Github Actions ---
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  tags = local.tags
}

# --- IAM Role for GitHub Actions with OIDC trust policy ---
resource "aws_iam_role" "github_actions" {
  name = "${local.project}-ecr-github-actions"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github-org}/${var.github-repo}:*"
          }
        }
      }
    ]
  })

  tags = local.tags
}

# --- IAM Policy for GitHub Actions ECR access ---
resource "aws_iam_policy" "github_actions" {
  name = "${local.project}-github-actions-ecr-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages"
        ]
        Resource = aws_ecr_repository.this.arn
      }
    ]
  })

  tags = local.tags
}

# --- Attach policy to GitHub Actions role ---
resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}

# --- IAM Role for EKS ECR access ---
resource "aws_iam_role" "eks_ecr_access" {
  name = "${local.project}-eks-ecr-access"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.tags
}

# --- IAM Policy for EKS ECR read-only access --- 
resource "aws_iam_policy" "eks_ecr_access" {
  name = "${local.project}-eks-ecr-access-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken"
        ]
        Resource = aws_ecr_repository.this.arn
      }
    ] }
  )
}

# --- IAM Role Policy Attachment ---
resource "aws_iam_role_policy_attachment" "eks_ecr_access" {
  role       = aws_iam_role.eks_ecr_access.name
  policy_arn = aws_iam_policy.eks_ecr_access.arn
}
