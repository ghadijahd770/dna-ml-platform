variable "workspace_id" {
  description = "ID of the existing DNA sandbox Fabric workspace (the GUID in the workspace URL after /groups/)."
  type        = string

  validation {
    condition     = var.workspace_id != "CHANGE-ME"
    error_message = "Set workspace_id in sandbox.tfvars."
  }
}

variable "group_ids" {
  description = "Object IDs of the six Entra groups. Empty values are skipped. Set with TF_VAR_group_ids (scripts/get-group-ids.sh)."

  type = object({
    platform_admins  = optional(string, "")
    data_engineers   = optional(string, "")
    data_scientists  = optional(string, "")
    ml_engineers     = optional(string, "")
    genai_developers = optional(string, "")
    viewers          = optional(string, "")
  })

  default = {}
}

variable "workspace_roles" {
  description = "Fabric workspace role for each group (Admin, Member, Contributor or Viewer). Matches docs/permissions.md."
  type        = map(string)

  default = {
    platform_admins  = "Admin"
    data_engineers   = "Member"
    data_scientists  = "Contributor"
    ml_engineers     = "Contributor"
    genai_developers = "Viewer"
    viewers          = "Viewer"
  }
}

variable "aml_workspace_principal_id" {
  description = "Azure ML workspace identity (output ml_workspace_principal_id of infra/azure). Gets Contributor so Azure ML can read OneLake. Empty to skip."
  type        = string
  default     = ""
}
