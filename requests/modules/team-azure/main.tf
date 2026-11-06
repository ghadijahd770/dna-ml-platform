# Everything one team gets: an Azure ML workspace, a Foundry resource with projects and
# approved models, budgets and role assignments. Settings come from requests/teams/<team>.yaml.

locals {
  t        = var.team
  location = var.platform.location

  name_suffix = "${var.platform.env}-${var.platform.region_code}-${var.platform.instance}"
  env         = var.platform.env
  unique6     = substr(md5("${var.subscription_id}-${var.team_name}-${local.env}"), 0, 6)
  unique8     = substr(md5("${var.subscription_id}-${var.team_name}-${local.env}"), 0, 8)

  # Entra group object IDs. Missing or empty groups are skipped.
  group_defaults = {
    data_engineers   = ""
    data_scientists  = ""
    ml_engineers     = ""
    genai_developers = ""
    viewers          = ""
  }

  groups_raw      = merge(local.group_defaults, try(local.t.groups, {}))
  groups          = { for k, v in local.groups_raw : k => v == null ? "" : tostring(v) }
  platform_admins = var.platform.platform_admins_group_id

  tags = {
    owner      = try(local.t.owner, var.team_name)
    env        = local.env == "sbx" ? "sandbox" : local.env
    costcentre = try(local.t.cost_centre, "")
    expires    = try(tostring(local.t.expires), "")
    team       = var.team_name
    workload   = "dna-ml-platform"
    managed_by = "terraform"
  }

  # Azure ML settings with defaults.
  ml_enabled      = try(local.t.azure_ml.enabled, true)
  cpu_vm_size     = try(local.t.azure_ml.cpu_cluster.vm_size, "Standard_DS3_v2")
  cpu_max_nodes   = try(local.t.azure_ml.cpu_cluster.max_nodes, 2)
  gpu_enabled     = try(local.t.azure_ml.gpu_cluster.enabled, false)
  gpu_vm_size     = try(local.t.azure_ml.gpu_cluster.vm_size, "Standard_NC4as_T4_v3")
  gpu_max_nodes   = try(local.t.azure_ml.gpu_cluster.max_nodes, 1)
  disable_st_keys = try(local.t.azure_ml.disable_storage_shared_key, false)

  # Foundry settings with defaults. Lists are normalised so every entry has the same shape.
  foundry_enabled = try(local.t.foundry.enabled, true)

  foundry_projects = local.foundry_enabled ? {
    for p in flatten([try(local.t.foundry.projects, [])]) : p.name => {
      name        = tostring(p.name)
      description = try(tostring(p.description), "")
    } if p != null
  } : {}

  foundry_models = local.foundry_enabled ? {
    for m in flatten([try(local.t.foundry.models, [])]) : m.name => {
      name     = tostring(m.name)
      model    = tostring(m.model)
      version  = tostring(m.version)
      format   = try(tostring(m.format), "OpenAI")
      sku      = try(tostring(m.sku), "Standard")
      capacity = try(tonumber(m.capacity), 10)
    } if m != null
  } : {}

  monthly_budget = try(local.t.monthly_budget, 500)
}

resource "azurerm_resource_group" "ml" {
  count    = local.ml_enabled ? 1 : 0
  name     = "rg-${var.team_name}-ml-${local.name_suffix}"
  location = local.location
  tags     = local.tags

  lifecycle {
    precondition {
      condition     = local.tags.costcentre != "" && local.tags.costcentre != "CHANGE-ME"
      error_message = "Set cost_centre in requests/teams/${var.team_name}.yaml."
    }
  }
}

resource "azurerm_resource_group" "ai" {
  count    = local.foundry_enabled ? 1 : 0
  name     = "rg-${var.team_name}-ai-${local.name_suffix}"
  location = local.location
  tags     = local.tags

  lifecycle {
    precondition {
      condition     = local.tags.costcentre != "" && local.tags.costcentre != "CHANGE-ME"
      error_message = "Set cost_centre in requests/teams/${var.team_name}.yaml."
    }
  }
}
