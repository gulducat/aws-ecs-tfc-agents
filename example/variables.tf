variable "name" {
  type        = string
  description = "Name to include in resource names"
  default     = "tfc-agents"
}

variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-west-2"
}

variable "tags" {
  type        = map(string)
  description = "Tags for AWS resources"
  default     = {}
}

variable "tfc_org" {
  type        = string
  description = "Name of TFC organization"
  default     = "hc-crt-private-ci-runners"
}

locals {
  token_ssm_path = "${var.name}/tfc-agent-token"
}
