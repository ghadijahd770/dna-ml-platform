# Microsoft Foundry resource and project for the DNA team.
# Sandbox network decision: public endpoint + API keys off (Entra login only).
# Only the model deployments listed in sandbox.tfvars exist; nobody else can add models.
# The account and project use the AzAPI provider so new Foundry features are available straight away.

locals {
  foundry_name = "aif-${var.team}-${var.env}-${local.unique6}"
}

resource "azapi_resource" "foundry" {
  count                     = var.deploy_foundry ? 1 : 0
  type                      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  name                      = local.foundry_name
  parent_id                 = azurerm_resource_group.ai[0].id
  location                  = var.location
  schema_validation_enabled = false
  response_export_values    = ["properties.endpoint"]
  tags                      = local.expiring_tags

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
  count                     = var.deploy_foundry ? 1 : 0
  type                      = "Microsoft.CognitiveServices/accounts/projects@2025-06-01"
  name                      = "proj-${var.team}-${local.name_suffix}"
  parent_id                 = azapi_resource.foundry[0].id
  location                  = var.location
  schema_validation_enabled = false
  tags                      = local.expiring_tags

  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {
      displayName = "DNA ${var.env} project"
      description = "DNA team Foundry project (${var.env})."
    }
  }
}

# Approved models only. When adding several at once, apply with -parallelism=1
# because Foundry accepts one deployment change at a time.
resource "azurerm_cognitive_deployment" "approved" {
  for_each             = var.deploy_foundry ? { for d in var.foundry_model_deployments : d.name => d } : {}
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
  count                      = var.deploy_foundry ? 1 : 0
  name                       = "to-log-analytics"
  target_resource_id         = azapi_resource.foundry[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
  }
}
