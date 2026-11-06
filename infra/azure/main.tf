# DNA ML platform: Azure resources for the sandbox.
#
# Creates three resource groups:
#   rg-dna-shared-<env>-<region>-01  Log Analytics, Key Vault, alerts, CI/CD identity, delete lock  (shared.tf)
#   rg-dna-ml-<env>-<region>-01      Azure ML workspace, managed network, Entra-only              (ml.tf)
#   rg-dna-ai-<env>-<region>-01      Foundry resource + project, API keys off                     (foundry.tf)
# plus budgets (budgets.tf) and every role assignment in docs/permissions.md (roles.tf).

data "azurerm_subscription" "current" {}

locals {
  name_suffix = "${var.env}-${var.region_code}-${var.instance}"

  # Short, stable suffixes for names that must be globally unique.
  unique6 = substr(md5("${data.azurerm_subscription.current.subscription_id}-${var.team}-${var.env}"), 0, 6)
  unique8 = substr(md5("${data.azurerm_subscription.current.subscription_id}-${var.team}-${var.env}"), 0, 8)

  base_tags = {
    owner      = var.owner
    env        = var.env == "sbx" ? "sandbox" : var.env
    costcentre = var.cost_centre
    workload   = "dna-ml-platform"
    managed_by = "terraform"
  }

  expiring_tags = merge(local.base_tags, { expires = var.expires })
}

resource "azurerm_resource_group" "shared" {
  name     = "rg-${var.team}-shared-${local.name_suffix}"
  location = var.location
  tags     = local.base_tags
}

resource "azurerm_resource_group" "ml" {
  name     = "rg-${var.team}-ml-${local.name_suffix}"
  location = var.location
  tags     = local.expiring_tags
}

resource "azurerm_resource_group" "ai" {
  count    = var.deploy_foundry ? 1 : 0
  name     = "rg-${var.team}-ai-${local.name_suffix}"
  location = var.location
  tags     = local.expiring_tags
}
