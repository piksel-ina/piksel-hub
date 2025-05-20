output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.this.name
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.this.arn
}

output "ecr_repository_url" {
  description = "URL of the ECR repository for Docker push/pull"
  value       = aws_ecr_repository.this.repository_url
}

output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}

output "eks_ecr_access_role_arn" {
  description = "ARN of the IAM role for EKS ECR access"
  value       = aws_iam_role.eks_ecr_access.arn
}

output "github_oidc_provider_arn" {
  description = "ARN of the OIDC provider for GitHub Actions"
  value       = aws_iam_openid_connect_provider.github.arn
}

