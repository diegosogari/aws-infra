resource "aws_cloudwatch_log_group" "demo" {
  name              = "/aws/lambda/${var.demo_app.name}"
  retention_in_days = var.demo_app.log_ret
}

data "aws_iam_policy_document" "demo" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.demo.arn}:*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["dynamodb:*"]
    resources = local.demo_tables
  }
}

resource "aws_iam_role" "demo" {
  name               = var.demo_app.name
  assume_role_policy = data.aws_iam_policy_document.lambda.json

  inline_policy {
    policy = data.aws_iam_policy_document.demo.json
  }
}

resource "aws_s3_object" "demo" {
  bucket             = aws_s3_bucket.lambda.id
  key                = var.demo_app.key
  source             = data.archive_file.lambda_custom.output_path
  checksum_algorithm = "SHA256"
}

resource "aws_lambda_function" "demo" {
  function_name    = var.demo_app.name
  role             = aws_iam_role.demo.arn
  handler          = var.demo_app.handler
  runtime          = var.demo_app.runtime
  s3_bucket        = aws_s3_bucket.lambda.id
  s3_key           = var.demo_app.key
  source_code_hash = coalesce(var.demo_app.hash, aws_s3_object.demo.checksum_sha256)
  publish          = true # for use with alias
}

locals {
  demo_previous_version = tostring(max(1, tonumber(aws_lambda_function.demo.version) - 1))
}

resource "aws_lambda_alias" "demo" {
  name             = var.demo_app.name
  function_name    = aws_lambda_function.demo.arn
  function_version = coalesce(var.demo_app.version, local.demo_previous_version)

  dynamic "routing_config" {
    for_each = aws_lambda_function.demo.version > 1 ? [1] : []

    content {
      additional_version_weights = {
        (aws_lambda_function.demo.version) = var.demo_app.shift
      }
    }
  }
}

resource "aws_lb_target_group" "demo" {
  name        = var.demo_app.name
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

resource "aws_lb_listener_rule" "demo" {
  listener_arn = aws_lb_listener.https.arn
  priority     = var.demo_app.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.demo.arn
  }

  condition {
    host_header {
      values = ["${var.demo_app.name}.${var.public_domain}"]
    }
  }
}