# Azure Machine Learning workspace for the team.
# Sandbox network decision: public endpoint + Entra-only login + Microsoft-managed network.

resource "azurerm_storage_account" "ml" {
  count                           = local.ml_enabled ? 1 : 0
  name                            = "st${var.team_name}ml${local.env}${local.unique8}"
  location                        = local.location
  resource_group_name             = azurerm_resource_group.ml[0].name
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = !local.disable_st_keys
  public_network_access_enabled   = true
  tags                            = local.tags
}

# Used by Azure ML itself.
resource "azurerm_key_vault" "ml" {
  count                         = local.ml_enabled ? 1 : 0
  name                          = "kv-${var.team_name}-ml-${local.env}-${local.unique6}"
  location                      = local.location
  resource_group_name           = azurerm_resource_group.ml[0].name
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  enable_rbac_authorization     = true
  purge_protection_enabled      = false
  soft_delete_retention_days    = 7
  public_network_access_enabled = true
  tags                          = local.tags
}

resource "azurerm_application_insights" "ml" {
  count               = local.ml_enabled ? 1 : 0
  name                = "appi-${var.team_name}-ml-${local.name_suffix}"
  location            = local.location
  resource_group_name = azurerm_resource_group.ml[0].name
  workspace_id        = var.platform.log_analytics_workspace_id
  application_type    = "web"
  tags                = local.tags
}

# Model images. Entra login only (admin user off).
resource "azurerm_container_registry" "ml" {
  count                         = local.ml_enabled ? 1 : 0
  name                          = "cr${var.team_name}ml${local.env}${local.unique8}"
  location                      = local.location
  resource_group_name           = azurerm_resource_group.ml[0].name
  sku                           = "Basic"
  admin_enabled                 = false
  public_network_access_enabled = true
  tags                          = local.tags
}

resource "azurerm_machine_learning_workspace" "main" {
  count                         = local.ml_enabled ? 1 : 0
  name                          = "mlw-${var.team_name}-${local.name_suffix}"
  location                      = local.location
  resource_group_name           = azurerm_resource_group.ml[0].name
  friendly_name                 = "${upper(var.team_name)} ML ${local.env}"
  description                   = "${upper(var.team_name)} team Azure ML workspace (${local.env})."
  storage_account_id            = azurerm_storage_account.ml[0].id
  key_vault_id                  = azurerm_key_vault.ml[0].id
  application_insights_id       = azurerm_application_insights.ml[0].id
  container_registry_id         = azurerm_container_registry.ml[0].id
  public_network_access_enabled = true
  tags                          = local.tags

  identity {
    type = "SystemAssigned"
  }

  managed_network {
    isolation_mode = "AllowInternetOutbound"
  }
}

resource "azurerm_monitor_diagnostic_setting" "ml_workspace" {
  count                      = local.ml_enabled ? 1 : 0
  name                       = "to-log-analytics"
  target_resource_id         = azurerm_machine_learning_workspace.main[0].id
  log_analytics_workspace_id = var.platform.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
  }
}

# Compute scales to zero, so you only pay while training.
resource "azurerm_machine_learning_compute_cluster" "cpu" {
  count                         = local.ml_enabled ? 1 : 0
  name                          = "cpu-cluster"
  location                      = local.location
  machine_learning_workspace_id = azurerm_machine_learning_workspace.main[0].id
  vm_priority                   = "Dedicated"
  vm_size                       = local.cpu_vm_size
  local_auth_enabled            = false

  scale_settings {
    min_node_count                       = 0
    max_node_count                       = local.cpu_max_nodes
    scale_down_nodes_after_idle_duration = "PT120S"
  }
}

resource "azurerm_machine_learning_compute_cluster" "gpu" {
  count                         = local.ml_enabled && local.gpu_enabled ? 1 : 0
  name                          = "gpu-cluster"
  location                      = local.location
  machine_learning_workspace_id = azurerm_machine_learning_workspace.main[0].id
  vm_priority                   = "Dedicated"
  vm_size                       = local.gpu_vm_size
  local_auth_enabled            = false

  scale_settings {
    min_node_count                       = 0
    max_node_count                       = local.gpu_max_nodes
    scale_down_nodes_after_idle_duration = "PT120S"
  }
}
