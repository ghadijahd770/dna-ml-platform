# Read by requests/ through terraform_remote_state.

output "location" {
  value = var.location
}

output "region_code" {
  value = var.region_code
}

output "env" {
  value = var.env
}

output "instance" {
  value = var.instance
}

output "shared_resource_group" {
  value = azurerm_resource_group.shared.name
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.main.id
}

output "action_group_id" {
  value = azurerm_monitor_action_group.platform.id
}

output "key_vault_name" {
  value = azurerm_key_vault.shared.name
}

output "platform_admins_group_id" {
  value = var.platform_admins_group_id
}

output "budget_start_date" {
  value = var.budget_start_date
}

output "ci_client_id" {
  description = "Set as the AZURE_CLIENT_ID repository variable for the deploy workflow."
  value       = azurerm_user_assigned_identity.ci.client_id
}

output "ci_principal_id" {
  value = azurerm_user_assigned_identity.ci.principal_id
}
