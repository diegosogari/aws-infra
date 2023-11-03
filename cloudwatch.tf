resource "aws_cloudwatch_log_group" "demo" {
  name              = "/aws/lambda/${var.demo_app.name}"
  retention_in_days = var.demo_app.log_ret
}
