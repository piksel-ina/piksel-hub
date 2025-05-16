component "vpc" {
  source = "./aws-vpc"

  inputs = {
    region                  = var.aws_region
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

  providers = {
    aws = provider.aws.configurations
  }
}

component "route53" {
  source = "./aws-route53"

  inputs = {
    region                      = var.aws_region
    project                     = var.project
    environment                 = var.environment
    vpc_id_shared               = component.vpc.vpc_id
    vpc_cidr_block_shared       = component.vpc.vpc_cidr_block
    private_subnets             = component.vpc.private_subnets
    spoke_vpc_cidrs             = var.spoke_vpc_cidrs
    enable_records_public       = var.enable_records_public
    enable_records_subdomain    = var.enable_records_subdomain
    enable_records_private_dev  = var.enable_records_private_dev
    enable_records_private_prod = var.enable_records_private_prod
    default_tags                = var.default_tags
  }

  providers = {
    aws = provider.aws.configurations
  }

  depends_on = [component.vpc]
}

component "phz_vpc_authorization" {
  source = "./aws-route53-authorization"

  inputs = {
    account_ids        = var.account_ids
    default_tags       = var.default_tags
    spoke_vpc_ids      = var.spoke_vpc_ids
    authorization_zone = component.route53.main_phz_id
  }

  providers = {
    aws = provider.aws.configurations
  }

  depends_on = [component.route53]
}

