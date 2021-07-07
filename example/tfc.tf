# Configure TFC agent pool and workspace(s)

resource "tfe_agent_pool" "pool" {
  name         = var.name
  organization = var.tfc_org
}

resource "tfe_agent_token" "token" {
  agent_pool_id = tfe_agent_pool.pool.id
  description   = var.name
}

resource "tfe_workspace" "test-agents" {
  for_each = toset([
    "test-agent-${terraform.workspace}",
  ])
  name           = each.key
  organization   = var.tfc_org
  agent_pool_id  = tfe_agent_pool.pool.id
  execution_mode = "agent"
}
