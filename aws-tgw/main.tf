locals {
  prefix         = "${lower(var.project)}-${lower(var.environment)}"
  ram_principals = values(var.account_ids)
  tags           = {
    "Terraform" = true
    "Project" = "Piksel"
  }
  blackhole_route = {
    destination_cidr_block = "0.0.0.0/0"
    blackhole              = true
  }
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
      vpc_id                             = var.vpc_id_shared
      subnet_ids                         = var.private_subnets
      enable_dns_support                 = true
      security_group_referencing_support = false

      enable_default_route_table_association = true
      enable_default_route_table_propagation = true
    }
  }

  ram_allow_external_principals = true
  ram_principals                = local.ram_principals

  tags = merge(local.tags, {
    Name = "${local.prefix}-tgw"
  })
}

# --- VPC Route Table Update ---
resource "aws_route" "hub_to_spoke_via_tgw" {
  count                  = length(var.spoke_vpc_cidrs)
  route_table_id         = var.private_route_table_ids[0]
  destination_cidr_block = var.spoke_vpc_cidrs[count.index]
  transit_gateway_id     = module.tgw.ec2_transit_gateway_id

  depends_on = [module.tgw]
}
