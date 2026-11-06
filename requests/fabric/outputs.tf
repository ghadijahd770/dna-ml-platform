output "workspace_roles" {
  description = "Fabric workspace roles given, per team and group."
  value       = { for key, a in local.group_roles : key => a.role }
}
