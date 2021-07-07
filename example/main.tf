# setup steps:
# * edit var.tfc_org and terraform{backend{ organization }}
#   as appropriate to match your TFC organization
# * tf workspace new dev
#   creates a workspace in TFC
# * edit settings in "tfc-agents-dev" workspace in TFC
#   Settings -> General -> Execution Mode -> Local
#   and
#   Remote state sharing -> Share state globally
# * tf init
# * tf apply

terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "hc-crt-private-ci-runners"

    workspaces {
      prefix = "tfc-agents-"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}

# when running locally, set TFE_TOKEN env var, e.g.
# export TFE_TOKEN="$(jq -r '.credentials."app.terraform.io".token' ~/.terraform.d/credentials.tfrc.json)"
provider "tfe" {}

resource "aws_ssm_parameter" "runner_token" {
  name        = "/${local.token_ssm_path}"
  description = "TFC agent token for ${var.name}"
  type        = "SecureString"
  value       = tfe_agent_token.token.token
}

module "ecs" {
  source = "../"
  name   = var.name

  create_vpc = true

  tfc_agent_token_param_name = local.token_ssm_path
  allow_assume_role_arns     = [aws_iam_role.tf_manage.arn]
}
