data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  az_count      = 2
  available_azs = data.aws_availability_zones.available.names
  public_domain = "sogari.dev"
  callback_urls = formatlist("https://%s.${local.public_domain}/oauth2/idpresponse", ["auth", "demo"])
  acme_url      = "https://acme-v02.api.letsencrypt.org/directory"
  acme_email    = "diego.sogari@gmail.com"

  tfc_oidc = {
    audience  = "aws.workload.identity"
    hostname  = "app.terraform.io"
    org_name  = "sogari"
    proj_name = "Default Project"
    workspace = "aws-infra"
  }

  gha_oidc = {
    audience  = "sts.amazonaws.com"
    hostname  = "token.actions.githubusercontent.com"
    org_name  = "diegosogari"
    repo_name = "*"
    branch    = "main"
  }

  demo_app = var.demo_app_dynamic_config
}
