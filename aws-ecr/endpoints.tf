# --- VPC Endpoints for ECR in Shared Account VPC ---
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id             = var.vpc_id_shared
  service_name       = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = var.private_subnet_ids
  security_group_ids = [var.ecr_endpoint_sg_id]

  private_dns_enabled = true # Relies on Route 53 Resolver for cross-account DNS resolution

  tags = merge(var.default_tags, {
    Name = "${var.project}-ecr-api-endpoint"
  })
}

# --- ECR Docker Endpoint ---
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id             = var.vpc_id_shared
  service_name       = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = var.private_subnet_ids
  security_group_ids = [var.ecr_endpoint_sg_id]

  private_dns_enabled = true

  tags = merge(var.default_tags, {
    Name = "${var.project}-ecr-dkr-endpoint"
  })
}

# --- S3 Endpoint for ECR layer storage ---
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id_shared
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.private_route_table_ids

  tags = merge(var.default_tags, {
    Name = "${var.project}-s3-endpoint"
  })
}