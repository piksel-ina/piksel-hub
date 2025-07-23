locals {
  prefix = "${lower(var.project)}-${lower(var.environment)}"
  tags   = var.default_tags

  # Build a map from zone name to zone ID for easy lookup
  zone_name_to_id = var.zone_ids
  env_zone_ids = {
    for env in var.cross_account_configs :
    env.env => [
      for zone_name in env.hosted_zone_names :
      local.zone_name_to_id[zone_name]
    ]
  }
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
          AWS = "arn:aws:iam::${each.value.account_id}:root" # temporary, until IRSA created  
        #   AWS = "arn:aws:iam::${each.value.account_id}:role/external-dns-irsa"
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

