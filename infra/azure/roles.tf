# Every Azure role assignment in docs/permissions.md.
# Roles are referenced by name, so Terraform stops with a clear error if Microsoft renames one.

locals {
  ai_rg_id      = var.deploy_foundry ? azurerm_resource_group.ai[0].id : ""
  foundry_id    = var.deploy_foundry ? azapi_resource.foundry[0].id : ""
  foundry_proj  = var.deploy_foundry ? azapi_resource.foundry_project[0].id : ""
  g             = var.group_ids
  ml_storage_id = azurerm_storage_account.ml.id
  ml_ws_id      = azurerm_machine_learning_workspace.main.id

  # Group assignments: key = a fixed label, so plans stay stable.
  group_assignments_all = concat(
    [
      # Shared Key Vault
      { key = "kv-platform-admins", scope = azurerm_key_vault.shared.id, role = "Key Vault Administrator", principal = local.g.platform_admins },
      { key = "kv-ml-engineers", scope = azurerm_key_vault.shared.id, role = "Key Vault Secrets User", principal = local.g.ml_engineers },

      # Azure ML resource group: see resources in the portal
      { key = "mlrg-data-engineers", scope = azurerm_resource_group.ml.id, role = "Reader", principal = local.g.data_engineers },
      { key = "mlrg-data-scientists", scope = azurerm_resource_group.ml.id, role = "Reader", principal = local.g.data_scientists },
      { key = "mlrg-ml-engineers", scope = azurerm_resource_group.ml.id, role = "Reader", principal = local.g.ml_engineers },
      { key = "mlrg-viewers", scope = azurerm_resource_group.ml.id, role = "Reader", principal = local.g.viewers },

      # Azure ML workspace
      { key = "ws-platform-admins", scope = local.ml_ws_id, role = "Owner", principal = local.g.platform_admins },
      { key = "ws-data-scientists-ds", scope = local.ml_ws_id, role = "AzureML Data Scientist", principal = local.g.data_scientists },
      { key = "ws-data-scientists-compute", scope = local.ml_ws_id, role = "AzureML Compute Operator", principal = local.g.data_scientists },
      { key = "ws-ml-engineers-ds", scope = local.ml_ws_id, role = "AzureML Data Scientist", principal = local.g.ml_engineers },
      { key = "ws-ml-engineers-compute", scope = local.ml_ws_id, role = "AzureML Compute Operator", principal = local.g.ml_engineers },

      # Azure ML storage: needed for Entra-only access to data and notebooks
      { key = "st-platform-admins-blob", scope = local.ml_storage_id, role = "Storage Blob Data Contributor", principal = local.g.platform_admins },
      { key = "st-data-scientists-blob", scope = local.ml_storage_id, role = "Storage Blob Data Contributor", principal = local.g.data_scientists },
      { key = "st-data-scientists-file", scope = local.ml_storage_id, role = "Storage File Data Privileged Contributor", principal = local.g.data_scientists },
      { key = "st-ml-engineers-blob", scope = local.ml_storage_id, role = "Storage Blob Data Contributor", principal = local.g.ml_engineers },
      { key = "st-ml-engineers-file", scope = local.ml_storage_id, role = "Storage File Data Privileged Contributor", principal = local.g.ml_engineers },

      # Container registry
      { key = "acr-ml-engineers", scope = azurerm_container_registry.ml.id, role = "AcrPull", principal = local.g.ml_engineers },
    ],
    var.deploy_foundry ? [
      # Foundry resource group: see resources in the portal
      { key = "airg-data-scientists", scope = local.ai_rg_id, role = "Reader", principal = local.g.data_scientists },
      { key = "airg-ml-engineers", scope = local.ai_rg_id, role = "Reader", principal = local.g.ml_engineers },
      { key = "airg-genai-developers", scope = local.ai_rg_id, role = "Reader", principal = local.g.genai_developers },
      { key = "airg-viewers", scope = local.ai_rg_id, role = "Reader", principal = local.g.viewers },

      # Foundry resource and project
      { key = "aif-platform-admins", scope = local.foundry_id, role = "Azure AI Account Owner", principal = local.g.platform_admins },
      { key = "proj-data-scientists", scope = local.foundry_proj, role = "Azure AI User", principal = local.g.data_scientists },
      { key = "proj-ml-engineers", scope = local.foundry_proj, role = "Azure AI User", principal = local.g.ml_engineers },
      { key = "proj-genai-developers", scope = local.foundry_proj, role = "Azure AI User", principal = local.g.genai_developers },
    ] : []
  )

  # Skip any group that hasn't been created yet (empty object ID).
  group_assignments = { for a in local.group_assignments_all : a.key => a if a.principal != "" }

  # CI/CD identity assignments.
  ci_assignments = merge(
    {
      kv      = { scope = azurerm_key_vault.shared.id, role = "Key Vault Secrets User" }
      ws      = { scope = local.ml_ws_id, role = "Contributor" }
      storage = { scope = local.ml_storage_id, role = "Storage Blob Data Contributor" }
      acr     = { scope = azurerm_container_registry.ml.id, role = "AcrPush" }
    },
    var.deploy_foundry ? {
      foundry = { scope = local.foundry_id, role = "Azure AI User" }
    } : {},
    var.grant_ci_subscription_access ? {
      "sub-contributor" = { scope = data.azurerm_subscription.current.id, role = "Contributor" }
      "sub-rbac-admin"  = { scope = data.azurerm_subscription.current.id, role = "Role Based Access Control Administrator" }
    } : {},
    var.tfstate_storage_account_name != "" ? {
      tfstate = { scope = data.azurerm_storage_account.tfstate[0].id, role = "Storage Blob Data Contributor" }
    } : {}
  )
}

data "azurerm_storage_account" "tfstate" {
  count               = var.tfstate_storage_account_name != "" ? 1 : 0
  name                = var.tfstate_storage_account_name
  resource_group_name = var.tfstate_resource_group_name
}

resource "azurerm_role_assignment" "groups" {
  for_each             = local.group_assignments
  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = each.value.principal
  principal_type       = "Group"
}

resource "azurerm_role_assignment" "ci" {
  for_each                         = local.ci_assignments
  scope                            = each.value.scope
  role_definition_name             = each.value.role
  principal_id                     = azurerm_user_assigned_identity.ci.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}
