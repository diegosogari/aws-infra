resource "aws_lambda_layer_version" "demo" {
  for_each   = var.demo_config.layers
  layer_name = "demo-${each.key}"
  s3_bucket  = aws_s3_bucket.lambda.id
  s3_key     = aws_s3_object.demo_layers[each.key].key

  source_code_hash = coalesce(
    each.value.package_hash,
    aws_s3_object.demo_layers[each.key].checksum_sha256
  )

  compatible_runtimes = each.value.runtimes
}

resource "aws_lambda_function" "demo" {
  for_each      = var.demo_config.functions
  function_name = "demo-${each.key}"
  role          = aws_iam_role.demo_app[each.key].arn
  handler       = strcontains(each.value.handler, "%s") ? format(each.value.handler, each.key) : each.value.handler
  runtime       = each.value.runtime
  s3_bucket     = aws_s3_bucket.lambda.id
  s3_key        = aws_s3_object.demo_functions[each.key].key
  publish       = true # for use with alias

  source_code_hash = coalesce(
    each.value.package_hash,
    aws_s3_object.demo_functions[each.key].checksum_sha256
  )

  layers = each.value.used_layers == null ? [
    for _, layer in aws_lambda_layer_version.demo : layer.arn
  ] : [
    for key, layer in aws_lambda_layer_version.demo :
    layer.arn if contains(each.value.used_layers, key)
  ]

  environment {
    variables = merge(each.value.environment, each.value.load_balanced ? {
      USER_POOL_ENDPOINT = aws_cognito_user_pool.default.endpoint
    } : {})
  }
}

resource "aws_lambda_alias" "demo" {
  for_each      = var.demo_config.functions
  name          = "demo-${each.key}"
  function_name = aws_lambda_function.demo[each.key].arn

  function_version = coalesce(
    each.value.stable_version,
    tostring(max(1, tonumber(aws_lambda_function.demo[each.key].version) - 1))
  )

  dynamic "routing_config" {
    for_each = aws_lambda_function.demo[each.key].version > 1 ? [1] : []

    content {
      additional_version_weights = {
        (aws_lambda_function.demo[each.key].version) = each.value.traffic_shift
      }
    }
  }
}

resource "aws_lambda_permission" "demo" {
  for_each = toset([
    for key, val in var.demo_config.functions : key if val.load_balanced
  ])
  statement_id  = "AllowExecutionFromALB"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.demo[each.key].function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.demo.arn
  qualifier     = aws_lambda_alias.demo[each.key].name
}

resource "aws_lambda_event_source_mapping" "demo" {
  for_each = toset([
    for key, val in var.demo_config.functions : key if val.publish_events
  ])
  event_source_arn  = aws_dynamodb_table.demo_events.stream_arn
  function_name     = aws_lambda_function.demo[each.key].arn
  starting_position = "LATEST"
}