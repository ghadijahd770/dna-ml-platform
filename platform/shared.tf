# One place for every log and alert.
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.prefix}-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.shared.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

# Team secrets. Entra (RBAC) access only.
resource "azurerm_key_vault" "shared" {
  name                          = "kv-${var.prefix}-${var.env}-${local.unique6}"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.shared.name
  tenant_id                     = data.azurerm_subscription.current.tenant_id
  sku_name                      = "standard"
  enable_rbac_authorization     = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = 90
  public_network_access_enabled = true
  tags                          = local.tags
}

resource "azurerm_monitor_diagnostic_setting" "shared_key_vault" {
  name                       = "to-log-analytics"
  target_resource_id         = azurerm_key_vault.shared.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
  }
}

# Who gets told when an alert fires.
resource "azurerm_monitor_action_group" "platform" {
  name                = "ag-${var.prefix}-platform-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.shared.name
  short_name          = "${var.prefix}plat"
  tags                = local.tags

  email_receiver {
    name                    = "platform-team"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}

# Alert when anyone creates or removes a role assignment in the subscription.
resource "azurerm_monitor_activity_log_alert" "access_change" {
  for_each = {
    created = "Microsoft.Authorization/roleAssignments/write"
    removed = "Microsoft.Authorization/roleAssignments/delete"
  }

  name                = "alert-${var.prefix}-access-${each.key}-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.shared.name
  location            = "global"
  scopes              = [data.azurerm_subscription.current.id]
  description         = "A role assignment was ${each.key} in the subscription."
  tags                = local.tags

  criteria {
    category       = "Administrative"
    operation_name = each.value
  }

  action {
    action_group_id = azurerm_monitor_action_group.platform.id
  }
}

# CI/CD identity: GitHub Actions logs in with OIDC, so there is no password to leak.
resource "azurerm_user_assigned_identity" "ci" {
  name                = "id-${var.prefix}-cicd-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.shared.name
  tags                = local.tags
}

resource "azurerm_federated_identity_credential" "github" {
  name                = "github-${var.github_environment}"
  resource_group_name = azurerm_resource_group.shared.name
  parent_id           = azurerm_user_assigned_identity.ci.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:${var.github_repo}:environment:${var.github_environment}"
}
