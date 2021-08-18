locals {
  function_name = "df-http-api-handler"
}
# Create API
resource "aws_apigatewayv2_api" "df-api" {
  name          = "df-api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
  }
}

# Add default stage with autodeploy
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.df-api.id
  name        = "$default"
  auto_deploy = true
}

# create default route
resource "aws_apigatewayv2_route" "default" {
  api_id             = aws_apigatewayv2_api.df-api.id
  route_key          = "$default"
  authorization_type = "NONE"
  target             = "integrations/${aws_apigatewayv2_integration.default.id}"
}

# Create role for lambda
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "api_lambda" {
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "upload_to_proteins_policy_attachment" {
  role       = aws_iam_role.api_lambda.name
  policy_arn = aws_iam_policy.upload_to_proteins_policy.arn
}

resource "aws_iam_role_policy_attachment" "read_proteins_policy_attachment" {
  role       = aws_iam_role.api_lambda.name
  policy_arn = aws_iam_policy.read_proteins_policy.arn
}

# define main lambda
resource "aws_lambda_function" "mainv2" {
  function_name = local.function_name
  handler       = "index.handler"
  role          = aws_iam_role.api_lambda.arn
  runtime       = "nodejs12.x"
  s3_bucket     = "df-api"
  s3_key        = "api.zip"
}

resource "aws_apigatewayv2_integration" "default" {
  api_id           = aws_apigatewayv2_api.df-api.id
  integration_type = "AWS_PROXY"

  connection_type           = "INTERNET"
  content_handling_strategy = "CONVERT_TO_TEXT"
  description               = "Lambda"
  integration_method        = "POST"
  integration_uri           = aws_lambda_function.mainv2.invoke_arn
  passthrough_behavior      = "WHEN_NO_MATCH"
}
resource "aws_lambda_permission" "default" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.mainv2.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.df-api.execution_arn}/*/*"
}

## Logging: create group with 30 days retention, THEN create the lambda, and allow it to publish
resource "aws_cloudwatch_log_group" "api_lambda" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 30
}
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  depends_on = [aws_cloudwatch_log_group.api_lambda] // ensure that the log group exists before the role can be exported and used
  role       = aws_iam_role.api_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
