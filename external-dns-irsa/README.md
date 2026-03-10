# External DNS IRSA

IAM roles for ExternalDNS and ODC CloudFront cross-account access. Enables Kubernetes services in workload accounts to manage DNS records in the shared account.

## Usage

```hcl
module "irsa-externaldns" {
  source = "../external-dns-irsa"

  project     = "piksel"
  environment = "staging"

  zone_ids = {
    "piksel.big.go.id" = "Z08561162REF6LC5AY0UM"
  }

  cross_account_configs = [
    {
      env                  = "staging"
      account_id           = "326641642924"
      namespace            = "external-dns"
      service_account_name = "external-dns-sa"
      hosted_zone_names    = ["staging.piksel.big.go.id", "piksel.big.go.id"]
    }
  ]
}
```

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `project` | string | Yes | Project name |
| `environment` | string | Yes | Environment name |
| `zone_ids` | map(string) | Yes | Route53 zone ID to name mapping |
| `cross_account_configs` | list(object) | Yes | List of cross-account configurations |
| `default_tags` | map(string) | No | Tags applied to all resources |

### Cross Account Config Object

| Attribute | Type | Description |
|-----------|------|-------------|
| `env` | string | Environment name (e.g., staging, prod) |
| `account_id` | string | Workload AWS account ID |
| `namespace` | string | Kubernetes namespace |
| `service_account_name` | string | Kubernetes service account name |
| `hosted_zone_names` | list(string) | DNS zone names to allow updates |

## Outputs

| Name | Description |
|------|-------------|
| `externaldns_crossaccount_role_arns` | Map of env to ExternalDNS IAM role ARNs |
| `cross_account_route53_policy_arns` | Map of env to Route53 policy ARNs |
| `odc_cloudfront_crossaccount_role_arns` | Map of env to CloudFront ODC IAM role ARNs |

## How It Works

1. IAM role created in shared account with Route53 permissions
2. Role trust policy allows assume-role from workload account
3. Kubernetes Service Account in workload account uses IRSA to assume role
4. ExternalDNS runs with those credentials to update DNS records

## Kubernetes Annotation

In workload accounts, annotate the ExternalDNS deployment:

```yaml
annotations:
  eks.amazonaws.com/role-arn: arn:aws:iam::326641642924:role/externaldns-crossaccount-role-staging
```
