# --- Output Values ---
publish_output "vpc_id_shared" {
  description = "Shared VPC ID"
  value       = deployment.shared.vpc_id
}

publish_output "zone_ids" {
  description = "List of Route53 Hosted Zone IDs to associate with the VPC"
  value       = deployment.shared.zone_ids
}

publish_output "transit_gateway_id" {
  description = "Transit Gateway ID"
  value       = deployment.shared.transit_gateway_id
}