output "authorization_ids" {
  description = "The calculated unique identifiers for the association"
  value       = { for k, v in aws_route53_vpc_association_authorization.this : k => v.id }
}
