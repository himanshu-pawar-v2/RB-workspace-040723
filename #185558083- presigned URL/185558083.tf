provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "bucket" {
  bucket = "bucket-for-rb-01"
  acl    = "private"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "api_gateway_role" {
  name = "api-to-bucket-upload-01"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "s3_policy" {
  name        = "policy-for-apigw-to-s3-0507"
  description = "Policy for API Gateway to S3 upload"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VisualEditor0",
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::rb-ws-url-csv/*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "api_gateway_s3_policy_attachment" {
  policy_arn = aws_iam_policy.s3_policy.arn
  role       = aws_iam_role.api_gateway_role.name
}

resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = "rb-apigateway-0507"
  description = "API Gateway for S3 upload"
}

resource "aws_api_gateway_resource" "bucket_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "{bucket}"
}

resource "aws_api_gateway_resource" "filename_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_resource.bucket_resource.id
  path_part   = "{filename}"
}

resource "aws_api_gateway_method" "put_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.filename_resource.id
  http_method   = "PUT"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "s3_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.filename_resource.id
  http_method             = aws_api_gateway_method.put_method.http_method
  integration_http_method = "PUT"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:us-east-1:s3:path/{bucket}/{key}"
  credentials             = "arn:aws:iam::370180090626:role/role-for-apigw-0507"
}

resource "aws_api_gateway_method_response" "method_response" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.filename_resource.id
  http_method = aws_api_gateway_method.put_method.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.filename_resource.id
  http_method = aws_api_gateway_method.put_method.http_method
  status_code = aws_api_gateway_method_response.method_response.status_code
}

resource "aws_api_gateway_stage" "stage" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "rb-s3upload-0507"
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = aws_api_gateway_stage.stage.stage_name
}

resource "aws_api_gateway_api_key" "api_key" {
  name = "key-for-s3"
}

resource "aws_api_gateway_usage_plan" "usage_plan" {
  name          = "plan-for-s3"
  api_stages {
    api_id   = aws_api_gateway_rest_api.api_gateway.id
    stage    = aws_api_gateway_stage.stage.stage_name
  }
  quota {
    limit    = 1000000
    offset   = 0
    period   = "MONTH"
  }
  throttle {
    burst_limit       = 500
    rate_limit        = 1000
    period            = "SECOND"
    period_identifier = "API_KEY"
  }
}

resource "aws_api_gateway_usage_plan_key" "usage_plan_key" {
  key_id        = aws_api_gateway_api_key.api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usage_plan.id
}

output "invoke_url" {
  value = aws_api_gateway_deployment.deployment.invoke_url
}
