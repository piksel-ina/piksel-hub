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

  lambda_config {
    pre_sign_up = aws_lambda_function.cognito_pre_signup.arn
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

  tags = var.default_tags
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

  generate_secret = lookup(each.value, "generate_secret", false)
}

resource "aws_cognito_user_pool_domain" "this" {
  count           = var.domain != "" ? 1 : 0
  domain          = var.domain
  certificate_arn = var.certificate_arn
  user_pool_id    = aws_cognito_user_pool.this.id
}


# Lambda IAM role
resource "aws_iam_role" "cognito_lambda_role" {
  name = "cognito-pre-signup-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.default_tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.cognito_lambda_role.name
}

# Create zip file from the Python script
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_deployment.zip"

  source {
    content  = file("${path.module}/config/cognito_pre_signup.py")
    filename = "index.py"
  }
}

# Lambda function
resource "aws_lambda_function" "cognito_pre_signup" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "cognito-pre-signup-validation"
  role          = aws_iam_role.cognito_lambda_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }

  tags = var.default_tags
}

data "aws_caller_identity" "current" {}

# Permission for Cognito to invoke Lambda
resource "aws_lambda_permission" "allow_cognito" {
  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cognito_pre_signup.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = "arn:aws:cognito-idp:${var.aws_region}:${data.aws_caller_identity.current.account_id}:userpool/*"
}
