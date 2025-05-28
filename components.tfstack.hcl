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
    region                       = var.aws_region
    project                      = var.project
    environment                  = var.environment
    vpc_id_shared                = component.vpc.vpc_id
    vpc_cidr_block_shared        = component.vpc.vpc_cidr_block
    private_subnets              = component.vpc.private_subnets
    spoke_vpc_cidrs              = var.spoke_vpc_cidrs
    account_ids                  = var.account_ids
    enable_records_public        = var.enable_records_public
    enable_records_subdomain     = var.enable_records_subdomain
    enable_records_private_main  = var.enable_records_private_main
    enable_records_private_dev   = var.enable_records_private_dev
    enable_records_private_prod  = var.enable_records_private_prod
    default_tags                 = var.default_tags
    public_records               = var.public_records
    subdomain_records            = var.subdomain_records
    main_private_records         = var.main_private_records
    dev_private_records          = var.dev_private_records
    prod_private_records         = var.prod_private_records
    externaldns_trusted_accounts = var.externaldns_configs
  }


  providers = {
    aws = provider.aws.configurations
  }

  depends_on = [component.vpc]
}

component "phz_vpc_associate" {
  source = "./aws-route53-association"

  for_each = {
    1 = component.route53.zone_ids["piksel.internal"],
    2 = component.route53.zone_ids["dev.piksel.internal"]
  }

  inputs = {
    account_ids        = var.account_ids
    spoke_vpc_ids      = var.spoke_vpc_ids
    authorization_zone = each.value
    default_tags       = var.default_tags
  }

  providers = {
    aws = provider.aws.configurations
  }

  depends_on = [component.route53]
}

component "tgw" {
  source = "./aws-tgw"

  inputs = {
    project                 = var.project
    environment             = var.environment
    vpc_id_shared           = component.vpc.vpc_id
    vpc_cidr_block_shared   = component.vpc.vpc_cidr_block
    spoke_vpc_cidrs         = var.spoke_vpc_cidrs
    private_subnets         = component.vpc.private_subnets
    account_ids             = var.account_ids
    private_route_table_ids = component.vpc.private_route_table_ids
  }

  providers = {
    aws = provider.aws.configurations
  }

  depends_on = [component.vpc]
}

component "security_group" {
  source = "./aws-security-group"

  inputs = {
    vpc_id_shared   = component.vpc.vpc_id
    vpc_cidr        = component.vpc.vpc_cidr_block
    spoke_vpc_cidrs = var.spoke_vpc_cidrs
    default_tags    = var.default_tags
  }

  providers = {
    aws = provider.aws.configurations
  }

  depends_on = [component.vpc]
}

component "ecr" {
  source = "./aws-ecr"

  inputs = {
    region                  = var.aws_region
    project                 = var.project
    current_account_id      = component.vpc.account_id
    account_ids             = var.account_ids
    ecr_endpoint_sg_id      = component.security_group.security_groups["ecr-endpoint-sg"]["id"]
    vpc_id_shared           = component.vpc.vpc_id
    private_subnet_ids      = component.vpc.private_subnets
    private_route_table_ids = component.vpc.private_route_table_ids
    default_tags            = var.default_tags
  }

  providers = {
    aws = provider.aws.configurations
  }

  depends_on = [component.tgw, component.phz_vpc_associate]
}

