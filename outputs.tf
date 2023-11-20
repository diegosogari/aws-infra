output "tfc_role_arn" {
  value = aws_iam_role.tfc_role.arn
}

output "gha_role_arn" {
  value = aws_iam_role.gha_role.arn
}

output "lambda_bucket_id" {
  value = aws_s3_bucket.lambda.id
}

output "demo_stable_versions" {
  value = {
    for key, alias in aws_lambda_alias.demo :
    key => alias.function_version
  }
}