output "teams" {
  description = "What each team has."
  value       = module.team
}

output "ml_workspace_principal_ids" {
  description = "Azure ML workspace identity per team. Read by requests/fabric."
  value       = { for name, t in module.team : name => t.ml_workspace_principal_id }
}
