# --- Data Source ---
output "account_id" {
  description = "The AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

# --- Outputs for the zones ---
output "route53_zone_zone_id" {
  description = "Zone ID of Route53 zones"
  value       = module.zones.route53_zone_zone_id
}

output "route53_zone_zone_arn" {
  description = "Zone ARN of Route53 zones"
  value       = module.zones.route53_zone_zone_arn
}

output "route53_zone_name_servers" {
  description = "Name servers of Route53 zones"
  value       = module.zones.route53_zone_name_servers
}

output "staging_zone_id" {
  description = "Zone ID for staging.pik-sel.id"
  value       = module.zones.route53_zone_zone_id["staging.pik-sel.id"]
}

output "production_zone_id" {
  description = "Zone ID for pik-sel.id"
  value       = module.zones.route53_zone_zone_id["pik-sel.id"]
}

output "staging_name_servers" {
  description = "Name servers for staging.pik-sel.id"
  value       = module.zones.route53_zone_name_servers["staging.pik-sel.id"]
}

output "production_name_servers" {
  description = "Name servers for pik-sel.id"
  value       = module.zones.route53_zone_name_servers["pik-sel.id"]
}


output "externaldns_crossaccount_role_arns" {
  description = "Map of environment to ExternalDNS cross-account IAM role ARNs"
  value       = module.irsa-externaldns.externaldns_crossaccount_role_arns
}

output "cross_account_route53_policy_policy_arns" {
  description = "Map of environment to ExternalDNS Route53 policy ARNs"
  value       = module.irsa-externaldns.cross_account_route53_policy_policy_arns
}

output "odc_cloudfront_crossaccount_role_arns" {
  description = "Map of environment to ODC CloudFront cross-account IAM role ARNs"
  value       = module.irsa-externaldns.odc_cloudfront_crossaccount_role_arns
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = module.ecr.ecr_repository_name
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = module.ecr.ecr_repository_arn
}

output "ecr_repository_url" {
  description = "URL of the ECR repository for Docker push/pull"
  value       = module.ecr.ecr_repository_url
}

output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions"
  value       = module.ecr.github_actions_role_arn
}

output "eks_ecr_access_role_arn" {
  description = "ARN of the IAM role for EKS ECR access"
  value       = module.ecr.eks_ecr_access_role_arn
}

output "github_oidc_provider_arn" {
  description = "ARN of the OIDC provider for GitHub Actions"
  value       = module.ecr.github_oidc_provider_arn
}

