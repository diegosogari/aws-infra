## Load balancers

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

## Listeners

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

## Target groups

resource "aws_lb_target_group" "demo" {
  name        = var.demo_app.name
  target_type = "lambda"
}

resource "aws_lb_target_group_attachment" "demo" {
  target_group_arn = aws_lb_target_group.demo.arn
  target_id        = aws_lambda_alias.demo.arn
  depends_on       = [aws_lambda_permission.demo]
}

## Listener rules

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
      status_code  = "200"
    }
  }

  condition {
    path_pattern {
      values = ["/login"]
    }
  }
}

resource "aws_lb_listener_rule" "demo" {
  listener_arn = aws_lb_listener.https.arn

  action {
    type  = "authenticate-cognito"
    order = 1

    authenticate_cognito {
      user_pool_arn              = aws_cognito_user_pool.default.arn
      user_pool_client_id        = aws_cognito_user_pool_client.default.id
      user_pool_domain           = aws_cognito_user_pool_domain.default.domain
      on_unauthenticated_request = "allow"
      scope                      = "openid email"
    }
  }

  action {
    type             = "forward"
    order            = 2
    target_group_arn = aws_lb_target_group.demo.arn
  }

  condition {
    host_header {
      values = ["${var.demo_app.name}.${var.public_domain}"]
    }
  }
}
