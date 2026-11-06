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

variable "platform_state_key" {
  description = "State file of the platform stack."
  type        = string
  default     = "platform-sandbox.tfstate"
}

variable "teams_dir" {
  description = "Folder with one YAML file per team."
  type        = string
  default     = "../teams"
}
