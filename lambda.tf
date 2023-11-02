resource "aws_s3_bucket" "lambda" {
  bucket_prefix = "lambda-"
}

resource "aws_s3_bucket_versioning" "lambda" {
  bucket = aws_s3_bucket.lambda.id

  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "lambda" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda_logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}
