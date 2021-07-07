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
  default     = "tfc-agent"
}

variable "tfc_agent_token_param_name" {
  type        = string
  description = "SSM parameter store path containing the Terraform Cloud agent token to launch our agent ECS tasks with. (TFC Organization Settings >> Agents)"
  default     = "app.terraform.io/tfc-agent"
}

variable "private_subnets" {
  type = list(string)
  description = "Private VPC subnets to deploy tfc-agent ECS service."
}

variable "security_groups" {
  type = list(string)
  description = "Security group IDs"
}

variable "cpu_count" {
  type        = string
  description = "vCPU count (default 2)"
  default     = 2
}

locals {
  cloudwatch_log_group = "/ecs-task/${var.name}"

  tfc_agent_token_parameter_arn = "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.tfc_agent_token_param_name}"

  cpu    = 1024 * var.cpu_count
  memory = local.cpu * 2 # memory must be minimum-double CPU
}

variable "allow_assume_role_arn" {
  type        = list(string)
  description = "List of IAM role ARNs that ECS tasks are allowed to assume."
  default     = ["*"]
}
