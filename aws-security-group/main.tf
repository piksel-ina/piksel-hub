# --- Security Group Configurations ---

# --- 1st Security Group: Hub VPC Services ---
module "hub_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "hub-to-spoke-sg"
  description = "Security Group for hub VPC services allowing traffic from spoke VPCs"
  vpc_id      = var.vpc_id_shared

  # --- Ingress rules: Allow DNS (UDP/53) and optionally TCP/53 from spoke VPCs ---
  ingress_with_cidr_blocks = [
    {
      from_port   = 53
      to_port     = 53
      protocol    = "udp"
      description = "Allow DNS UDP from spoke VPCs"
      cidr_blocks = join(",", var.spoke_vpc_cidrs)
    },
    {
      from_port   = 53
      to_port     = 53
      protocol    = "tcp"
      description = "Allow DNS TCP from spoke VPCs"
      cidr_blocks = join(",", var.spoke_vpc_cidrs)
    },
    {
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      description = "Allow ICMP (ping) from spoke VPCs"
      cidr_blocks = join(",", var.spoke_vpc_cidrs)
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "Allow HTTP from spoke VPCs"
      cidr_blocks = join(",", var.spoke_vpc_cidrs)
    }
  ]

  # --- Egress rules: Allow all outbound traffic ---
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all outbound traffic"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = var.default_tags
}

# --- 2nd Security Group: ECR Endpoints in Hub VPC ---
module "ecr_endpoint_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "ecr-endpoint-sg"
  description = "Security Group for ECR VPC endpoints in hub VPC allowing HTTPS from spoke VPCs"
  vpc_id      = var.vpc_id_shared

  # --- Ingress rules: Allow HTTPS (443) from spoke VPCs and hub VPC CIDR ---
  ingress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Allow HTTPS from hub and spoke VPCs"
      cidr_blocks = join(",", concat([var.vpc_cidr], var.spoke_vpc_cidrs))
    }
  ]

  # --- Egress rules: Allow all outbound traffic (for endpoint to communicate with AWS services if needed) ---
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all outbound traffic"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = var.default_tags
}


