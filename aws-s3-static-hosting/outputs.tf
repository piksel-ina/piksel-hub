# --- S3 Outputs ---
output "docs_bucket_name" {
  description = "Name of the S3 bucket for documentation"
  value       = aws_s3_bucket.docs.id
}

output "docs_bucket_arn" {
  description = "ARN of the S3 bucket for documentation"
  value       = aws_s3_bucket.docs.arn
}

output "docs_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.docs.bucket_domain_name
}

# --- CloudFront Outputs ---
output "docs_cloudfront_distribution_id" {
  description = "CloudFront distribution ID for documentation"
  value       = aws_cloudfront_distribution.docs.id
}

output "docs_cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.docs.arn
}

output "docs_cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.docs.domain_name
}

output "docs_cloudfront_hosted_zone_id" {
  description = "CloudFront distribution hosted zone ID"
  value       = aws_cloudfront_distribution.docs.hosted_zone_id
}

# --- Certificate Outputs ---
output "docs_certificate_arn" {
  description = "ARN of the SSL certificate"
  value       = aws_acm_certificate.docs.arn
}

# --- Route53 Outputs ---
output "docs_route53_record_name" {
  description = "Route53 record name for documentation"
  value       = aws_route53_record.docs.name
}

output "docs_route53_record_fqdn" {
  description = "Fully qualified domain name for documentation"
  value       = aws_route53_record.docs.fqdn
}

# --- URLs ---
output "docs_url" {
  description = "URL of the documentation site"
  value       = "https://${local.docs_domain}"
}

# --- WAF Outputs (conditional) ---
output "docs_waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL (if enabled)"
  value       = var.enable_waf ? aws_wafv2_web_acl.docs[0].arn : null
}

# --- Logging Outputs ---
output "docs_logs_bucket_name" {
  description = "Name of the S3 bucket for CloudFront logs"
  value       = aws_s3_bucket.docs_logs.id
}

# --- Deployment Information ---
output "deployment_commands" {
  description = "Commands to deploy documentation"
  value = {
    sync_command         = "aws s3 sync ./build s3://${aws_s3_bucket.docs.id} --delete"
    invalidation_command = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.docs.id} --paths '/*'"
  }
}