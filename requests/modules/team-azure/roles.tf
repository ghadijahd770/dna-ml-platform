# Every Azure role assignment for the team (docs/permissions.md).
# Roles are referenced by name, so Terraform stops with a clear error if Microsoft renames one.

locals {
  g     = local.groups
  ml_rg = local.ml_enabled ? azurerm_resource_group.ml[0].id : ""
  ml_ws = local.ml_enabled ? azurerm_machine_learning_workspace.main[0].id : ""
  ml_st = local.ml_enabled ? azurerm_storage_account.ml[0].id : ""
  ml_cr = local.ml_enabled ? azurerm_container_registry.ml[0].id : ""
  ai_rg = local.foundry_enabled ? azurerm_resource_group.ai[0].id : ""
  aif   = local.foundry_enabled ? azapi_resource.foundry[0].id : ""

  ml_assignments = local.ml_enabled ? [
    # Azure ML resource group: see resources in the portal
    { key = "mlrg-data-engineers", scope = local.ml_rg, role = "Reader", principal = local.g.data_engineers },
    { key = "mlrg-data-scientists", scope = local.ml_rg, role = "Reader", principal = local.g.data_scientists },
    { key = "mlrg-ml-engineers", scope = local.ml_rg, role = "Reader", principal = local.g.ml_engineers },
    { key = "mlrg-viewers", scope = local.ml_rg, role = "Reader", principal = local.g.viewers },

    # Azure ML workspace
    { key = "ws-platform-admins", scope = local.ml_ws, role = "Owner", principal = local.platform_admins },
    { key = "ws-data-scientists-ds", scope = local.ml_ws, role = "AzureML Data Scientist", principal = local.g.data_scientists },
    { key = "ws-data-scientists-compute", scope = local.ml_ws, role = "AzureML Compute Operator", principal = local.g.data_scientists },
    { key = "ws-ml-engineers-ds", scope = local.ml_ws, role = "AzureML Data Scientist", principal = local.g.ml_engineers },
    { key = "ws-ml-engineers-compute", scope = local.ml_ws, role = "AzureML Compute Operator", principal = local.g.ml_engineers },

    # Azure ML storage: needed for Entra-only access to data and notebooks
    { key = "st-platform-admins-blob", scope = local.ml_st, role = "Storage Blob Data Contributor", principal = local.platform_admins },
    { key = "st-data-scientists-blob", scope = local.ml_st, role = "Storage Blob Data Contributor", principal = local.g.data_scientists },
    { key = "st-data-scientists-file", scope = local.ml_st, role = "Storage File Data Privileged Contributor", principal = local.g.data_scientists },
    { key = "st-ml-engineers-blob", scope = local.ml_st, role = "Storage Blob Data Contributor", principal = local.g.ml_engineers },
    { key = "st-ml-engineers-file", scope = local.ml_st, role = "Storage File Data Privileged Contributor", principal = local.g.ml_engineers },

    # Container registry
    { key = "acr-ml-engineers", scope = local.ml_cr, role = "AcrPull", principal = local.g.ml_engineers },
  ] : []

  ai_assignments = local.foundry_enabled ? concat(
    [
      # Foundry resource group: see resources in the portal
      { key = "airg-data-scientists", scope = local.ai_rg, role = "Reader", principal = local.g.data_scientists },
      { key = "airg-ml-engineers", scope = local.ai_rg, role = "Reader", principal = local.g.ml_engineers },
      { key = "airg-genai-developers", scope = local.ai_rg, role = "Reader", principal = local.g.genai_developers },
      { key = "airg-viewers", scope = local.ai_rg, role = "Reader", principal = local.g.viewers },

      # Foundry resource: only the platform team can deploy models
      { key = "aif-platform-admins", scope = local.aif, role = "Azure AI Account Owner", principal = local.platform_admins },
    ],
    flatten([
      for p in keys(local.foundry_projects) : [
        { key = "proj-${p}-data-scientists", scope = azapi_resource.foundry_project[p].id, role = "Azure AI User", principal = local.g.data_scientists },
        { key = "proj-${p}-ml-engineers", scope = azapi_resource.foundry_project[p].id, role = "Azure AI User", principal = local.g.ml_engineers },
        { key = "proj-${p}-genai-developers", scope = azapi_resource.foundry_project[p].id, role = "Azure AI User", principal = local.g.genai_developers },
      ]
    ])
  ) : []

  # Skip any group that hasn't been created yet (empty object ID).
  group_assignments = {
    for a in concat(local.ml_assignments, local.ai_assignments) : a.key => a if a.principal != ""
  }

  # The CI/CD identity can deploy into the team's resources.
  ci_assignments = merge(
    local.ml_enabled ? {
      "ws"  = { scope = local.ml_ws, role = "Contributor" }
      "st"  = { scope = local.ml_st, role = "Storage Blob Data Contributor" }
      "acr" = { scope = local.ml_cr, role = "AcrPush" }
    } : {},
    local.foundry_enabled ? {
      "aif" = { scope = local.aif, role = "Azure AI User" }
    } : {}
  )
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
  principal_id                     = var.platform.ci_principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}
