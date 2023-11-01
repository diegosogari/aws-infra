resource "aws_s3_bucket" "alb_logs" {
  bucket_prefix = "alb-logs-"
}

resource "aws_security_group" "alb" {
  name = "alb"
  description = "SG for ALB"
  vpc_id = aws_default_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "alb" {
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
