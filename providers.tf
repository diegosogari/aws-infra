terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.26.0"
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
}

provider "aws" {
}

provider "acme" {
  server_url = local.acme_url
}

provider "namecheap" {
}
