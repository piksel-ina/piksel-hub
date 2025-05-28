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

publish_output "ecr_arn" {
  description = "ECR arn"
  value       = deployment.shared.ecr["arn"]
}

publish_output "ecr_url" {
  description = "ECR arn"
  value       = deployment.shared.ecr["url"]
}

publish_output "eks_ecr_role" {
  description = "ARN of the IAM role for EKS ECR access"
  value       = deployment.shared.ecr_role["eks_role_arn"]
}

publish_output "inbound_resolver_ips" {
  description = "List of Inbound Resolver Endpoint IPs"
  value       = deployment.shared.inbound_resolver_ip_addresses[*].ip
}

publish_output "externaldns_crossaccount_role_arns" {
  description = "Map of environment to ExternalDNS cross-account IAM role ARNs"
  value = deployment.shared.externaldns_crossaccount_role_arns
}

publish_output "externaldns_route53_policy_arns" {
  description = "Map of environment to ExternalDNS Route53 policy ARNs"
  value = deployment.shared.externaldns_route53_policy_arns
}