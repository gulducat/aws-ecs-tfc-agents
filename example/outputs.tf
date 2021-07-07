output "tf_manage_iam_role_arn" {
  description = "Role to be assumed by TFC workspaces when managing resources."
  value       = aws_iam_role.tf_manage.arn
}
