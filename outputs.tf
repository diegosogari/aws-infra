output "tfc_role_arn" {
  value = aws_iam_role.tfc_role.arn
}

output "lambda_bucket_id" {
  value = aws_s3_bucket.lambda.id
}

output "demo_function_version" {
  value = aws_lambda_alias.demo.function_version
}