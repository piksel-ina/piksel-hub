# --- Data Source ---
output "account_id" {
  description = "The AWS account ID"
  value       = module.network.account_id
}

# --- VPC Outputs ---
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.network.vpc_cidr_block
}

# --- Subnet Outputs ---
output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.network.public_subnets
}

output "public_subnets_cidr_blocks" {
  description = "List of CIDR blocks of public subnets"
  value       = module.network.public_subnets_cidr_blocks
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.network.private_subnets
}

output "private_subnets_cidr_blocks" {
  description = "List of CIDR blocks of private subnets"
  value       = module.network.private_subnets_cidr_blocks
}

# --- NAT Gateway Outputs ---
output "natgw_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.network.natgw_ids
}

output "nat_public_ips" {
  description = "List of NAT Gateway IDs"
  value       = module.network.nat_public_ips
}

# --- Route Table Outputs ---
output "public_route_table_ids" {
  description = "List of IDs of public route tables"
  value       = module.network.public_route_table_ids
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = module.network.private_route_table_ids
}

# --- Flow Logs Outputs ---
output "vpc_flow_log_id" {
  description = "ID of the VPC Flow Log (if enabled)"
  value       = module.network.vpc_flow_log_id
}

output "vpc_flow_log_cloudwatch_iam_role_arn" {
  description = "ARN of the CloudWatch Log Group for Flow Logs (if enabled)"
  value       = module.network.vpc_flow_log_cloudwatch_iam_role_arn
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
