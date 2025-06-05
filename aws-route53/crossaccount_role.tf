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
}

# --- Cross Account Access for External DNS ---
resource "aws_iam_role" "externaldns_crossaccount" {
  for_each = { for v in var.cross_account_configs : v.env => v }

  name = "externaldns-crossaccount-role-${each.key}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${each.value.account_id}:oidc-provider/${replace(each.value.oidc_provider_url, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(each.value.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:${each.value.namespace}:${each.value.service_account_name}"
          }
        }
      }
    ]
  })
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
        Effect = "Allow"
        Action = [
          "route53:Get*",
          "route53:List*",
          "route53:Change*"
        ]
        Resource = "*"
      }
    ]
    }
  )
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
