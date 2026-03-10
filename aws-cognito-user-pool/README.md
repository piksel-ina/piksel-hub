# AWS Cognito User Pool

Cognito User Pool module with self-signup and admin approval workflow.

## Usage

```hcl
module "cognito" {
  source = "../aws-cognito-user-pool"

  user_pool_name = "piksel-users"
  domain         = "auth.example.com"
  certificate_arn = aws_acm_certificate.cert.arn

  admin_email_subscriptions = ["admin@example.com"]

  clients = [
    {
      name                 = "my-app"
      allowed_oauth_flows  = ["code"]
      allowed_oauth_scopes = ["email", "openid", "profile"]
      callback_urls        = ["https://app.example.com/oauth/callback"]
      logout_urls          = ["https://app.example.com/"]
      generate_secret      = true
    }
  ]
}
```

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `user_pool_name` | string | Yes | Name of the Cognito User Pool |
| `clients` | list(object) | No | OAuth client configurations |
| `domain` | string | No | Custom domain for hosted UI |
| `certificate_arn` | string | No | ACM certificate ARN for custom domain |
| `admin_email_subscriptions` | list(string) | No | Emails to receive new user notifications |
| `default_tags` | map(string) | No | Tags applied to all resources |

### Client Object

| Attribute | Type | Description |
|-----------|------|-------------|
| `name` | string | Client name |
| `allowed_oauth_flows` | list(string) | OAuth flows: `code` or `implicit` |
| `allowed_oauth_scopes` | list(string) | OAuth scopes: `email`, `openid`, `profile`, `aws.cognito.signin.user.admin` |
| `callback_urls` | list(string) | OAuth callback URLs |
| `logout_urls` | list(string) | Logout URLs |
| `generate_secret` | bool | Whether to generate client secret |

## Outputs

| Name | Description |
|------|-------------|
| `user_pool_id` | Cognito User Pool ID |
| `user_pool_arn` | Cognito User Pool ARN |
| `user_pool_endpoint` | Cognito endpoint URL |
| `client_ids` | Map of client name to client ID |
| `domain_cloud_front_domain` | CloudFront domain for custom domain |
| `domain_cloud_front_zone_id` | CloudFront zone ID |
| `sns_new_user_topic_arn` | SNS topic ARN for new user notifications |

## Self-Signup with Admin Approval

### Flow

1. User signs up via hosted UI
2. Verification email sent automatically
3. User confirms email
4. Post Confirmation Lambda adds user to `pending_approval` group
5. Admin notified via SNS
6. Admin moves user to desired group in Cognito Console
7. User can access applications

### User Groups

The module creates these groups:

- `pending_approval` - New users waiting for admin approval
- `moderate_users` - Standard users
- `power_users` - Users with larger instance quotas
- `coastline` - Coastal data access
- `admin` - Administrators

### Lambdas

| Trigger | Function | Purpose |
|---------|----------|---------|
| Pre Sign-up | `cognito-pre-signup` | Cleans stale users with same email |
| Post Confirmation | `cognito-post-confirmation` | Adds user to pending_approval group, sends SNS |

### Handling Approval in Applications

Applications should check user's group membership:

```python
# Example: Check if user is in pending_approval group
cognito = boto3.client("cognito-idp")
response = cognito.admin_list_groups_for_user(
    UserPoolId="ap-southeast-3_XXXXX",
    Username="user@example.com"
)
groups = [g["GroupName"] for g in response["Groups"]]

if "pending_approval" in groups:
    # Redirect to approval pending page
    pass
```

## Email Verification

Email verification is automatic via `auto_verified_attributes = ["email"]`. The verification message template is configured in `config/email-verification.html`.
