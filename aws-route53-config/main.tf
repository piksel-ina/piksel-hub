# --- Zone Configuration ---
locals {
  prefix = "${lower(var.project)}-${lower(var.environment)}"
  tags   = var.default_tags
}


# --- INBOUND RESOLVER ENDPOINT ---
module "inbound_resolver_endpoint" {
  source  = "terraform-aws-modules/route53/aws//modules/resolver-endpoints"
  version = "~> 5.0"

  create    = var.create_inbound_resolver_endpoint
  name      = "${local.prefix}-inbound-resolver"
  direction = "INBOUND"
  vpc_id    = var.vpc_id_shared

  protocols = ["Do53"]

  # Provide at least two subnets in different AZs
  ip_address = [
    { subnet_id = var.private_subnets[0] },
    { subnet_id = var.private_subnets[1] }
  ]

  # Create security group
  create_security_group              = true
  security_group_name                = "${var.project}-resolver-inbound-sg"
  security_group_description         = "Allow DNS queries to Inbound Resolver Endpoint for ${var.project}"
  security_group_ingress_cidr_blocks = concat(var.spoke_vpc_cidrs, [var.vpc_cidr_block_shared])
  security_group_egress_cidr_blocks  = ["0.0.0.0/0"]

  tags                = merge(local.tags, { Name = "${var.project}-inbound-resolver" })
  security_group_tags = merge(local.tags, { Name = "${var.project}-resolver-inbound-sg" })
}


locals {
  # Build a map from zone name to zone ID for easy lookup
  zone_name_to_id = {
    for k, z in aws_route53_zone.this : z.name => z.zone_id
  }
  env_zone_ids = {
    for env in var.cross_account_configs :
    env.env => [
      for zone_name in env.hosted_zone_names :
      local.zone_name_to_id[zone_name]
    ]
  }
  tags = var.default_tags
}

# --- Cross Account Access for External DNS ---
resource "aws_iam_role" "externaldns_crossaccount" {
  for_each = { for v in var.cross_account_configs : v.env => v }

  name = "externaldns-crossaccount-role-${lower(each.key)}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          # AWS = "arn:aws:iam::${each.value.account_id}:root" # temporary, until IRSA created  
          AWS = "arn:aws:iam::${each.value.account_id}:role/external-dns-irsa"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "external-dns-${lower(each.key)}"
          }
        }
      }
    ]
  })

  tags = local.tags
}

# --- Generate the IAM Policy Dynamically ---
resource "aws_iam_policy" "cross_account_route53_policy" {
  for_each = local.env_zone_ids

  name        = "CrossAccountDNSRoute53Policy-${each.key}"
  description = "Allow Cross Account Resources to manage Route53 records for ${each.key}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRoute53ListOperations"
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListHostedZonesByName",
          "route53:GetChange",
          "route53:GetHostedZoneCount"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowSpecificHostedZoneOperations"
        Effect = "Allow"
        Action = [
          "route53:GetHostedZone",
          "route53:ListResourceRecordSets",
          "route53:ChangeResourceRecordSets"
        ]
        Resource = [
          for zone_id in each.value :
          "arn:aws:route53:::hostedzone/${zone_id}"
        ]
      },
      {
        Sid    = "AllowHealthCheckOperations"
        Effect = "Allow"
        Action = [
          "route53:CreateHealthCheck",
          "route53:DeleteHealthCheck",
          "route53:GetHealthCheck",
          "route53:ListHealthChecks",
          "route53:UpdateHealthCheck"
        ]
        Resource = "*"
      }
    ]
    }
  )

  tags = local.tags
}


# --- Attach policies ---
resource "aws_iam_role_policy_attachment" "externaldns_crossaccount_attach" {
  for_each = aws_iam_role.externaldns_crossaccount

  role       = each.value.name
  policy_arn = aws_iam_policy.cross_account_route53_policy[each.key].arn
}

# --- Cross Account Trust Policy for ODC-Cloudfront Cache---
# --- This is used to allow the ODC CloudFront distribution to assume the role in the other accounts ---
resource "aws_iam_role" "odc_cloudfront_crossaccount" {
  for_each = { for v in var.cross_account_configs : v.env => v }

  name = "odc-cloudfront-crossaccount-role-${each.key}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${each.value.account_id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}
 
# --- Attach policies ---
resource "aws_iam_role_policy_attachment" "odc_cloudfront_crossaccount_attach" {
  for_each = aws_iam_role.odc_cloudfront_crossaccount

  role       = each.value.name
  policy_arn = aws_iam_policy.cross_account_route53_policy[each.key].arn
}

# --- The outputs ---
output "externaldns_crossaccount_role_arns" {
  description = "Map of environment to ExternalDNS cross-account IAM role ARNs"
  value       = { for k, v in aws_iam_role.externaldns_crossaccount : k => v.arn }
}

output "cross_account_route53_policy_policy_arns" {
  description = "Map of environment to ExternalDNS Route53 policy ARNs"
  value       = { for k, v in aws_iam_policy.cross_account_route53_policy : k => v.arn }
}

output "odc_cloudfront_crossaccount_role_arns" {
  description = "Map of environment to ODC CloudFront cross-account IAM role ARNs"
  value       = { for k, v in aws_iam_role.odc_cloudfront_crossaccount : k => v.arn }
}
