locals {
  common_tags = {
    "ManagedBy" = "Terraform"
    "Project"   = "Piksel"
    "Service"   = "piksel.big.go.id"
    "Owner"     = "Piksel-Devops-Team"
  }
  region  = "ap-southeast-3"
  project = "Piksel"
}

identity_token "aws" {
  audience = ["aws.workload.identity"]
}

# --- Deployment for Shared Account ---
deployment "shared" {
  inputs = {
    aws_region              = local.region
    project                 = local.project
    environment             = "Shared"
    default_tags            = merge(local.common_tags, { "Environment" = "Shared" })
    aws_role                = "arn:aws:iam::686410905891:role/stacks-piksel-ina-piksel-ina"
    aws_token               = identity_token.aws.jwt
    vpc_cidr                = "10.0.0.0/16"
    az_count                = "3"
    single_nat_gateway      = true
    one_nat_gateway_per_az  = false
    enable_flow_log         = true
    flow_log_retention_days = 30
    account_ids = {
      "dev_account" = "236122835646"
    }
    enable_records_public       = false
    enable_records_subdomain    = false
    enable_records_private_dev  = false
    enable_records_private_prod = false
    spoke_vpc_ids               = [upstream_input.infrastructure.vpc_id_dev]
    spoke_vpc_cidrs             = [upstream_input.infrastructure.vpc_cidr_dev, "10.2.0.0/16"]
  }
}

# --- Auto-approve plans for shared ---
orchestrate "auto_approve" "safe_plan_shared" {
  check {
    condition = context.plan.deployment == deployment.shared
    reason    = "Only automatically approved plans that are for the shared deployment."
  }
  check {
    condition = context.success
    reason    = "Operation unsuccessful. Check HCP Terraform UI for error details."
  }
  check {
    condition = context.plan.changes.remove == 0
    reason    = "Plan is destroying ${context.plan.changes.remove} resources."
  }
}
