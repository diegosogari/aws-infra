## Certificates

resource "aws_acm_certificate" "default" {
  private_key       = acme_certificate.default.private_key_pem
  certificate_body  = acme_certificate.default.certificate_pem
  certificate_chain = acme_certificate.default.issuer_pem
}
