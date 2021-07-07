output "tf_manage_iam_role_arn" {
  description = "Role to be assumed by TFC hc-common-release-tooling-vault/* workspaces when accessing/mutating resources."
  value       = aws_iam_role.tf_manage.arn
}
