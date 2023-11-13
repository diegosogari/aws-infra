resource "aws_lambda_function" "demo" {
  function_name    = local.demo_app.name
  role             = aws_iam_role.demo.arn
  handler          = local.demo_app.handler
  runtime          = local.demo_app.runtime
  s3_bucket        = aws_s3_bucket.lambda.id
  s3_key           = local.demo_app.pkg_key
  source_code_hash = coalesce(local.demo_app.pkg_hash, aws_s3_object.demo.checksum_sha256)
  publish          = true # for use with alias

  environment {
    variables = {
      USER_POOL_ENDPOINT = aws_cognito_user_pool.default.endpoint
    }
  }
}

resource "aws_lambda_alias" "demo" {
  name             = local.demo_app.name
  function_name    = aws_lambda_function.demo.arn
  function_version = local.demo_stable

  dynamic "routing_config" {
    for_each = local.demo_current > 1 ? [1] : []

    content {
      additional_version_weights = {
        (local.demo_current) = local.demo_app.traffic_shift
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

resource "aws_lambda_layer_version" "demo" {
  layer_name       = local.demo_app.name
  s3_bucket        = aws_s3_bucket.lambda.id
  s3_key           = local.demo_app.deps_key
  source_code_hash = coalesce(local.demo_app.deps_hash, aws_s3_object.demo_deps.checksum_sha256)

  compatible_runtimes = [local.demo_app.runtime]
}