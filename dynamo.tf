resource "aws_dynamodb_table" "demo_profiles" {
  name           = "demo-profiles"
  billing_mode   = "PROVISIONED"
  read_capacity  = 10
  write_capacity = 10
  hash_key       = "ProfileId"
  range_key      = "UpdatedAt"

  attribute {
    name = "ProfileId"
    type = "S"
  }

  attribute {
    name = "UpdatedAt"
    type = "N"
  }
}

resource "aws_dynamodb_table" "demo_submissions" {
  name           = "demo-submissions"
  billing_mode   = "PROVISIONED"
  read_capacity  = 10
  write_capacity = 10
  hash_key       = "SubmissionId"
  range_key      = "UpdatedAt"

  attribute {
    name = "SubmissionId"
    type = "S"
  }

  attribute {
    name = "UpdatedAt"
    type = "N"
  }
}

locals {
  demo_tables = [
    aws_dynamodb_table.demo_profiles.arn,
    aws_dynamodb_table.demo_submissions.arn
  ]
}