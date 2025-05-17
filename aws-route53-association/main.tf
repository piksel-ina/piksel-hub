# --- Authorization for VPC Association ---
resource "aws_route53_vpc_association_authorization" "this" {
  for_each = toset(var.spoke_vpc_ids)
  vpc_id   = each.value
  zone_id  = var.authorization_zone
}

# --- Role to Allow Spoke VPC to Create Association with Hub VPC"
resource "aws_iam_role" "this" {
  for_each = var.account_ids
  name     = "cross_account_role_${each.key}_with_${var.authorization_zone}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          "AWS" = "arn:aws:iam::${each.value}:root"
        },
        Action = "sts:AssumeRole"
      },
    ]
  })

  tags = var.default_tags
}

# --- Grants the role permission to associate VPCs with hosted zones ---
resource "aws_iam_role_policy" "this" {
  for_each = var.account_ids
  name     = "vpc_association_policy_${each.key}"
  role     = aws_iam_role.this[each.key].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "route53:AssociateVPCWithHostedZone"
        Resource = "arn:aws:route53:::hostedzone/${var.authorization_zone}"
      }
    ]
  })
}

