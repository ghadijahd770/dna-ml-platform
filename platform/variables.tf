# ── Naming ─────────────────────────────────────────────────────────────────────

variable "location" {
  description = "Azure region. Must match the Fabric capacity region."
  type        = string
  default     = "southafricanorth"
}

variable "region_code" {
  description = "Short region code used in names (san = South Africa North)."
  type        = string
  default     = "san"
}

variable "env" {
  description = "Environment code used in names: sbx, dev, tst or prd."
  type        = string
  default     = "sbx"

  validation {
    condition     = contains(["sbx", "dev", "tst", "prd"], var.env)
    error_message = "env must be one of sbx, dev, tst, prd."
  }
}

variable "prefix" {
  description = "Platform name prefix used in names."
  type        = string
  default     = "dna"
}

variable "instance" {
  description = "Instance number used in names."
  type        = string
  default     = "01"
}

# ── Ownership, cost and alerts ─────────────────────────────────────────────────

variable "owner" {
  description = "Owner tag value."
  type        = string
}

variable "cost_centre" {
  description = "Cost centre tag value."
  type        = string

  validation {
    condition     = var.cost_centre != "CHANGE-ME"
    error_message = "Set cost_centre in platform/sandbox.tfvars."
  }
}

variable "alert_email" {
  description = "Email address (team mailbox or Teams channel address) that receives platform alerts."
  type        = string

  validation {
    condition     = var.alert_email != "CHANGE-ME@example.com"
    error_message = "Set alert_email in platform/sandbox.tfvars."
  }
}

variable "monthly_budget" {
  description = "Monthly budget for the shared resource group, in the billing account currency."
  type        = number
  default     = 100
}

variable "budget_start_date" {
  description = "Budget start: the first day of a month, e.g. 2026-11-01T00:00:00Z. Keep it fixed after the first deployment."
  type        = string
}

# ── Access ─────────────────────────────────────────────────────────────────────

variable "platform_admins_group_id" {
  description = "Object ID of sg-dna-platform-admins (bootstrap/get-group-ids.sh prints it). Empty to skip."
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "GitHub repository (owner/name) allowed to deploy with the CI/CD identity."
  type        = string
  default     = "ghadijahd770/dna-ml-platform"
}

variable "github_environment" {
  description = "GitHub environment name used by the deploy workflow."
  type        = string
  default     = "sandbox"
}

variable "grant_ci_subscription_access" {
  description = "Give the CI/CD identity Contributor + Role Based Access Control Administrator on the subscription so the deploy workflow can run. Agree this with security."
  type        = bool
  default     = true
}

variable "tfstate_resource_group_name" {
  description = "Resource group of the Terraform state storage account (bootstrap/bootstrap-state.sh)."
  type        = string
  default     = "rg-dna-tfstate-sbx-san-01"
}

variable "tfstate_storage_account_name" {
  description = "Terraform state storage account. The CI/CD identity gets access to it. Empty to skip."
  type        = string
  default     = ""
}
