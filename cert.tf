resource "tls_private_key" "acme" {
  algorithm = "RSA"
}

resource "acme_registration" "default" {
  account_key_pem = tls_private_key.acme.private_key_pem
  email_address   = "diego.sogari@gmail.com"
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
}