# --- Authorization for VPC Association ---
resource "aws_route53_vpc_association_authorization" "this" {
  for_each = toset(var.spoke_vpc_ids)
  vpc_id   = each.value
  zone_id  = var.authorization_zone
}

variable "spoke_vpc_ids" {
  description = "List of spoke VPC IDs"
  type        = list(string)
  default     = [""]
}

variable "authorization_zone" {
  description = "Zone on which VPCs will be authorized"
  type        = string
  default     = ""
}

output "authorization_ids" {
  description = "The calculated unique identifiers for the association"
  value       = { for k, v in aws_route53_vpc_association_authorization.this : k => v.id }
}

# --- Role to Allow Spoke VPC to Create Association with Hub VPC"
resource "aws_iam_role" "this" {
  for_each = toset(var.account_ids)
  name     = "vpc_association_cross_account_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          "AWS" = "arn:aws:iam::${each.value}:root"
        },
        "Action" : "route53:AssociateVPCWithHostedZone",
        "Resource" : "arn:aws:route53:::hostedzone/*"
      },
    ]
  })

  tags = var.default_tags
}

variable "account_ids" {
  description = "Account IDs to associate"
  type        = list(string)
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}