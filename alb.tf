resource "aws_s3_bucket" "alb_logs" {
  bucket_prefix = "alb-logs-"
}

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

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  policy = data.aws_iam_policy_document.alb_logs.json
}

resource "aws_security_group" "alb" {
  name        = "alb"
  description = "SG for ALB"
  vpc_id      = aws_default_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}

resource "aws_vpc_security_group_ingress_rule" "alb_icmp" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "icmp"
  from_port   = "-1"
  to_port     = "-1"
}

resource "aws_lb" "default" {
  name               = "default"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_default_subnet.public[*].id

  enable_deletion_protection = true

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.id
    prefix  = "default"
    enabled = true
  }
}
