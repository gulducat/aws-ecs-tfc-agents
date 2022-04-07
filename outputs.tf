output "runtime_iam_role_arn" {
  description = "Role that can assume other roles at runtime."
  value       = aws_iam_role.runtime.arn
}

output "security_groups" {
  description = "Security groups associated with ECS cluster."
  value       = local.security_groups
}

output "vpc_id" {
  description = "VPC ID associated with ECS cluster. If create_vpc is false, output is an empty string."
  value       = var.create_vpc ? module.vpc[0].vpc_id : ""
}
