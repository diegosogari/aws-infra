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

data "archive_file" "dummy_zip" {
  type        = "zip"
  output_path = "dummy.zip"

  source {
    content  = "content"
    filename = "filename"
  }
}

resource "terraform_data" "dummy_revision" {
  input = data.archive_file.dummy_zip.output_md5
}

resource "aws_s3_object" "demo_layers" {
  for_each = local.demo_app.layers
  bucket   = aws_s3_bucket.lambda.id
  key      = "demo-layer-${each.key}.zip"
  source   = data.archive_file.dummy_zip.output_path

  checksum_algorithm = "SHA256"

  lifecycle {
    replace_triggered_by = [terraform_data.dummy_revision]
  }
}

resource "aws_s3_object" "demo_functions" {
  for_each = local.demo_app.functions
  bucket   = aws_s3_bucket.lambda.id
  key      = "demo-function-${each.key}.zip"
  source   = data.archive_file.dummy_zip.output_path

  checksum_algorithm = "SHA256"

  lifecycle {
    replace_triggered_by = [terraform_data.dummy_revision]
  }
}
