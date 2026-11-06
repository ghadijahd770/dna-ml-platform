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

variable "team" {
  description = "Team code used in names."
  type        = string
  default     = "dna"
}

variable "instance" {
  description = "Instance number used in names."
  type        = string
  default     = "01"
}

# ── Tags and cost ──────────────────────────────────────────────────────────────

variable "owner" {
  description = "Owner tag value."
  type        = string
}

variable "cost_centre" {
  description = "Cost centre tag value."
  type        = string

  validation {
    condition     = var.cost_centre != "CHANGE-ME"
    error_message = "Set cost_centre in sandbox.tfvars."
  }
}

variable "expires" {
  description = "Expiry date (yyyy-mm-dd) tagged on the ML and AI resource groups. Review monthly."
  type        = string
}

variable "alert_email" {
  description = "Email address (team mailbox or Teams channel address) that receives alerts. Set with TF_VAR_alert_email."
  type        = string
}

variable "monthly_budget" {
  description = "Monthly budget per resource group, in the billing account currency."
  type        = number
  default     = 500
}

variable "budget_start_date" {
  description = "Budget start: the first day of a month, e.g. 2026-11-01T00:00:00Z. Keep it fixed after the first deployment."
  type        = string
}

# ── Access ─────────────────────────────────────────────────────────────────────

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
  description = "Resource group of the Terraform state storage account (from scripts/bootstrap-state.sh). Empty to skip."
  type        = string
  default     = ""
}

variable "tfstate_storage_account_name" {
  description = "Terraform state storage account. The CI/CD identity gets access to it so the workflow can read and write state. Empty to skip."
  type        = string
  default     = ""
}

# ── Azure ML ───────────────────────────────────────────────────────────────────

variable "cpu_cluster_vm_size" {
  description = "VM size for the CPU training cluster."
  type        = string
  default     = "Standard_DS3_v2"
}

variable "cpu_cluster_max_nodes" {
  description = "Maximum nodes for the CPU training cluster. Minimum is always 0."
  type        = number
  default     = 2
}

variable "deploy_gpu_cluster" {
  description = "Create a GPU cluster too. Needs GPU quota in the region first."
  type        = bool
  default     = false
}

variable "gpu_cluster_vm_size" {
  description = "VM size for the GPU training cluster."
  type        = string
  default     = "Standard_NC4as_T4_v3"
}

variable "gpu_cluster_max_nodes" {
  description = "Maximum nodes for the GPU cluster."
  type        = number
  default     = 1
}

variable "disable_storage_shared_key" {
  description = "Turn off shared keys on the Azure ML storage account. Read docs/network-decision.md first."
  type        = bool
  default     = false
}

# ── Foundry ────────────────────────────────────────────────────────────────────

variable "deploy_foundry" {
  description = "Create the Foundry resource and project."
  type        = bool
  default     = true
}

variable "foundry_model_deployments" {
  description = "Approved model deployments. Only models on this list exist in the sandbox."

  type = list(object({
    name     = string
    model    = string
    version  = string
    format   = string
    sku      = string
    capacity = number
  }))

  default = []
}
