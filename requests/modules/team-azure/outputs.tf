output "resource_groups" {
  value = values(local.budget_resource_groups)
}

output "ml_workspace_name" {
  value = local.ml_enabled ? azurerm_machine_learning_workspace.main[0].name : ""
}

output "ml_workspace_principal_id" {
  description = "Azure ML workspace identity. requests/fabric gives it access to the team's Fabric workspace."
  value       = local.ml_enabled ? azurerm_machine_learning_workspace.main[0].identity[0].principal_id : ""
}

output "foundry_account_name" {
  value = local.foundry_enabled ? azapi_resource.foundry[0].name : ""
}

output "foundry_endpoint" {
  value = local.foundry_enabled ? azapi_resource.foundry[0].output.properties.endpoint : ""
}

output "foundry_projects" {
  value = [for p in azapi_resource.foundry_project : p.name]
}

output "approved_models" {
  value = keys(local.foundry_models)
}
