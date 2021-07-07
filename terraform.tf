terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "hc-common-release-tooling-vault"

    workspaces {
      prefix = "tfc-agents-"
    }
  }
}

provider "aws" {
  region = var.region
  assume_role {
    role_arn     = var.aws_assume_role_arn
    session_name = var.TFC_RUN_ID
  }
}
