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
  key                = local.demo_app.pkg_key
  content            = "content"
  checksum_algorithm = "SHA256"
}

resource "aws_s3_object" "demo_deps" {
  bucket             = aws_s3_bucket.lambda.id
  key                = local.demo_app.deps_key
  content            = "content"
  checksum_algorithm = "SHA256"
}
