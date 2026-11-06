output "shared_resource_group" {
  value = azurerm_resource_group.shared.name
}

output "ml_resource_group" {
  value = azurerm_resource_group.ml.name
}

output "ai_resource_group" {
  value = var.deploy_foundry ? azurerm_resource_group.ai[0].name : ""
}

output "ml_workspace_name" {
  value = azurerm_machine_learning_workspace.main.name
}

output "ml_workspace_principal_id" {
  description = "Azure ML workspace identity. Give it Contributor on the Fabric workspace (infra/fabric) so it can read OneLake."
  value       = azurerm_machine_learning_workspace.main.identity[0].principal_id
}

output "ml_storage_account_name" {
  value = azurerm_storage_account.ml.name
}

output "foundry_account_name" {
  value = var.deploy_foundry ? azapi_resource.foundry[0].name : ""
}

output "foundry_project_name" {
  value = var.deploy_foundry ? azapi_resource.foundry_project[0].name : ""
}

output "foundry_endpoint" {
  value = var.deploy_foundry ? azapi_resource.foundry[0].output.properties.endpoint : ""
}

output "key_vault_name" {
  value = azurerm_key_vault.shared.name
}

output "ci_client_id" {
  description = "Set as the AZURE_CLIENT_ID repository variable for the deploy workflow."
  value       = azurerm_user_assigned_identity.ci.client_id
}

output "ci_principal_id" {
  value = azurerm_user_assigned_identity.ci.principal_id
}
