# Monthly budget on each resource group, alerting the platform action group at 50 %, 80 % and 100 %.

locals {
  budget_resource_groups = merge(
    {
      shared = azurerm_resource_group.shared.id
      ml     = azurerm_resource_group.ml.id
    },
    var.deploy_foundry ? { ai = azurerm_resource_group.ai[0].id } : {}
  )
}

resource "azurerm_consumption_budget_resource_group" "monthly" {
  for_each          = local.budget_resource_groups
  name              = "budget-${var.team}-${each.key}-${local.name_suffix}"
  resource_group_id = each.value
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
