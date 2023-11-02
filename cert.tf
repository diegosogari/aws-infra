resource "terraform_data" "acme_url" {
  input = var.acme_url
}

resource "tls_private_key" "acme" {
  algorithm = "RSA"

  lifecycle {
    replace_triggered_by = [terraform_data.acme_url]
  }
}

resource "acme_registration" "default" {
  account_key_pem = tls_private_key.acme.private_key_pem
  email_address   = var.acme_email
}

resource "acme_certificate" "default" {
  account_key_pem = acme_registration.default.account_key_pem
  common_name     = "*.${var.public_domain}"

  dns_challenge {
    provider = "namecheap"
  }
}

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

resource "aws_acm_certificate" "default" {
  private_key       = acme_certificate.default.private_key_pem
  certificate_body  = acme_certificate.default.certificate_pem
  certificate_chain = acme_certificate.default.issuer_pem
}
