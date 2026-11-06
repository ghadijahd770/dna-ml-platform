variable "tfstate_resource_group_name" {
  description = "Resource group of the Terraform state storage account."
  type        = string
  default     = "rg-dna-tfstate-sbx-san-01"
}

variable "tfstate_storage_account_name" {
  description = "Terraform state storage account (filled in by bootstrap/bootstrap-state.sh)."
  type        = string

  validation {
    condition     = var.tfstate_storage_account_name != "CHANGE-ME"
    error_message = "Run bootstrap/bootstrap-state.sh first."
  }
}

variable "requests_azure_state_key" {
  description = "State file of the requests/azure stack (for the Azure ML workspace identities)."
  type        = string
  default     = "requests-sandbox-azure.tfstate"
}

variable "teams_dir" {
  description = "Folder with one YAML file per team."
  type        = string
  default     = "../teams"
}

variable "default_roles" {
  description = "Fabric workspace role for each group, unless a team file overrides it (fabric.roles)."
  type        = map(string)

  default = {
    data_engineers   = "Member"
    data_scientists  = "Contributor"
    ml_engineers     = "Contributor"
    genai_developers = "Viewer"
    viewers          = "Viewer"
  }
}
