locals {
  subnets         = var.create_vpc ? module.vpc[0].private_subnets : var.private_subnets
  security_groups = var.create_vpc ? aws_security_group.tfc_agent[*].id : var.security_groups
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  num_vpc_azs = 3
  vpc_azs     = slice(data.aws_availability_zones.available.names, 0, local.num_vpc_azs)
  private_subnet_cidr_blocks = [
    for a in local.vpc_azs :
    cidrsubnet(var.vpc_cidr, 4, index(local.vpc_azs, a) + 1)
  ]
  public_subnet_cidr_blocks = [
    for a in local.vpc_azs :
    cidrsubnet(var.vpc_cidr, 4, index(local.vpc_azs, a) + 5 + local.num_vpc_azs)
  ]
}

module "vpc" {
  count  = var.create_vpc ? 1 : 0
  source = "terraform-aws-modules/vpc/aws"

  name = var.name
  cidr = var.vpc_cidr

  azs             = local.vpc_azs
  public_subnets  = local.public_subnet_cidr_blocks
  private_subnets = local.private_subnet_cidr_blocks

  # Single NAT Gateway
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
}

resource "aws_security_group" "tfc_agent" {
  count = var.create_vpc ? 1 : 0

  name_prefix = "${var.name}-sg"
  description = "Security group for tfc-agent"
  vpc_id      = module.vpc[0].vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_egress" {
  count = var.create_vpc ? 1 : 0

  security_group_id = aws_security_group.tfc_agent[0].id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
