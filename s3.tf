## Buckets

resource "aws_s3_bucket" "lambda" {
  bucket_prefix = "lambda-"
}

resource "aws_s3_bucket" "alb_logs" {
  bucket_prefix = "alb-logs-"
}

## Policies

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  policy = data.aws_iam_policy_document.alb_logs.json
}

## Objects

resource "aws_s3_object" "demo" {
  bucket             = aws_s3_bucket.lambda.id
  key                = var.demo_app.key
  source             = data.archive_file.lambda_custom.output_path
  checksum_algorithm = "SHA256"

  lifecycle {
    replace_triggered_by = [terraform_data.lambda_custom_revision]
  }
}

resource "terraform_data" "lambda_custom_revision" {
  input = data.archive_file.lambda_custom.output_md5
}

data "archive_file" "lambda_custom" {
  type = "zip"

  source {
    # https://docs.aws.amazon.com/lambda/latest/dg/runtimes-walkthrough.html
    # https://docs.aws.amazon.com/apigateway/latest/developerguide/handle-errors-in-lambda-integration.html
    content  = <<EOF
#!/bin/sh

set -euo pipefail

# Processing
while true
do
  HEADERS="$(mktemp)"
  # Get an event. The HTTP request will block until one is received
  EVENT_DATA=$(curl -sS -LD "$HEADERS" "http://$AWS_LAMBDA_RUNTIME_API/2018-06-01/runtime/invocation/next")

  # Extract request ID by scraping response headers received above
  REQUEST_ID=$(grep -Fi Lambda-Runtime-Aws-Request-Id "$HEADERS" | tr -d '[:space:]' | cut -d: -f2)

  # Run the handler function from the script
  echo "$EVENT_DATA" 1>&2;
  RESPONSE="{ \"statusCode\": 200, \"body\": \"Hello from Lambda!\" }"

  # Send the response
  curl "http://$AWS_LAMBDA_RUNTIME_API/2018-06-01/runtime/invocation/$REQUEST_ID/response" -d "$RESPONSE"
done
EOF
    filename = "bootstrap"
  }

  output_file_mode = 755
  output_path      = "function.zip"
}
