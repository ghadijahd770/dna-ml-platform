# DNA ML platform: the shared foundation.
# Set up once, then changed rarely and only by the platform team.
#
#   rg-dna-shared-<env>-<region>-01   Log Analytics, Key Vault, alert contacts, access-change alerts,
#                                     CI/CD identity, delete lock, budget
#
# Team resources (Azure ML, Foundry, Fabric access) live in requests/ and read this
# stack's outputs.

data "azurerm_subscription" "current" {}

locals {
  name_suffix = "${var.env}-${var.region_code}-${var.instance}"
  unique6     = substr(md5("${data.azurerm_subscription.current.subscription_id}-${var.prefix}-${var.env}"), 0, 6)

  tags = {
    owner      = var.owner
    env        = var.env == "sbx" ? "sandbox" : var.env
    costcentre = var.cost_centre
    workload   = "dna-ml-platform"
    managed_by = "terraform"
  }
}

resource "azurerm_resource_group" "shared" {
  name     = "rg-${var.prefix}-shared-${local.name_suffix}"
  location = var.location
  tags     = local.tags
}

# Protects the logs and Key Vault that everything depends on.
resource "azurerm_management_lock" "shared" {
  name       = "do-not-delete"
  scope      = azurerm_resource_group.shared.id
  lock_level = "CanNotDelete"
  notes      = "Shared DNA platform foundations. Remove only with platform team approval."
}

resource "azurerm_consumption_budget_resource_group" "shared" {
  name              = "budget-${var.prefix}-shared-${local.name_suffix}"
  resource_group_id = azurerm_resource_group.shared.id
  amount            = var.monthly_budget
  time_grain        = "Monthly"

  time_period {
    start_date = var.budget_start_date
  }

  dynamic "notification" {
    for_each = [50, 80, 100]

    content {
      enabled        = true
      threshold      = notification.value
      operator       = "GreaterThan"
      threshold_type = "Actual"
      contact_groups = [azurerm_monitor_action_group.platform.id]
    }
  }
}
