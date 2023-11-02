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

# for OIDC authentication
resource "aws_vpc_security_group_egress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
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

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.default.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.default.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "login" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 1

  action {
    type  = "authenticate-cognito"
    order = 1

    authenticate_cognito {
      user_pool_arn              = aws_cognito_user_pool.default.arn
      user_pool_client_id        = aws_cognito_user_pool_client.default.id
      user_pool_domain           = aws_cognito_user_pool_domain.default.domain
      on_unauthenticated_request = "authenticate"
      scope                      = "openid email"
    }
  }

  action {
    type  = "fixed-response"
    order = 2

    fixed_response {
      content_type = "text/html"
      message_body = "<!DOCTYPE html><html><body onload=\"document.body.innerHTML=document.cookie\"</body></html>"
      status_code  = "200"
    }
  }

  condition {
    path_pattern {
      values = ["/login"]
    }
  }
}
