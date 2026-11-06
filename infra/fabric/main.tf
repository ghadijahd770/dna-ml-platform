# DNA ML platform: Fabric workspace access as code.
# Gives each Entra group its Fabric workspace role (docs/permissions.md) and lets
# Azure ML read OneLake. Tenant settings, capacity and Git integration stay manual.

locals {
  group_roles = {
    for key, role in var.workspace_roles : key => {
      id   = lookup(var.group_ids, key, "")
      role = role
    } if lookup(var.group_ids, key, "") != ""
  }
}

resource "fabric_workspace_role_assignment" "groups" {
  for_each     = local.group_roles
  workspace_id = var.workspace_id
  role         = each.value.role

  principal = {
    id   = each.value.id
    type = "Group"
  }
}

resource "fabric_workspace_role_assignment" "azure_ml" {
  count        = var.aml_workspace_principal_id != "" ? 1 : 0
  workspace_id = var.workspace_id
  role         = "Contributor"

  principal = {
    id   = var.aml_workspace_principal_id
    type = "ServicePrincipal"
  }
}
