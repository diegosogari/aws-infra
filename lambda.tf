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

resource "aws_lambda_permission" "demo" {
  statement_id  = "AllowExecutionFromALB"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.demo.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.demo.arn
  qualifier     = aws_lambda_alias.demo.name
}
