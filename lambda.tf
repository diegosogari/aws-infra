resource "aws_lambda_layer_version" "demo" {
  layer_name       = local.demo_app.name
  s3_bucket        = aws_s3_bucket.lambda.id
  s3_key           = local.demo_app.deps_key
  source_code_hash = coalesce(local.demo_app.deps_hash, aws_s3_object.demo_deps.checksum_sha256)

  compatible_runtimes = [local.demo_app.runtime]
}

resource "aws_lambda_function" "demo" {
  function_name    = local.demo_app.name
  role             = aws_iam_role.demo.arn
  handler          = local.demo_app.handler
  runtime          = local.demo_app.runtime
  s3_bucket        = aws_s3_bucket.lambda.id
  s3_key           = local.demo_app.pkg_key
  source_code_hash = coalesce(local.demo_app.pkg_hash, aws_s3_object.demo.checksum_sha256)
  publish          = true # for use with alias

  layers = [aws_lambda_layer_version.demo.arn]

  environment {
    variables = merge(local.demo_app.environment, {
      USER_POOL_ENDPOINT = aws_cognito_user_pool.default.endpoint
    })
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

resource "aws_lambda_function" "demo_event_publisher" {
  function_name    = "${local.demo_app.name}-event-publisher"
  role             = aws_iam_role.demo_event_publisher.arn
  handler          = local.demo_app.handler
  runtime          = local.demo_app.runtime
  s3_bucket        = aws_s3_bucket.lambda.id
  s3_key           = local.demo_app.events_key
  source_code_hash = coalesce(local.demo_app.events_hash, aws_s3_object.demo_event_publisher.checksum_sha256)
}

resource "aws_lambda_event_source_mapping" "demo" {
  event_source_arn  = aws_dynamodb_table.demo_events.stream_arn
  function_name     = aws_lambda_function.demo_event_publisher.arn
  starting_position = "LATEST"
}