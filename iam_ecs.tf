# IAM Permissions used by TFC Agent running in ECS

data "aws_iam_role" "admin" {
  name = "${var.aws_account_name}-admin"
}
data "aws_iam_role" "developer" {
  name = "${var.aws_account_name}-developer"
}

# Common to all ECS-base permissions, derived from
# arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
data "aws_iam_policy_document" "ecs_task_common_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      aws_cloudwatch_log_group.tfc_agent.arn,
      "${aws_cloudwatch_log_group.tfc_agent.arn}:log-stream:*",
    ]
  }
}

#####
# Agent (ECS Task) Initialize
#####

# This should _only_ be on the init role, _NOT_ the runtime role
# sets up Env Vars for the Task
resource "aws_iam_role_policy" "init_specific" {
  role   = aws_iam_role.init.name
  name   = "SSM"
  policy = data.aws_iam_policy_document.init_specific.json
}
data "aws_iam_policy_document" "init_specific" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameters"]
    resources = [local.tfc_agent_token_parameter_arn]
  }
}
data "aws_iam_policy_document" "assume_init" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
    ]
    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type        = "Service"
    }
  }
}

# role for agent init
resource "aws_iam_role" "init" {
  name               = "${var.name}-ecs-task-init-profile"
  description        = "Used by ECS to setup/initialize ${var.name} Tasks."
  assume_role_policy = data.aws_iam_policy_document.assume_init.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy" "init" {
  role   = aws_iam_role.init.name
  name   = "AmazonECSTaskExecutionRolePolicy"
  policy = data.aws_iam_policy_document.ecs_task_common_policy.json
}

#####
# Agent (ECS Task) Runtime
#####

# This should _only_ be on the runtime role
# Allows Task to Assume Role into `tfc-hc-common-release-tooling-vault` IAM Role.
# This also allows Task to Assume Role cross-account.
resource "aws_iam_role_policy" "runtime_specific" {
  role   = aws_iam_role.runtime.name
  name   = "AssumeRole"
  policy = data.aws_iam_policy_document.runtime_specific.json
}
data "aws_iam_policy_document" "runtime_specific" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
      "sts:SetSourceIdentity",
    ]
    resources = [
      aws_iam_role.tf_manage.arn,
    ]
  }
}
data "aws_iam_policy_document" "assume_runtime" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
      "sts:SetSourceIdentity",
    ]
    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type        = "Service"
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
      "sts:SetSourceIdentity",
    ]
    principals {
      identifiers = [
        # Ease overhead of terraform import
        data.aws_iam_role.developer.arn,
        data.aws_iam_role.admin.arn,
      ]
      type = "AWS"
    }
  }
}

# role for agent runtime
resource "aws_iam_role" "runtime" {
  name               = "${var.name}-ecs-task-agent-profile"
  description        = "Used by ${var.name} Tasks during Runtime."
  assume_role_policy = data.aws_iam_policy_document.assume_runtime.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy" "runtime" {
  role   = aws_iam_role.runtime.id
  name   = "AmazonECSTaskExecutionRolePolicy"
  policy = data.aws_iam_policy_document.ecs_task_common_policy.json
}
