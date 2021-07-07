resource "aws_ecs_cluster" "tfc_agent" {
  name               = "${var.name}Cluster"
  capacity_providers = var.capacity_providers
  tags               = var.common_tags
}

resource "aws_ecs_service" "tfc_agent" {
  name            = "${var.name}Service"
  cluster         = aws_ecs_cluster.tfc_agent.id
  launch_type     = "FARGATE"
  desired_count   = var.num_agents
  task_definition = aws_ecs_task_definition.tfc_agent.arn
  tags            = var.common_tags
  network_configuration {
    security_groups  = var.security_groups
    subnets          = var.private_subnets
    assign_public_ip = false
  }
}

resource "aws_ecs_task_definition" "tfc_agent" {
  family                   = "${var.name}Task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  container_definitions    = local.agent_task_definition
  execution_role_arn       = aws_iam_role.init.arn
  task_role_arn            = aws_iam_role.runtime.arn
  cpu                      = local.cpu
  memory                   = local.memory
  tags                     = var.common_tags
}

locals {
  agent_task_definition = jsonencode([
    {
      name      = "tfc-agent"
      image     = var.tfc_agent_image
      essential = true
      cpu       = local.cpu
      memory    = local.memory
      environment = [
        {
          name  = "TFC_AGENT_DISABLE_UPDATE"
          value = "true"
        },
        {
          name  = "TFC_AGENT_SINGLE"
          value = "true"
        },
        {
          name  = "TFC_AGENT_NAME"
          value = "${var.name}-ecs"
        },
        {
          name  = "TFC_AGENT_LOG_LEVEL"
          value = "info"
        },
      ]
      secrets = [
        {
          name      = "TFC_AGENT_TOKEN"
          valueFrom = local.tfc_agent_token_parameter_arn
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-group         = local.cloudwatch_log_group
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "logs"
        }
      }
    }
  ])
}
