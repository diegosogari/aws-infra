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

  demo_app = {
    hostname = lookup(var.demo_app_dynamic_config, "hostname", "demo")

    layers = merge({
      for key, val in local.default_app_config.layers :
      key => merge(val, lookup(lookup(var.demo_app_dynamic_config, "layers", {}), key, {}))
      }, {
      for key, val in lookup(var.demo_app_dynamic_config, "layers", {}) :
      key => merge(lookup(local.default_app_config.layers, key, {}), val)
    })

    functions = merge({
      for key, val in local.default_app_config.functions :
      key => merge(val, lookup(lookup(var.demo_app_dynamic_config, "functions", {}), key, {}))
      }, {
      for key, val in lookup(var.demo_app_dynamic_config, "functions", {}) :
      key => merge(lookup(local.default_app_config.functions, key, {}), val)
    })
  }

  default_app_config = {
    layers = {
      for name in ["dependencies"] :
      name => {
        package_hash = ""
        runtimes     = ["python3.10"]
      }
    }

    functions = {
      for name in [
        "request_handler",
        "command_handler",
        "event_publisher",
        "event_consumer"
      ] :
      name => {
        runtime        = "python3.10"
        handler        = "${name}.handle"
        package_hash   = ""
        stable_version = ""
        traffic_shift  = 0.2
        log_retention  = 14
        environment    = {}
        used_layers    = ["dependencies"]
      }
    }
  }
}
