# Test the workspace created by ../
# * tf init
# * select 1. dev
# * tf apply

terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "hc-crt-private-ci-runners"

    workspaces {
      prefix = "test-agent-"
    }
  }
}

variable "TFC_RUN_ID" {
  type        = string
  description = "Current TFC run ID. Used as part of the AWS provider's assume role session name argument. Set to a placeholder default to allow for non-TFE runs to occur when needed."
  default     = "TFC_RUN_ID_DEFAULT"
}

data "terraform_remote_state" "agents" {
  backend = "remote"

  config = {
    organization = "hc-crt-private-ci-runners"
    workspaces = {
      name = "tfc-agents-dev"
    }
  }
}

provider "aws" {
  region = "us-west-2"

  assume_role {
    role_arn     = data.terraform_remote_state.agents.outputs.tf_manage_iam_role_arn
    session_name = var.TFC_RUN_ID
  }
}

data "aws_caller_identity" "current" {}

output "whoami" {
  value = data.aws_caller_identity.current
}
