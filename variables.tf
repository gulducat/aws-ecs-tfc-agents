variable "aws_account_name" {
  description = "AWS Account Name - used in Agent Name in TFC UI"
}

variable "aws_assume_role_arn" {
  type        = string
  description = "The IAM role ARN to be assumed in the AWS provider arguments / used to manage AWS resources' lifecycles."
}

variable "common_tags" {
  type        = map(string)
  description = "Tags to apply to all resources."
  default     = {}
}

variable "desired_count" {
  description = "Number of parallel tasks"
  default     = 1
}

variable "name" {
  type        = string
  description = "Name prefix to add to the resources"
  default     = "tfc-agent_hc-crt-vault"
}

variable "region" {
  type        = string
  description = "AWS Region to operate resoureces from"
  default     = "us-west-2"
}

variable "tfc_agent_token_param_name" {
  type        = string
  description = "SSM parameter store path containing the Terraform Cloud agent token to launch our agent ECS tasks with. (TFC Organization Settings >> Agents)"
  default     = "tfc-agent/app.terraform.io/hc-common-release-tooling-vault/tfc-agent"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR range to provision the TFC agents / ECS VPC with."
  default     = "10.0.0.0/20"
}

locals {
  tfc_agent_token_parameter_arn = "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.tfc_agent_token_param_name}"

  cpu    = 1024 * 2      # vCPU count
  memory = local.cpu * 2 # memory must be minimum-double CPU
}

variable "TFC_RUN_ID" {
  type        = string
  description = "Current TFE(C) run ID. Used as part of the AWS provider's assume role session name argument. Set to a placeholder default to allow for non-TFE runs to occur when needed."
  default     = "TFC_RUN_ID_DEFAULT"
}
