locals {
  tags            = var.default_tags
  current_account = var.current_account_id
  ecr_principals  = [for account_id in values(var.account_ids) : "arn:aws:iam::${account_id}:root"]
  project         = lower(var.project)

  lifecycle_rules_by_repo = {
    for repo_name, repo_cfg in var.ecr_repos :
    repo_name => concat(
      [
        for idx, pfx in repo_cfg.tag_prefixes : {
          rulePriority = 1 + idx
          description  = "Keep last ${try(repo_cfg.keep_last, 2)} images for tags with prefix '${pfx}'"
          selection = {
            tagStatus     = "tagged"
            tagPrefixList = [pfx]
            countType     = "imageCountMoreThan"
            countNumber   = try(repo_cfg.keep_last, 2)
          }
          action = { type = "expire" }
        }
      ],
      (
        try(repo_cfg.expire_untagged_after_days, 7) > 0
        ? [{
          rulePriority = 90
          description  = "Expire untagged images older than ${try(repo_cfg.expire_untagged_after_days, 7)} days"
          selection = {
            tagStatus   = "untagged"
            countType   = "sinceImagePushed"
            countUnit   = "days"
            countNumber = try(repo_cfg.expire_untagged_after_days, 7)
          }
          action = { type = "expire" }
        }]
        : []
      )
    )
  }
}

# --- AWS Elastic Container Registry Configurations ---
resource "aws_ecr_repository" "this" {
  for_each             = var.ecr_repos
  name                 = each.key
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.tags
}

# --- AWS ECR Lifecycle Policy ---
resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = var.ecr_repos
  repository = aws_ecr_repository.this[each.key].name
  policy     = jsonencode({ rules = local.lifecycle_rules_by_repo[each.key] })
}


# --- OIDC Provider for Github Actions ---
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  tags           = local.tags
}

# --- IAM Role for GitHub Actions with OIDC trust policy ---
resource "aws_iam_role" "github_actions" {
  name = "${local.project}-ecr-github-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
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
          "token.actions.githubusercontent.com:sub" = [
            for repo in var.github_repos : "repo:${var.github_org}/${repo}:*"
          ]
        }
      }
    }]
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
        Resource = [for r in aws_ecr_repository.this : r.arn]
      }
    ]
  })

  tags = local.tags
}

# --- ECR Repository Policy for Cross Account Access  ---
resource "aws_ecr_repository_policy" "this" {
  for_each   = var.ecr_repos
  repository = aws_ecr_repository.this[each.key].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GithubActionsAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.github_actions.arn
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

# --- Attach policy to GitHub Actions role ---
resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}


# --- IAM Role for EKS ECR access (READ all repos) ---
resource "aws_iam_role" "eks_ecr_access" {
  name = "${local.project}-eks-ecr-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_policy" "eks_ecr_access" {
  name = "${local.project}-eks-ecr-access-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
        Resource = concat(
          [for r in aws_ecr_repository.this : r.arn],
          [for r in aws_ecr_repository.this : "${r.arn}/*"]
        )
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "eks_ecr_access" {
  role       = aws_iam_role.eks_ecr_access.name
  policy_arn = aws_iam_policy.eks_ecr_access.arn
}