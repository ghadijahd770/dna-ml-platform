# Microsoft Foundry for the team: one resource, one or more projects, approved models only.
# Sandbox network decision: public endpoint + API keys off (Entra login only).
# Uses the AzAPI provider so new Foundry features are available straight away.

locals {
  foundry_name = "aif-${var.team_name}-${local.env}-${local.unique6}"
}

resource "azapi_resource" "foundry" {
  count                     = local.foundry_enabled ? 1 : 0
  type                      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  name                      = local.foundry_name
  parent_id                 = azurerm_resource_group.ai[0].id
  location                  = local.location
  schema_validation_enabled = false
  response_export_values    = ["properties.endpoint"]
  tags                      = local.tags

  identity {
    type = "SystemAssigned"
  }

  body = {
    kind = "AIServices"

    sku = {
      name = "S0"
    }

    properties = {
      customSubDomainName    = local.foundry_name
      allowProjectManagement = true
      publicNetworkAccess    = "Enabled"
      disableLocalAuth       = true

      networkAcls = {
        defaultAction = "Allow"
      }
    }
  }
}

resource "azapi_resource" "foundry_project" {
  for_each                  = local.foundry_projects
  type                      = "Microsoft.CognitiveServices/accounts/projects@2025-06-01"
  name                      = "proj-${var.team_name}-${each.key}"
  parent_id                 = azapi_resource.foundry[0].id
  location                  = local.location
  schema_validation_enabled = false
  tags                      = local.tags

  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {
      displayName = "${upper(var.team_name)} ${each.key}"
      description = each.value.description
    }
  }
}

# Approved models only. When adding several at once, apply with -parallelism=1
# because Foundry accepts one deployment change at a time.
resource "azurerm_cognitive_deployment" "approved" {
  for_each             = local.foundry_models
  name                 = each.value.name
  cognitive_account_id = azapi_resource.foundry[0].id

  model {
    format  = each.value.format
    name    = each.value.model
    version = each.value.version
  }

  sku {
    name     = each.value.sku
    capacity = each.value.capacity
  }
}

resource "azurerm_monitor_diagnostic_setting" "foundry" {
  count                      = local.foundry_enabled ? 1 : 0
  name                       = "to-log-analytics"
  target_resource_id         = azapi_resource.foundry[0].id
  log_analytics_workspace_id = var.platform.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
  }
}
