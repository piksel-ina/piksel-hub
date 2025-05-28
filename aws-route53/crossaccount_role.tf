locals {
  # Build a map from zone name to zone ID for easy lookup
  zone_name_to_id = {
    for k, z in aws_route53_zone.this : z.name => z.zone_id
  }
  env_zone_ids = {
    for env in var.externaldns_trusted_accounts :
    env.env => [
      for zone_name in env.hosted_zone_names :
      local.zone_name_to_id[zone_name]
    ]
  }
}

# --- Cross Account Access for External DNS ---
resource "aws_iam_role" "externaldns_crossaccount" {
  for_each = { for v in var.externaldns_trusted_accounts : v.env => v }

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
resource "aws_iam_policy" "externaldns_route53" {
  for_each = local.env_zone_ids

  name        = "ExternalDNSRoute53Policy-${each.key}"
  description = "Allow ExternalDNS to manage Route53 records for ${each.key}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        for zone_id in each.value : {
          Effect = "Allow"
          Action = [
            "route53:ChangeResourceRecordSets"
          ]
          Resource = "arn:aws:route53:::hostedzone/${zone_id}"
        }
      ],
      [
        {
          Effect = "Allow"
          Action = [
            "route53:ListHostedZones",
            "route53:ListResourceRecordSets"
          ]
          Resource = "*"
        }
      ]
    )
  })
}

# --- Attach policies ---
resource "aws_iam_role_policy_attachment" "externaldns_crossaccount_attach" {
  for_each = aws_iam_role.externaldns_crossaccount

  role       = each.value.name
  policy_arn = aws_iam_policy.externaldns_route53[each.key].arn
}


# --- The outputs ---
output "externaldns_crossaccount_role_arns" {
  description = "Map of environment to ExternalDNS cross-account IAM role ARNs"
  value       = { for k, v in aws_iam_role.externaldns_crossaccount : k => v.arn }
}

output "externaldns_route53_policy_arns" {
  description = "Map of environment to ExternalDNS Route53 policy ARNs"
  value       = { for k, v in aws_iam_policy.externaldns_route53 : k => v.arn }
}

