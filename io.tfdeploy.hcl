# --- Input Values ---
upstream_input "infrastructure" {
  type   = "stack"
  source = "app.terraform.io/hashicorp/piksel-ina/piksel-infrastructure"
}

# --- Output Values ---
publish_output "vpc_id_shared" {
  description = "Shared VPC ID"
  value       = deployment.shared.vpc_id
}

publish_output "zone_ids" {
  description = "List of Route53 Hosted Zone IDs to associate with the VPC"
  value       = deployment.shared.zone_ids
}

