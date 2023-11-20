## OIDC providers

resource "aws_iam_openid_connect_provider" "tfc_provider" {
  url             = data.tls_certificate.tfc_certificate.url
  client_id_list  = [local.tfc_oidc.audience]
  thumbprint_list = [data.tls_certificate.tfc_certificate.certificates[0].sha1_fingerprint]
}

resource "aws_iam_openid_connect_provider" "gha_provider" {
  url             = data.tls_certificate.gha_certificate.url
  client_id_list  = [local.gha_oidc.audience]
  thumbprint_list = [data.tls_certificate.gha_certificate.certificates[0].sha1_fingerprint]
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

resource "aws_iam_role" "gha_role" {
  name               = "gha"
  assume_role_policy = data.aws_iam_policy_document.gha_role_policy.json

  inline_policy {
    name   = "gha" # required
    policy = data.aws_iam_policy_document.gha_policy.json
  }
}

resource "aws_iam_role" "demo" {
  name               = local.demo_app.name
  assume_role_policy = data.aws_iam_policy_document.lambda.json

  inline_policy {
    name   = local.demo_app.name # required
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
      variable = "${local.tfc_oidc.hostname}:aud"
      values   = [local.tfc_oidc.audience]
    }

    condition {
      test     = "StringLike"
      variable = "${local.tfc_oidc.hostname}:sub"
      values   = ["organization:${local.tfc_oidc.org_name}:project:${local.tfc_oidc.proj_name}:workspace:${local.tfc_oidc.workspace}:run_phase:*"]
    }
  }
}

data "aws_iam_policy_document" "gha_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["${aws_iam_openid_connect_provider.gha_provider.arn}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.gha_oidc.hostname}:aud"
      values   = [local.gha_oidc.audience]
    }

    condition {
      test     = "StringLike"
      variable = "${local.gha_oidc.hostname}:sub"
      values   = ["repo:${local.gha_oidc.org_name}/${local.gha_oidc.repo_name}:ref:refs/heads/${local.gha_oidc.branch}"]
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

data "aws_iam_policy_document" "gha_policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.lambda.arn}/*"]
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
      aws_dynamodb_table.demo_events.arn,
      aws_dynamodb_table.demo_resources.arn
    ]
  }
}
