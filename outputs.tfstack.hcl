# --- Data Source ---
output "account_id" {
  type        = string
  description = "The AWS account ID"
  value       = component.vpc.account_id
}

# --- VPC Outputs ---
output "vpc_id" {
  type        = string
  description = "ID of the VPC"
  value       = component.vpc.vpc_id
}

output "vpc_cidr_block" {
  type        = string
  description = "CIDR block of the VPC"
  value       = component.vpc.vpc_cidr_block
}

# --- Subnet Outputs ---
output "public_subnets" {
  type        = list(string)
  description = "List of IDs of public subnets"
  value       = component.vpc.public_subnets
}

output "public_subnets_cidr_blocks" {
  type        = list(string)
  description = "List of CIDR blocks of public subnets"
  value       = component.vpc.public_subnets_cidr_blocks
}

output "private_subnets" {
  type        = list(string)
  description = "List of IDs of private subnets"
  value       = component.vpc.private_subnets
}

output "private_subnets_cidr_blocks" {
  type        = list(string)
  description = "List of CIDR blocks of private subnets"
  value       = component.vpc.private_subnets_cidr_blocks
}

# --- NAT Gateway Outputs ---
output "natgw_ids" {
  type        = list(string)
  description = "List of NAT Gateway IDs"
  value       = component.vpc.natgw_ids
}

output "nat_public_ips" {
  type        = list(string)
  description = "List of NAT Gateway IDs"
  value       = component.vpc.nat_public_ips
}

# --- Route Table Outputs ---
output "public_route_table_ids" {
  type        = list(string)
  description = "List of IDs of public route tables"
  value       = component.vpc.public_route_table_ids
}

output "private_route_table_ids" {
  type        = list(string)
  description = "List of IDs of private route tables"
  value       = component.vpc.private_route_table_ids
}

# --- Flow Logs Outputs ---
output "vpc_flow_log_id" {
  type        = string
  description = "ID of the VPC Flow Log (if enabled)"
  value       = component.vpc.vpc_flow_log_id
}

output "vpc_flow_log_cloudwatch_iam_role_arn" {
  type        = string
  description = "ARN of the CloudWatch Log Group for Flow Logs (if enabled)"
  value       = component.vpc.vpc_flow_log_cloudwatch_iam_role_arn
}

# --- Route53 Zone Outputs ---
output "zone_ids" {
  description = "The ID of the public hosted zone"
  value       = component.route53.zone_ids
  type        = map(string)
}

output "zone_name_servers" {
  description = "Name servers for the hosted zone"
  value       = component.route53.zone_name_servers
  type        = map(list(string))
}

output "zone_arns" {
  description = "The ARN of the public hosted zone"
  value       = component.route53.zone_arns
  type        = map(string)
}

output "zone_name" {
  description = "The name of the public hosted zone"
  value       = component.route53.zone_name
  type        = map(string)
}

# --- Resolver Outputs ---
output "inbound_resolver_id" {
  description = "The ID of the Inbound Resolver Endpoint."
  value       = component.route53.inbound_resolver_id
  type        = string
}

output "inbound_resolver_arn" {
  description = "The ARN of the Inbound Resolver Endpoint."
  value       = component.route53.inbound_resolver_arn
  type        = string
}

output "inbound_resolver_ip_addresses" {
  description = "IP Addresses of the Inbound Resolver Endpoint."
  value       = component.route53.inbound_resolver_ip_addresses
  type        = set(map(string))
}

output "inbound_resolver_security_group_id" {
  description = "Security Group ID used by the Inbound Resolver Endpoint."
  value       = component.route53.inbound_resolver_security_group_id
  type        = list(string)
}

# --- Authorization Outputs ---
output "authorization_ids" {
  description = "The unique identifiers for the authorizations"
  value       = [for x in component.phz_vpc_associate : x.authorization_ids]
  type        = list(map(string))
}

output "association_ids" {
  description = "The unique identifiers for the authorizations"
  value       = [for x in component.phz_vpc_associate : x.authorization_ids]
  type        = list(map(string))
}

# --- Transit Gateway Outputs ---
output "transit_gateway_id" {
  description = "The ID of the Transit Gateway"
  value       = component.tgw.transit_gateway_id
  type        = string
}

output "transit_gateway_arn" {
  description = "The ARN of the Transit Gateway"
  value       = component.tgw.transit_gateway_arn
  type        = string
}

output "transit_gateway_vpc_attachment_ids" {
  description = "List of Transit Gateway VPC Attachment identifiers"
  value       = component.tgw.transit_gateway_vpc_attachment_ids
  type        = list(string)
}

output security_group_metadata {
  description = "Output the security group"
  type = object({
    arn         = string
    id          = string
    name        = string
    description = string
  })
  value = {
    arn         = component.security_group.security_group_arn
    id          = component.security_group.security_group_id
    name        = component.security_group.security_group_name
    description = component.security_group.security_group_description
  }
}
