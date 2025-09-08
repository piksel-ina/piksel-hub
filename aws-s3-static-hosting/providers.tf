provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.default_tags
  }
}

# Provider for us-east-1 (required for CloudFront certificates)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = var.default_tags
  }
}