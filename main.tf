terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "csearle"

    workspaces {
      name = "cs-resume-back-end-dev"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region              = var.region
  shared_config_files = []
  profile             = var.dev_prefix
}

data "aws_caller_identity" "current" {}
locals {
  account_id = data.aws_caller_identity.current.account_id
}

# GITHUB ACTIONS CONFIGURATION

resource "aws_iam_openid_connect_provider" "oidc" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = [
    "sts.amazonaws.com",
  ]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "gh" {
  name                = "github_actions_role"
  assume_role_policy  = data.aws_iam_policy_document.assume_role_oidc.json
}

resource "aws_iam_role_policy_attachment" "s3_policy" {
  role       = aws_iam_role.gh.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

data "aws_iam_policy_document" "assume_role_oidc" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.oidc.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:csearl3/cs-resume-front-end:*"]
    }
  }
}

# API CONFIGURATION

resource "aws_api_gateway_rest_api" "api" {
  name = "cs-resume-API"
  body = file("${path.module}/openapi.json")
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.api.body))
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stage" {
  depends_on    = [ aws_cloudwatch_log_group.api_group ]
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.dev_prefix
}

resource "aws_api_gateway_method_settings" "logging" {
  depends_on  = [ aws_api_gateway_account.settings ]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.stage.stage_name
  method_path = "*/*"
  settings {
    logging_level   = "INFO"
    throttling_rate_limit  = 100
    throttling_burst_limit = 50
  }
}

resource "aws_api_gateway_account" "settings" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}

data "aws_iam_policy_document" "assume_role_apigw" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cloudwatch" {
  name               = "api_gateway_cloudwatch_global"
  assume_role_policy = data.aws_iam_policy_document.assume_role_apigw.json
}

data "aws_iam_policy_document" "cloudwatch" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
    ]
    resources = ["*"]
  }
}
resource "aws_iam_role_policy" "cloudwatch" {
  name   = "logging_policy"
  role   = aws_iam_role.cloudwatch.id
  policy = data.aws_iam_policy_document.cloudwatch.json
}

resource "aws_cloudwatch_log_group" "api_group" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.api.id}/${var.dev_prefix}"
  retention_in_days = 7
}

# LAMBDA CONFIGURATION

# UNIQUE VISITOR FUNCTION
resource "aws_lambda_function" "unique" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "lambda_unique_function.zip"
  function_name = "uniqueIP-function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_unique_function.lambda_handler"
  runtime       = "python3.10"
  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.lambda_group,
  ]
  environment {
    variables = {
      TABLE_NAME = "uniqueIP-table"
      PYTHONHASHSEED = 7
    }
  }
}

resource "aws_lambda_permission" "unique_apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.unique.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:${var.region}:${local.account_id}:${aws_api_gateway_rest_api.api.id}/*/*/uniquelambda"
}

resource "aws_cloudwatch_log_group" "lambda_group" {
  name              = "/aws/lambda/uniqueIP-function"
  retention_in_days = 14
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:BatchGetItem",
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchWriteItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
    ]
    resources = ["arn:aws:dynamodb:*:*:*"]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_policy"
  path        = "/"
  description = "IAM policy for logging and DynamoDB access from a Lambda"
  policy      = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

data "aws_iam_policy_document" "assume_role_lambda" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "lambda_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
}

# VISIT COUNT FUNCTION
resource "aws_lambda_function" "counter" {
  filename      = "lambda_visitor_function.zip"
  function_name = "count-function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_visitor_function.lambda_handler"
  runtime       = "python3.10"
  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.lambda_group2,
  ]
  environment {
    variables = {
      TABLE_NAME = "visitCount-table"
    }
  }
}

resource "aws_lambda_permission" "counter_apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${local.account_id}:${aws_api_gateway_rest_api.api.id}/*/*/countlambda"
}

resource "aws_cloudwatch_log_group" "lambda_group2" {
  name              = "/aws/lambda/count-function"
  retention_in_days = 14
}

# DYNAMODB CONFIGURATION

resource "aws_dynamodb_table" "unique_table" {
  name           = "uniqueIP-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "IP_Hash"
  attribute {
    name = "IP_Hash"
    type = "S"
  }
}

resource "aws_dynamodb_table" "counter_table" {
  name           = "visitCount-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "stat"
  attribute {
    name = "stat"
    type = "S"
  }
}

# S3 BUCKET CONFIGURATION

resource "aws_s3_bucket" "bucket" {
  bucket = "cs-resume-dev"
}

resource "aws_s3_bucket_website_configuration" "static" {
  bucket = aws_s3_bucket.bucket.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.bucket.id
}

resource "aws_s3_bucket_policy" "allow_access" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.allow_access.json
}

data "aws_iam_policy_document" "allow_access" {
  statement {
    sid = "PublicReadGetObject"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.bucket.arn}/*",]
  }
}
