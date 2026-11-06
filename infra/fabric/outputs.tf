output "workspace_role_assignments" {
  description = "Groups that were given a role on the Fabric workspace."
  value       = { for key, a in local.group_roles : key => a.role }
}
