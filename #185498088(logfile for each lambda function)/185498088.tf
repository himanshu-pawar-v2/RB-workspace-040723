# There should be one log file per lambda function (in CloudWatch)
provider "aws" {
  region = "us-east-1"
}

resource "aws_lambda_function" "lambda-for-cw-06" {
  function_name = "example-lambda-function"
  runtime = "python3.8" 
  handler = "lambda_function.handler"
  filename = "file_lambda_function.zip"  # input here the path to Lambda function's deployment package
  role = aws_iam_role.lambda_role.arn

  environment {
    variables = {
      AWS_LAMBDA_LOG_STREAM_NAME = "[rb-log-stream-group-g6]"
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_execution_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role = aws_iam_role.lambda_role.name
}

resource "aws_cloudwatch_log_group" "example_log_group" {
  name = "/aws/lambda/${aws_lambda_function.lambda-for-cw-06}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "cw_log_stream" {
  name           = "[rb-log-stream-group-g6]"
  log_group_name = aws_cloudwatch_log_group.cw_log_stream
}

resource "aws_lambda_permission" "allow_cloudwatch_logs" {
  statement_id  = "AllowExecutionFromCloudWatchLogs"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.arn:aws:lambda:us-east-1:370180090626:function:lambda-for-cw-06
  principal     = "logs.amazonaws.com"
  source_arn    = aws_cloudwatch_log_group.arn:aws:logs:us-east-1:370180090626:log-group:/aws/lambda/lambda-for-cw-06:*
}
