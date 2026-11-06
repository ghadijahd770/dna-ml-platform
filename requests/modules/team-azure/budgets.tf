# Monthly budget on each of the team's resource groups, alerting the platform team
# at 50 %, 80 % and 100 %.

locals {
  budget_resource_groups = merge(
    local.ml_enabled ? { ml = azurerm_resource_group.ml[0].id } : {},
    local.foundry_enabled ? { ai = azurerm_resource_group.ai[0].id } : {}
  )
}

resource "azurerm_consumption_budget_resource_group" "monthly" {
  for_each          = local.budget_resource_groups
  name              = "budget-${var.team_name}-${each.key}-${local.name_suffix}"
  resource_group_id = each.value
  amount            = local.monthly_budget
  time_grain        = "Monthly"

  time_period {
    start_date = var.platform.budget_start_date
  }

  dynamic "notification" {
    for_each = [50, 80, 100]

    content {
      enabled        = true
      threshold      = notification.value
      operator       = "GreaterThan"
      threshold_type = "Actual"
      contact_groups = [var.platform.action_group_id]
    }
  }
}
