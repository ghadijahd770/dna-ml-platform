# DNA ML platform: team requests (Fabric).
#
# For every team file with a fabric.workspace_id, gives each group its Fabric workspace role
# and lets the team's Azure ML workspace read OneLake. Tenant settings, capacity and Git
# integration stay manual (see bootstrap/README.md).

# Reads the Azure ML workspace identities from requests/azure.
data "terraform_remote_state" "requests_azure" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.tfstate_resource_group_name
    storage_account_name = var.tfstate_storage_account_name
    container_name       = "tfstate"
    key                  = var.requests_azure_state_key
    use_azuread_auth     = true
  }
}

locals {
  team_files = fileset("${path.module}/${var.teams_dir}", "*.yaml")

  teams = {
    for f in local.team_files :
    trimsuffix(f, ".yaml") => yamldecode(file("${path.module}/${var.teams_dir}/${f}"))
  }

  # Teams that have a Fabric workspace.
  fabric_teams = {
    for name, t in local.teams : name => tostring(t.fabric.workspace_id)
    if try(t.fabric.workspace_id, null) != null && try(t.fabric.workspace_id, "") != "" && try(t.fabric.workspace_id, "") != "CHANGE-ME"
  }

  # One entry per team and group that has an object ID.
  group_roles = merge([
    for name, workspace_id in local.fabric_teams : {
      for group, role in merge(var.default_roles, try(local.teams[name].fabric.roles, {})) :
      "${name}-${group}" => {
        workspace_id = workspace_id
        principal_id = tostring(local.teams[name].groups[group])
        role         = tostring(role)
      }
      if try(local.teams[name].groups[group], null) != null && try(local.teams[name].groups[group], "") != ""
    }
  ]...)

  ml_principals = try(data.terraform_remote_state.requests_azure.outputs.ml_workspace_principal_ids, {})

  # Azure ML gets Contributor on its team's Fabric workspace so it can read OneLake.
  azure_ml_roles = {
    for name, workspace_id in local.fabric_teams : name => {
      workspace_id = workspace_id
      principal_id = local.ml_principals[name]
    }
    if try(local.ml_principals[name], "") != ""
  }
}

resource "fabric_workspace_role_assignment" "groups" {
  for_each     = local.group_roles
  workspace_id = each.value.workspace_id
  role         = each.value.role

  principal = {
    id   = each.value.principal_id
    type = "Group"
  }
}

resource "fabric_workspace_role_assignment" "azure_ml" {
  for_each     = local.azure_ml_roles
  workspace_id = each.value.workspace_id
  role         = "Contributor"

  principal = {
    id   = each.value.principal_id
    type = "ServicePrincipal"
  }
}
