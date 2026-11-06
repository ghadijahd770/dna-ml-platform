# Platform-level role assignments. Team roles are in requests/modules/team-azure/roles.tf.

data "azurerm_storage_account" "tfstate" {
  count               = var.tfstate_storage_account_name != "" ? 1 : 0
  name                = var.tfstate_storage_account_name
  resource_group_name = var.tfstate_resource_group_name
}

resource "azurerm_role_assignment" "platform_admins_key_vault" {
  count                = var.platform_admins_group_id != "" ? 1 : 0
  scope                = azurerm_key_vault.shared.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.platform_admins_group_id
  principal_type       = "Group"
}

locals {
  ci_assignments = merge(
    {
      "key-vault" = { scope = azurerm_key_vault.shared.id, role = "Key Vault Secrets User" }
    },
    var.grant_ci_subscription_access ? {
      "sub-contributor" = { scope = data.azurerm_subscription.current.id, role = "Contributor" }
      "sub-rbac-admin"  = { scope = data.azurerm_subscription.current.id, role = "Role Based Access Control Administrator" }
    } : {},
    var.tfstate_storage_account_name != "" ? {
      "tfstate" = { scope = data.azurerm_storage_account.tfstate[0].id, role = "Storage Blob Data Contributor" }
    } : {}
  )
}

resource "azurerm_role_assignment" "ci" {
  for_each                         = local.ci_assignments
  scope                            = each.value.scope
  role_definition_name             = each.value.role
  principal_id                     = azurerm_user_assigned_identity.ci.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}
