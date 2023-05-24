terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  cloud {
    organization = "csearle"
    workspaces {
      name = "cs-resume-back-end-dev"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}
locals {
  account_id = data.aws_caller_identity.current.account_id
}

# API CONFIGURATION

resource "aws_api_gateway_rest_api" "api" {
  name = "cs-resume-API"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "unique" {
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "uniquelambda"
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "unique_get" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.unique.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "unique_options" {
  authorization = "NONE"
  http_method   = "OPTIONS"
  resource_id   = aws_api_gateway_resource.unique.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_integration" "unique_int_get" {
  http_method             = aws_api_gateway_method.unique_get.http_method
  resource_id             = aws_api_gateway_resource.unique.id
  rest_api_id             = aws_api_gateway_rest_api.api.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  content_handling        = "CONVERT_TO_TEXT"
  uri                     = aws_lambda_function.unique.invoke_arn
}

resource "aws_api_gateway_integration" "unique_int_options" {
  http_method = aws_api_gateway_method.unique_options.http_method
  resource_id = aws_api_gateway_resource.unique.id
  rest_api_id = aws_api_gateway_rest_api.api.id
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "unique_get_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.unique.id
  http_method = aws_api_gateway_method.unique_get.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_method_response" "unique_options_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.unique.id
  http_method = aws_api_gateway_method.unique_options.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "unique_get_int_response" {
  depends_on  = [aws_api_gateway_integration.unique_int_get]
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.unique.id
  http_method = aws_api_gateway_method.unique_get.http_method
  status_code = aws_api_gateway_method_response.unique_get_response.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

resource "aws_api_gateway_integration_response" "unique_options_int_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.unique.id
  http_method = aws_api_gateway_method.unique_options.http_method
  status_code = aws_api_gateway_method_response.unique_options_response.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_resource" "counter" {
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "countlambda"
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "counter_get" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.counter.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "counter_post" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.counter.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "counter_options" {
  authorization = "NONE"
  http_method   = "OPTIONS"
  resource_id   = aws_api_gateway_resource.counter.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_integration" "counter_int_get" {
  http_method             = aws_api_gateway_method.counter_get.http_method
  resource_id             = aws_api_gateway_resource.counter.id
  rest_api_id             = aws_api_gateway_rest_api.api.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  content_handling        = "CONVERT_TO_TEXT"
  uri                     = aws_lambda_function.counter.invoke_arn
}

resource "aws_api_gateway_integration" "counter_int_post" {
  http_method             = aws_api_gateway_method.counter_post.http_method
  resource_id             = aws_api_gateway_resource.counter.id
  rest_api_id             = aws_api_gateway_rest_api.api.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  content_handling        = "CONVERT_TO_TEXT"
  uri                     = aws_lambda_function.counter.invoke_arn
}

resource "aws_api_gateway_integration" "counter_int_options" {
  http_method = aws_api_gateway_method.counter_options.http_method
  resource_id = aws_api_gateway_resource.counter.id
  rest_api_id = aws_api_gateway_rest_api.api.id
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "counter_get_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.counter.id
  http_method = aws_api_gateway_method.counter_get.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_method_response" "counter_post_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.counter.id
  http_method = aws_api_gateway_method.counter_post.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_method_response" "counter_options_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.counter.id
  http_method = aws_api_gateway_method.counter_options.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "counter_get_int_response" {
  depends_on  = [aws_api_gateway_integration.counter_int_get]
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.counter.id
  http_method = aws_api_gateway_method.counter_get.http_method
  status_code = aws_api_gateway_method_response.counter_get_response.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

resource "aws_api_gateway_integration_response" "counter_post_int_response" {
  depends_on  = [aws_api_gateway_integration.counter_int_post]
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.counter.id
  http_method = aws_api_gateway_method.counter_post.http_method
  status_code = aws_api_gateway_method_response.counter_post_response.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

resource "aws_api_gateway_integration_response" "counter_options_int_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.counter.id
  http_method = aws_api_gateway_method.counter_options.http_method
  status_code = aws_api_gateway_method_response.counter_options_response.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_gateway_response" "default4xx" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  response_type = "DEFAULT_4XX"
  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Methods" : "'GET,OPTIONS,POST'",
    "gatewayresponse.header.Access-Control-Allow-Origin" : "'*'",
    "gatewayresponse.header.Access-Control-Allow-Headers" : "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
  }
}

resource "aws_api_gateway_gateway_response" "default5xx" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  response_type = "DEFAULT_5XX"
  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Methods" : "'GET,OPTIONS,POST'",
    "gatewayresponse.header.Access-Control-Allow-Origin" : "'*'",
    "gatewayresponse.header.Access-Control-Allow-Headers" : "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
  }
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.unique,
      aws_api_gateway_method.unique_get,
      aws_api_gateway_method.unique_options,
      aws_api_gateway_integration.unique_int_get,
      aws_api_gateway_integration.unique_int_options,
      aws_api_gateway_method_response.unique_get_response,
      aws_api_gateway_method_response.unique_options_response,
      aws_api_gateway_integration_response.unique_get_int_response,
      aws_api_gateway_integration_response.unique_options_int_response,
      aws_api_gateway_method.counter_get,
      aws_api_gateway_method.counter_post,
      aws_api_gateway_method.counter_options,
      aws_api_gateway_integration.counter_int_get,
      aws_api_gateway_integration.counter_int_post,
      aws_api_gateway_integration.counter_int_options,
      aws_api_gateway_method_response.counter_get_response,
      aws_api_gateway_method_response.counter_post_response,
      aws_api_gateway_method_response.counter_options_response,
      aws_api_gateway_integration_response.counter_get_int_response,
      aws_api_gateway_integration_response.counter_post_int_response,
      aws_api_gateway_integration_response.counter_options_int_response,
      aws_api_gateway_gateway_response.default4xx,
      aws_api_gateway_gateway_response.default5xx,
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stage" {
  depends_on    = [aws_cloudwatch_log_group.api_group]
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.dev_prefix
}

resource "aws_api_gateway_method_settings" "logging" {
  depends_on  = [aws_api_gateway_account.settings]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.stage.stage_name
  method_path = "*/*"
  settings {
    logging_level          = "INFO"
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
      TABLE_NAME     = "uniqueIP-table"
    }
  }
}

resource "aws_lambda_permission" "unique_apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.unique.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${local.account_id}:${aws_api_gateway_rest_api.api.id}/*/*${aws_api_gateway_resource.unique.path}"
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
  name         = "uniqueIP-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "IP_Hash"
  attribute {
    name = "IP_Hash"
    type = "S"
  }
}

resource "aws_dynamodb_table" "counter_table" {
  name         = "visitCount-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "stat"
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
    actions = ["s3:GetObject"]
    resources = [
      aws_s3_bucket.bucket.arn,
      "${aws_s3_bucket.bucket.arn}/*",
    ]
  }
}
