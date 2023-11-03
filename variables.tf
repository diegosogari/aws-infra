variable "tfc_aws_audience" {
  type        = string
  default     = "aws.workload.identity"
  description = "The audience value to use in run identity tokens"
}

variable "tfc_hostname" {
  type        = string
  default     = "app.terraform.io"
  description = "The hostname of the TFC or TFE instance you'd like to use with AWS"
}

variable "tfc_organization_name" {
  type        = string
  default     = "sogari"
  description = "The name of your Terraform Cloud organization"
}

variable "tfc_project_name" {
  type        = string
  default     = "Default Project"
  description = "The project under which a workspace will be created"
}

variable "tfc_workspace_name" {
  type        = string
  default     = "aws-infra"
  description = "The name of the workspace that you'd like to create and connect to AWS"
}

variable "az_count" {
  type        = number
  default     = 2
  description = "The number of availability zones"
}

variable "public_domain" {
  type        = string
  default     = "sogari.dev"
  description = "The public domain name for DNS"
}

variable "acme_url" {
  type        = string
  default     = "https://acme-v02.api.letsencrypt.org/directory"
  description = "The URL to the ACME endpoint's directory"
}

variable "acme_email" {
  type        = string
  default     = "diego.sogari@gmail.com"
  description = "The contact email address for the ACME account"
}

variable "demo_app" {
  type = object({
    name    = optional(string, "demo")
    handler = optional(string, "handler")
    runtime = optional(string, "provided.al2")
    key     = optional(string, "demo.zip")
    hash    = optional(string)      # base64sha256 of the new zip package
    shift   = optional(number, 0.2) # use zero for rollback
    version = optional(string)      # stable version (defaults to the previous)
    log_ret = optional(number, 14)  # log retention in days
  })
  default = {}

  validation {
    condition     = var.demo_app.shift >= 0 && var.demo_app.shift <= 1
    error_message = "traffic shift percentage must be between 0 and 1"
  }
}
