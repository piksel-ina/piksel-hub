
# --- Zone outputs ---
output "zone_ids" {
  description = "Zone ID of Route53 zone"
  value       = { for k, v in aws_route53_zone.this : k => v.zone_id }
}

output "zone_arns" {
  description = "Zone ARN of Route53 zone"
  value       = { for k, v in aws_route53_zone.this : k => v.arn }
}

output "zone_name_servers" {
  description = "Name servers of Route53 zone"
  value       = { for k, v in aws_route53_zone.this : k => v.name_servers }
}

output "primary_name_server" {
  description = "The Route 53 name server that created the SOA record."
  value       = { for k, v in aws_route53_zone.this : k => v.primary_name_server }
}

output "zone_name" {
  description = "Name of Route53 zone"
  value       = { for k, v in aws_route53_zone.this : k => v.name }
}

# --- Resolver Outputs ---
output "inbound_resolver_id" {
  description = "The ID of the Inbound Resolver Endpoint."
  value       = module.inbound_resolver_endpoint.route53_resolver_endpoint_id
}

output "inbound_resolver_arn" {
  description = "The ARN of the Inbound Resolver Endpoint."
  value       = module.inbound_resolver_endpoint.route53_resolver_endpoint_arn
}

output "inbound_resolver_ip_addresses" {
  description = "IP Addresses of the Inbound Resolver Endpoint."
  value       = module.inbound_resolver_endpoint.route53_resolver_endpoint_ip_addresses
}

output "inbound_resolver_security_group_id" {
  description = "Security Group ID used by the Inbound Resolver Endpoint."
  value       = module.inbound_resolver_endpoint.route53_resolver_endpoint_security_group_ids
}

# --- Cross Account Role ---
output "externaldns_crossaccount_role_arns" {
  value = { for k, v in aws_iam_role.externaldns_crossaccount : k => v.arn }
}

