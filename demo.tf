data "aws_iam_policy_document" "demo" {
  source_policy_documents = [data.aws_iam_policy_document.lambda_logs.json]

  statement {
    effect  = "Allow"
    actions = ["dynamodb:*"]
    resources = [
      aws_dynamodb_table.demo_profiles.arn,
      aws_dynamodb_table.demo_submissions.arn
    ]
  }
}

resource "aws_iam_role" "demo" {
  name               = "demo-role"
  assume_role_policy = data.aws_iam_policy_document.lambda.json

  inline_policy {
    name   = "demo-policy"
    policy = data.aws_iam_policy_document.demo.json
  }
}

resource "aws_s3_object" "demo_dummy" {
  bucket             = aws_s3_bucket.lambda.id
  key                = var.demo_pkg.key
  source             = data.archive_file.lambda_dummy.output_path
  checksum_algorithm = "SHA256"
}

resource "aws_lambda_function" "demo" {
  function_name    = "demo"
  role             = aws_iam_role.demo.arn
  handler          = var.demo_pkg.handler
  runtime          = var.demo_pkg.runtime
  s3_bucket        = aws_s3_bucket.lambda.id
  s3_key           = var.demo_pkg.key
  source_code_hash = coalesce(var.demo_pkg.hash, aws_s3_object.demo_dummy.checksum_sha256)
  publish          = true # for use with alias
}

locals {
  demo_previous_version = tostring(max(1, tonumber(aws_lambda_function.demo.version) - 1))
}

resource "aws_lambda_alias" "demo" {
  name             = "demo"
  function_name    = aws_lambda_function.demo.arn
  function_version = coalesce(var.demo_pkg.version, local.demo_previous_version)

  dynamic "routing_config" {
    for_each = aws_lambda_function.demo.version > 1 ? [1] : []

    content {
      additional_version_weights = {
        (aws_lambda_function.demo.version) = var.demo_pkg.shift
      }
    }
  }
}

resource "aws_lb_target_group" "demo" {
  name        = "demo"
  target_type = "lambda"
}

resource "aws_lambda_permission" "demo" {
  statement_id  = "AllowExecutionFromALB"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.demo.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.demo.arn
  qualifier     = aws_lambda_alias.demo.name
}

resource "aws_lb_target_group_attachment" "demo" {
  target_group_arn = aws_lb_target_group.demo.arn
  target_id        = aws_lambda_alias.demo.arn
  depends_on       = [aws_lambda_permission.demo]
}

resource "aws_lb_listener_rule" "host_based_weighted_routing" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.demo.arn
  }

  condition {
    host_header {
      values = ["demo.${var.public_domain}"]
    }
  }
}