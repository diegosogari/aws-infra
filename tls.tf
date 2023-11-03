## Certificates

data "tls_certificate" "tfc_certificate" {
  url = "https://${local.tfc_oidc.hostname}"
}

data "tls_certificate" "gha_certificate" {
  url = "https://${local.gha_oidc.hostname}"
}

## Private keys

resource "tls_private_key" "acme" {
  algorithm = "RSA"

  lifecycle {
    replace_triggered_by = [terraform_data.acme_url]
  }
}

resource "terraform_data" "acme_url" {
  input = local.acme_url
}
