# IAM Permissions to manage resources in the account

#####
# Terraform Permission Role (AssumeRole)
#####

data "aws_iam_policy_document" "assume_tf_manage" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
    ]
    principals {
      identifiers = [
        aws_iam_role.runtime.arn,
      ]
      type = "AWS"
    }
  }
}

resource "aws_iam_role" "tf_manage" {
  name               = "${var.name}-tf-manage"
  description        = "Role to be assumed by TFC hc-common-release-tooling-vault/* workspaces when accessing/mutating resources."
  assume_role_policy = data.aws_iam_policy_document.assume_tf_manage.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy" "tf_manage_base" {
  role   = aws_iam_role.tf_manage.name
  name   = "ManageBase"
  policy = data.aws_iam_policy_document.tf_manage_base.json
}

data "aws_iam_policy_document" "tf_manage_base" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeAccountAttributes",
      "sts:GetCallerIdentity",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "tf_infra_management" {
  role   = aws_iam_role.tf_manage.name
  name   = "InfrastructureManagement"
  policy = data.aws_iam_policy_document.tf_infra_management.json
}

data "aws_iam_policy_document" "tf_infra_management" {
  statement {
    effect = "Allow"
    # TODO: revisit these permissions and pare them down to what is specifically required before shipping our MVP, etc.
    actions = [
      "acm:*",
      "autoscaling:*",
      "ec2:*",
      "elasticloadbalancing:*",
      "iam:*",
      "kms:*",
      "logs:*",
      "ecs:*",
      "route53:*",
      "secretsmanager:*",
    ]
    resources = ["*"]
  }
}
