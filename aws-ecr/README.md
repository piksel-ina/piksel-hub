# AWS ECR

Elastic Container Registry module with cross-account access and GitHub Actions integration.

## Usage

```hcl
module "ecr" {
  source = "../aws-ecr"

  project            = "piksel"
  current_account_id = "123456789012"

  github_org = "piksel-ina"

  account_ids = {
    dev     = "111111111111"
    staging = "222222222222"
    prod    = "333333333333"
  }

  ecr_repos = {
    "my-app"     = {}
    "jupyter"    = { keep_last = 5 }
    "data-api"   = { is_mutable = true }
    "worker"     = { expire_untagged_after_days = 14 }
  }
}
```

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `project` | string | Yes | Project name for tagging |
| `current_account_id` | string | Yes | AWS account ID for this account |
| `github_org` | string | Yes | GitHub organization for OIDC |
| `account_ids` | map(string) | Yes | Environment to account ID mapping |
| `ecr_repos` | map(object) | No | Repository configurations |
| `default_tags` | map(string) | No | Tags applied to all resources |

### ECR Repo Object

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `keep_last` | number | 3 | Number of untagged images to keep |
| `expire_untagged_after_days` | number | 7 | Days before untagged images expire |
| `is_mutable` | bool | false | Allow tag mutability |
| `tag_prefixes` | list(string) | null | Prefix filters for lifecycle policy |

## Outputs

| Name | Description |
|------|-------------|
| `ecr_repository_names` | Map of repo key to name |
| `ecr_repository_arns` | Map of repo key to ARN |
| `ecr_repository_urls` | Map of repo key to URL |
| `github_actions_role_arn` | IAM role for GitHub Actions |
| `eks_ecr_access_role_arn` | IAM role for EKS worker nodes |
| `github_oidc_provider_arn` | OIDC provider ARN for GitHub |

## Cross-Account Access

The module creates IAM roles that can be assumed by workload accounts:

- `piksel-eks-ecr-access` - For EKS nodes to pull images
- `piksel-ecr-github-actions` - For GitHub Actions to push/pull

## GitHub Actions Integration

The module sets up OIDC authentication for GitHub Actions. Workflow example:

```yaml
jobs:
  deploy:
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/piksel-ecr-github-actions
          aws-region: ap-southeast-3
      - uses: aws-actions/amazon-ecr-login@v2
      - docker build -t $ECR_REGISTRY/my-app:${{ github.sha }} .
      - docker push $ECR_REGISTRY/my-app:${{ github.sha }}
```
