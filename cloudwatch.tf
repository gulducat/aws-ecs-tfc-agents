resource "aws_cloudwatch_log_group" "tfc_agent" {
  name              = "/hc/ecs-task/${var.name}"
  retention_in_days = 7
  tags              = local.common_tags
}
