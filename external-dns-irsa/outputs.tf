# --- The outputs ---
output "externaldns_crossaccount_role_arns" {
  description = "Map of environment to ExternalDNS cross-account IAM role ARNs"
  value       = { for k, v in aws_iam_role.externaldns_crossaccount : k => v.arn }
}

output "cross_account_route53_policy_policy_arns" {
  description = "Map of environment to ExternalDNS Route53 policy ARNs"
  value       = { for k, v in aws_iam_policy.cross_account_route53_policy : k => v.arn }
}

output "odc_cloudfront_crossaccount_role_arns" {
  description = "Map of environment to ODC CloudFront cross-account IAM role ARNs"
  value       = { for k, v in aws_iam_role.odc_cloudfront_crossaccount : k => v.arn }
}
