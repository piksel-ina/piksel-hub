locals {
  prefix         = "${lower(var.project)}-${lower(var.environment)}"
  ram_principals = values(var.account_ids)
  tags           = var.default_tags
  destinations = [
    for cidr in var.spoke_vpc_cidrs : {
      destination_cidr_block = cidr
    }
  ]
  hub_tgw_routes = concat(
    local.destinations,
    [
      {
        destination_cidr_block = "0.0.0.0/0"
        blackhole              = true
      }
    ]
  )

}

# --- Transit Gateway for VPC-to-VPC connectivity ---
module "tgw" {
  source  = "terraform-aws-modules/transit-gateway/aws"
  version = "= 2.13.0"

  name        = "${local.prefix}-tgw"
  description = "${local.prefix} Transit Gateway"

  enable_auto_accept_shared_attachments = true


  vpc_attachments = {
    vpc_shared = {
      vpc_id             = var.vpc_id_shared
      subnet_ids         = var.private_subnets
      enable_dns_support = true

      enable_default_route_table_association = false
      enable_default_route_table_propagation = false

      tgw_routes = local.hub_tgw_routes
    }
  }

  ram_allow_external_principals = true
  ram_principals                = local.ram_principals

  tags = merge(local.tags, {
    Name = "${local.prefix}-tgw"
  })
}
