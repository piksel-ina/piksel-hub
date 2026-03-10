data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_post_confirmation" {
  name               = "lambda-post-confirmation-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "lambda_pre_signup" {
  name               = "lambda-pre-signup-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "lambda_post_confirmation_policy" {
  statement {
    effect = "Allow"
    actions = [
      "cognito-idp:AdminAddUserToGroup",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "cognito-idp:AdminListGroupsForUser",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "sns:Publish",
    ]
    resources = [aws_sns_topic.new_user.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "lambda_post_confirmation" {
  name        = "lambda-post-confirmation-policy"
  description = "Policy for Lambda post confirmation to disable user and publish SNS"
  policy      = data.aws_iam_policy_document.lambda_post_confirmation_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_post_confirmation" {
  role       = aws_iam_role.lambda_post_confirmation.name
  policy_arn = aws_iam_policy.lambda_post_confirmation.arn
}

data "aws_iam_policy_document" "lambda_pre_signup_policy" {
  statement {
    effect = "Allow"
    actions = [
      "cognito-idp:ListUsers",
      "cognito-idp:AdminDeleteUser",
    ]
    resources = [aws_cognito_user_pool.this.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "lambda_pre_signup" {
  name        = "lambda-pre-signup-policy"
  description = "Policy for Lambda pre signup to clean stale users"
  policy      = data.aws_iam_policy_document.lambda_pre_signup_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_pre_signup" {
  role       = aws_iam_role.lambda_pre_signup.name
  policy_arn = aws_iam_policy.lambda_pre_signup.arn
}

resource "aws_sns_topic" "new_user" {
  name = "new-user"
}

resource "aws_sns_topic_subscription" "admin_emails" {
  for_each  = toset(var.admin_email_subscriptions)
  topic_arn = aws_sns_topic.new_user.arn
  protocol  = "email"
  endpoint  = each.value
}

data "archive_file" "post_confirmation" {
  type        = "zip"
  source_file = "${path.module}/lambda/post-confirmation/main.py"
  output_path = "${path.module}/lambda/post-confirmation/function.zip"
}

data "archive_file" "pre_signup" {
  type        = "zip"
  source_file = "${path.module}/lambda/pre-signup/main.py"
  output_path = "${path.module}/lambda/pre-signup/function.zip"
}

resource "aws_lambda_function" "post_confirmation" {
  filename         = data.archive_file.post_confirmation.output_path
  function_name    = "cognito-post-confirmation"
  role             = aws_iam_role.lambda_post_confirmation.arn
  handler          = "main.handler"
  source_code_hash = data.archive_file.post_confirmation.output_base64sha256
  runtime          = "python3.12"
  architectures    = ["arm64"]

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.new_user.arn
    }
  }
}

resource "aws_lambda_function" "pre_signup" {
  filename         = data.archive_file.pre_signup.output_path
  function_name    = "cognito-pre-signup"
  role             = aws_iam_role.lambda_pre_signup.arn
  handler          = "main.handler"
  source_code_hash = data.archive_file.pre_signup.output_base64sha256
  runtime          = "python3.12"
  architectures    = ["arm64"]
}

resource "aws_lambda_permission" "cognito_post_confirmation" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_confirmation.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.this.arn
}

resource "aws_lambda_permission" "cognito_pre_signup" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pre_signup.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.this.arn
}
