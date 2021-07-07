output "runtime_iam_role_arn" {
  description = "Role that can assume other roles at runtime."
  value       = aws_iam_role.runtime.arn
}
