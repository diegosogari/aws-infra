## Domain records

resource "namecheap_domain_records" "default" {
  domain = var.public_domain

  record {
    hostname = "*"
    type     = "ALIAS"
    address  = aws_lb.default.dns_name
    ttl      = 300
  }

  record {
    hostname = "auth"
    type     = "ALIAS"
    address  = aws_cognito_user_pool_domain.default.cloudfront_distribution
    ttl      = 300
  }
}
