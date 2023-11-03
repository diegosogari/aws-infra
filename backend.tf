terraform {
  backend "remote" {
    organization = "sogari"

    workspaces {
      name = "aws-infra"
    }
  }
}