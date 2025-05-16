# --- Transit Gateway Outputs ---
output "transit_gateway_id" {
  description = "The ID of the Transit Gateway"
  value       = module.tgw.ec2_transit_gateway_id
}

output "transit_gateway_arn" {
  description = "The ARN of the Transit Gateway"
  value       = module.tgw.ec2_transit_gateway_arn
}

output "transit_gateway_vpc_attachment_ids" {
  description = "List of Transit Gateway VPC Attachment identifiers"
  value       = module.tgw.ec2_transit_gateway_vpc_attachment_ids
}

output "transit_gateway_vpc_attachment" {
  description = "Map of Transit Gateway VPC Attachment attributes"
  value       = module.tgw.ec2_transit_gateway_vpc_attachment
}

output "route_hub_to_spoke_via_tgw_id" {
  description = "Route ID for the hub to spoke route via Transit Gateway"
  value       = [for r in aws_route.hub_to_spoke_via_tgw : r.id]
}

output "route_hub_to_spoke_via_tgw_instance_id" {
  description = "Instance ID for the hub to spoke route via Transit Gateway"
  value       = [for r in aws_route.hub_to_spoke_via_tgw : r.instance_id]
}

output "route_hub_to_spoke_via_tgw_state" {
  description = "State of the hub to spoke route via Transit Gateway"
  value       = [for r in aws_route.hub_to_spoke_via_tgw : r.state]
}