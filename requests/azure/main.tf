# DNA ML platform: team requests (Azure).
#
# Every file in requests/teams/*.yaml is one team. For each team this builds an Azure ML
# workspace, a Foundry resource with projects and approved models, budgets and roles.
# Menu requests are handled by editing the team's YAML file and running this stack again.

data "azurerm_client_config" "current" {}

# Reads the shared foundation built by platform/.
data "terraform_remote_state" "platform" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.tfstate_resource_group_name
    storage_account_name = var.tfstate_storage_account_name
    container_name       = "tfstate"
    key                  = var.platform_state_key
    use_azuread_auth     = true
  }
}

locals {
  team_files = fileset("${path.module}/${var.teams_dir}", "*.yaml")

  teams = {
    for f in local.team_files :
    trimsuffix(f, ".yaml") => yamldecode(file("${path.module}/${var.teams_dir}/${f}"))
  }
}

module "team" {
  source   = "../modules/team-azure"
  for_each = local.teams

  team_name       = each.key
  team            = each.value
  platform        = data.terraform_remote_state.platform.outputs
  tenant_id       = data.azurerm_client_config.current.tenant_id
  subscription_id = data.azurerm_client_config.current.subscription_id
}
