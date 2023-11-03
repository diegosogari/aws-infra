## Certificates

data "tls_certificate" "tfc_certificate" {
  url = "https://${var.tfc_hostname}"
}

## Private keys

resource "tls_private_key" "acme" {
  algorithm = "RSA"

  lifecycle {
    replace_triggered_by = [terraform_data.acme_url]
  }
}

resource "terraform_data" "acme_url" {
  input = var.acme_url
}
