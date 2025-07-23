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


