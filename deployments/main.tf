locals {
  staging_account_id = "326641642924"
}

# VPC and other network component
module "network" {
  source = "../aws-vpc"

  project                 = var.project
  environment             = var.environment
  vpc_cidr                = var.vpc_cidr
  az_count                = var.az_count
  single_nat_gateway      = var.single_nat_gateway
  one_nat_gateway_per_az  = var.one_nat_gateway_per_az
  enable_flow_log         = var.enable_flow_log
  flow_log_retention_days = var.flow_log_retention_days
  default_tags            = var.default_tags
}

# Route 53 zone for staging
module "zones" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "~> 3.0"

  zones = {
    "staging.pik-sel.id" = {
      comment = "staging.pik-sel.id"
      tags = {
        Environment = "staging"
      }
    },
    "pik-sel.id" = {
      comment = "pik-sel.id main domain"
      tags = {
        Environment = "production"
      }
    }
  }

  tags = merge(var.default_tags, {
    ManagedBy = "Terraform"
  })
}

# Create NS record in parent domain for staging subdomain
module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 3.0"

  zone_id = module.zones.route53_zone_zone_id["pik-sel.id"]

  records = [
    {
      name    = "staging"
      type    = "NS"
      ttl     = 300
      records = module.zones.route53_zone_name_servers["staging.pik-sel.id"]
    }
  ]

  depends_on = [module.zones]
}

# IRSA for ExternaDNS 
module "irsa-externaldns" {
  source = "../external-dns-irsa"

  zone_ids    = module.zones.route53_zone_zone_id
  project     = var.project
  environment = var.environment
  cross_account_configs = [
    {
      env                  = "staging"
      account_id           = local.staging_account_id
      namespace            = "external-dns"
      service_account_name = "external-dns-sa"
      hosted_zone_names    = ["staging.pik-sel.id"]
    }
  ]

}

# AWS ECR
module "ecr" {
  source = "../aws-ecr"
  project                 = var.project
  current_account_id      = module.network.account_id
  account_ids             = {
    "staging" = local.staging_account_id
    }
  default_tags            = var.default_tags
}