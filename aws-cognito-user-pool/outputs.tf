output "user_pool_id" {
  value = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  value = aws_cognito_user_pool.this.arn
}

output "user_pool_endpoint" {
  value = aws_cognito_user_pool.this.endpoint
}

output "client_ids" {
  value = { for k, v in aws_cognito_user_pool_client.this : k => v.id }
}

output "domain_cloud_front_domain" {
  value = length(aws_cognito_user_pool_domain.this) > 0 ? aws_cognito_user_pool_domain.this[0].cloudfront_distribution : ""
}

output "domain_cloud_front_zone_id" {
  value = length(aws_cognito_user_pool_domain.this) > 0 ? aws_cognito_user_pool_domain.this[0].cloudfront_distribution_zone_id : ""
}

output "lambda_arn" {
  value = aws_lambda_function.cognito_pre_signup.arn
}