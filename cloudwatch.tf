resource "aws_cloudwatch_log_group" "demo" {
  name              = "/aws/lambda/${local.demo_app.name}"
  retention_in_days = local.demo_app.log_retention
}

resource "aws_cloudwatch_log_group" "demo_event_publisher" {
  name              = "/aws/lambda/${local.demo_app.name}-event-publisher"
  retention_in_days = local.demo_app.log_retention
}
