# General

variable "name" {
  type        = string
  description = "Name prefix to add to the resources."
  default     = "tfc-agent"
}

variable "common_tags" {
  type        = map(string)
  description = "Tags to apply to all resources."
  default     = {}
}

# VPC

variable "create_vpc" {
  type        = bool
  description = "If true, create a VPC to place resources in."
  default     = false
}

variable "vpc_cidr" {
  type        = string
  description = "If creating a VPC, use this CIDR."
  default     = "10.0.0.0/20"
}

variable "private_subnets" {
  type        = list(string)
  description = "If *not* creating a VPC, use these VPC subnets."
  default     = [""]
}

variable "security_groups" {
  type        = list(string)
  description = "If *not* creating a VPC, use these VPC security groups."
  default     = [""]
}

# ECS

variable "capacity_providers" {
  type        = list(string)
  description = "ECS capacity providers."
  default     = ["FARGATE_SPOT"]
}

variable "cpu_count" {
  type        = string
  description = "vCPU count (default 2)"
  default     = 2
}

variable "num_agents" {
  type        = number
  description = "Number of parallel tasks"
  default     = 2 # one for plan, another for apply
}

variable "tfc_agent_image" {
  type        = string
  description = "TFC agent docker image. Be mindful of docker hub rate limits"
  default     = "tfc-agent:latest"
}

variable "tfc_agent_env_vars" {
  type        = list(object({ name = string, value = string }))
  description = "A list of environment variables that should be present on each TFC agent."
  default = [
    {
      name  = "TFC_AGENT_DISABLE_UPDATE"
      value = "true"
    },
    {
      name  = "TFC_AGENT_SINGLE"
      value = "true"
    },
    {
      name  = "TFC_AGENT_LOG_LEVEL"
      value = "info"
    }
  ]
}

# IAM and secrets

variable "allow_assume_role_arns" {
  type        = list(string)
  description = "List of IAM role ARNs that ECS tasks are allowed to assume."
  default     = ["*"]
}

variable "tfc_agent_token_param_name" {
  type        = string
  description = "SSM parameter store path containing the Terraform Cloud agent token to launch our agent ECS tasks with. (TFC Organization Settings >> Agents)"
  default     = "app.terraform.io/tfc-agent"
}

# Various locals

locals {
  cloudwatch_log_group = "/ecs-task/${var.name}"

  tfc_agent_token_parameter_arn = join(":", [
    "arn",
    data.aws_partition.current.partition,
    "ssm",
    data.aws_region.current.name,
    data.aws_caller_identity.current.account_id,
    "parameter/${var.tfc_agent_token_param_name}"
  ])

  cpu    = 1024 * var.cpu_count
  memory = local.cpu * 2 # memory must be minimum-double CPU
}
