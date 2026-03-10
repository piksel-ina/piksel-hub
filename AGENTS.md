# AGENTS.md - Piksel-Hub

Terraform infrastructure for shared AWS resources consumed by environment-specific repos (staging, production).

## Project Context

- **Terraform 1.x** + AWS Provider
- **Main region:** `ap-southeast-3`
- **State:** Local per module — never commit `.terraform/` or `*.tfstate*`
- **Modules:** prefer `terraform-aws-modules` from registry

## Repository Structure

| Directory | Purpose |
|-----------|---------|
| `deployments/` | **Single entrypoint** — always run commands from here |
| `aws-ecr/` | ECR repositories |
| `aws-cognito-user-pool/` | Cognito configuration |
| `external-dns-irsa/` | IAM roles for external-dns |
| `aws-s3-static-hosting/` | S3 static hosting |

Each module:
```
module-name/
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
└── config/
```

## Commands

**Always run from the `deployments/` entrypoint. Never target individual module directories.**

```bash
make init
make validate
make fmt
make plan
make apply    # also triggers backup.sh post-apply
make destroy
```

Always run before committing:
```bash
make validate && make fmt
```

## Code Conventions

### Do
- `snake_case` for all — variables, outputs, resources, files
- Singleton resource → use `this` (e.g. `aws_vpc.this`)
- Always include `description` on every variable
- Tags: always `merge(var.default_tags, { ManagedBy = "Terraform" })`
- IAM policies: use `jsonencode()`
- Use `optional()` + `try()` for flexible variable configs
- Aliased provider for us-east-1: `alias = "us_east_1"`

### Don't
- Don't run `plan`/`apply`/`destroy` from individual module directories
- Don't commit `.terraform/`, `*.tfstate`, or `*.tfstate.backup`
- Don't hardcode account IDs — use `data "aws_caller_identity" "current"`

## Linting (Optional)

```bash
tfsec .
tflint --module
checkov -d .
```
