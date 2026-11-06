# Azure Machine Learning workspace for the DNA team.
# Sandbox network decision: public endpoint + Entra-only login + Microsoft-managed network.

resource "azurerm_storage_account" "ml" {
  name                            = "st${var.team}ml${var.env}${local.unique8}"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.ml.name
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = !var.disable_storage_shared_key
  public_network_access_enabled   = true
  tags                            = local.expiring_tags
}

# Used by Azure ML itself.
resource "azurerm_key_vault" "ml" {
  name                          = "kv-${var.team}-ml-${var.env}-${local.unique6}"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.ml.name
  tenant_id                     = data.azurerm_subscription.current.tenant_id
  sku_name                      = "standard"
  enable_rbac_authorization     = true
  purge_protection_enabled      = false
  soft_delete_retention_days    = 7
  public_network_access_enabled = true
  tags                          = local.expiring_tags
}

resource "azurerm_application_insights" "ml" {
  name                = "appi-${var.team}-ml-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.ml.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  tags                = local.expiring_tags
}

# Model images. Entra login only (admin user off).
resource "azurerm_container_registry" "ml" {
  name                          = "cr${var.team}ml${var.env}${local.unique8}"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.ml.name
  sku                           = "Basic"
  admin_enabled                 = false
  public_network_access_enabled = true
  tags                          = local.expiring_tags
}

resource "azurerm_machine_learning_workspace" "main" {
  name                          = "mlw-${var.team}-${local.name_suffix}"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.ml.name
  friendly_name                 = "DNA ML ${var.env}"
  description                   = "DNA team Azure ML workspace (${var.env})."
  storage_account_id            = azurerm_storage_account.ml.id
  key_vault_id                  = azurerm_key_vault.ml.id
  application_insights_id       = azurerm_application_insights.ml.id
  container_registry_id         = azurerm_container_registry.ml.id
  public_network_access_enabled = true
  tags                          = local.expiring_tags

  identity {
    type = "SystemAssigned"
  }

  managed_network {
    isolation_mode = "AllowInternetOutbound"
  }
}

resource "azurerm_monitor_diagnostic_setting" "ml_workspace" {
  name                       = "to-log-analytics"
  target_resource_id         = azurerm_machine_learning_workspace.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
  }
}

# Compute scales to zero, so you only pay while training.
resource "azurerm_machine_learning_compute_cluster" "cpu" {
  name                          = "cpu-cluster"
  location                      = var.location
  machine_learning_workspace_id = azurerm_machine_learning_workspace.main.id
  vm_priority                   = "Dedicated"
  vm_size                       = var.cpu_cluster_vm_size
  local_auth_enabled            = false

  scale_settings {
    min_node_count                       = 0
    max_node_count                       = var.cpu_cluster_max_nodes
    scale_down_nodes_after_idle_duration = "PT120S"
  }
}

resource "azurerm_machine_learning_compute_cluster" "gpu" {
  count                         = var.deploy_gpu_cluster ? 1 : 0
  name                          = "gpu-cluster"
  location                      = var.location
  machine_learning_workspace_id = azurerm_machine_learning_workspace.main.id
  vm_priority                   = "Dedicated"
  vm_size                       = var.gpu_cluster_vm_size
  local_auth_enabled            = false

  scale_settings {
    min_node_count                       = 0
    max_node_count                       = var.gpu_cluster_max_nodes
    scale_down_nodes_after_idle_duration = "PT120S"
  }
}
