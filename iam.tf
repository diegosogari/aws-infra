## OIDC providers

resource "aws_iam_openid_connect_provider" "tfc_provider" {
  url             = data.tls_certificate.tfc_certificate.url
  client_id_list  = [var.tfc_aws_audience]
  thumbprint_list = [data.tls_certificate.tfc_certificate.certificates[0].sha1_fingerprint]
}

## Roles

resource "aws_iam_role" "tfc_role" {
  name               = "tfc"
  assume_role_policy = data.aws_iam_policy_document.tfc_role_policy.json

  inline_policy {
    name   = "tfc" # required
    policy = data.aws_iam_policy_document.tfc_policy.json
  }
}

resource "aws_iam_role" "demo" {
  name               = var.demo_app.name
  assume_role_policy = data.aws_iam_policy_document.lambda.json

  inline_policy {
    name   = var.demo_app.name # required
    policy = data.aws_iam_policy_document.demo.json
  }
}

## Policies

data "aws_elb_service_account" "default" {}

data "aws_iam_policy_document" "alb_logs" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.default.arn]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.alb_logs.arn}/*"]
  }
}

data "aws_iam_policy_document" "lambda" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "tfc_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["${aws_iam_openid_connect_provider.tfc_provider.arn}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.tfc_hostname}:aud"
      values   = ["${one(aws_iam_openid_connect_provider.tfc_provider.client_id_list)}"]
    }

    condition {
      test     = "StringLike"
      variable = "${var.tfc_hostname}:sub"
      values   = ["organization:${var.tfc_organization_name}:project:${var.tfc_project_name}:workspace:${var.tfc_workspace_name}:run_phase:*"]
    }
  }
}

data "aws_iam_policy_document" "tfc_policy" {
  statement {
    effect      = "Allow"
    not_actions = ["organizations:*", "account:*"]
    resources   = ["*"]
  }
}

data "aws_iam_policy_document" "demo" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.demo.arn}:*"]
  }

  statement {
    effect  = "Allow"
    actions = ["dynamodb:*"]
    resources = [
      aws_dynamodb_table.demo_profiles.arn,
      aws_dynamodb_table.demo_submissions.arn
    ]
  }
}
