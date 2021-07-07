resource "aws_cloudwatch_log_group" "tfc_agent" {
  name              = local.cloudwatch_log_group
  retention_in_days = 7
  tags              = var.common_tags
}
