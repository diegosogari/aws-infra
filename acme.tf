## Registrations

resource "acme_registration" "default" {
  account_key_pem = tls_private_key.acme.private_key_pem
  email_address   = var.acme_email
}

## Certificates

resource "acme_certificate" "default" {
  account_key_pem = acme_registration.default.account_key_pem
  common_name     = "*.${var.public_domain}"

  dns_challenge {
    provider = "namecheap"
  }
}
