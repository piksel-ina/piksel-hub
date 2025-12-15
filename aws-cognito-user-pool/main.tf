resource "aws_cognito_user_pool" "this" {
  name = var.user_pool_name

  alias_attributes         = ["email", "preferred_username"]
  auto_verified_attributes = ["email"]

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "institution"
    required                 = false
    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "phone"
    required                 = false
    string_attribute_constraints {
      min_length = 8
      max_length = 15
    }
  }

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "Verifikasi Akun PIKSEL / PIKSEL Account Verification"
    email_message        = file("${path.module}/config/email-verification.html")
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  deletion_protection = "ACTIVE"

  tags = var.tags
}

resource "aws_cognito_user_pool_client" "this" {
  for_each = { for client in var.clients : client.name => client }

  name         = each.value.name
  user_pool_id = aws_cognito_user_pool.this.id

  allowed_oauth_flows                  = each.value.allowed_oauth_flows
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = each.value.allowed_oauth_scopes
  callback_urls                        = each.value.callback_urls
  logout_urls                          = each.value.logout_urls
  supported_identity_providers         = ["COGNITO"]
  explicit_auth_flows                  = ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
}

resource "aws_cognito_user_pool_domain" "this" {
  count           = var.domain != "" ? 1 : 0
  domain          = var.domain
  certificate_arn = var.certificate_arn
  user_pool_id    = aws_cognito_user_pool.this.id
}
