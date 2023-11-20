resource "aws_cloudwatch_log_group" "demo" {
  for_each          = local.demo_app.functions
  name              = "/aws/lambda/demo-${each.key}"
  retention_in_days = each.value.log_retention
}
