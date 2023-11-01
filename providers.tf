terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.23.1"
    }
    acme = {
      source  = "vancluever/acme"
      version = "2.18.0"
    }
    namecheap = {
      source  = "namecheap/namecheap"
      version = "2.1.0"
    }
  }

  backend "remote" {
    organization = "sogari"

    workspaces {
      name = "aws-infra"
    }
  }
}

provider "aws" {
}

provider "acme" {
  server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
}

provider "namecheap" {
}