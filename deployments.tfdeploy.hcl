locals {
  common_tags = {
    "Terraform" = true
    "Project"   = "Piksel"
    "Service"   = "pik-sel.id"
    "Owner"     = "Piksel-Devops-Team"
  }
  region      = "ap-southeast-3"
  project     = "Piksel"
  dev_account = "236122835646"
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
      "dev_account" = local.dev_account
    }
    spoke_vpc_ids   = ["vpc-03f8c4d789172e39a"]
    spoke_vpc_cidrs = ["10.1.0.0/16"]
    cross_account_configs = [
      {
        env                  = "dev"
        account_id           = local.dev_account
        namespace            = "external-dns"
        service_account_name = "external-dns-sa"
        hosted_zone_names    = ["dev.pik-sel.id"]
      }
    ]
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
