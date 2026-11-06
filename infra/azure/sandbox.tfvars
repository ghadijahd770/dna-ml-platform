# Sandbox settings for the DNA ML platform (Azure resources).
# Fill in CHANGE-ME before the first deployment.
# alert_email and group_ids come from environment variables:
#   TF_VAR_alert_email  and  TF_VAR_group_ids  (set by scripts/get-group-ids.sh or the workflow)

location    = "southafricanorth"
region_code = "san"
env         = "sbx"
team        = "dna"
instance    = "01"

# Tags and cost
owner             = "dna-platform"
cost_centre       = "CHANGE-ME"
expires           = "2027-02-28"
monthly_budget    = 500
budget_start_date = "2026-11-01T00:00:00Z"

# Access
github_repo                  = "ghadijahd770/dna-ml-platform"
github_environment           = "sandbox"
grant_ci_subscription_access = true

# Filled in by scripts/bootstrap-state.sh
tfstate_resource_group_name  = "rg-dna-tfstate-sbx-san-01"
tfstate_storage_account_name = ""

# Azure ML
cpu_cluster_vm_size        = "Standard_DS3_v2"
cpu_cluster_max_nodes      = 2
deploy_gpu_cluster         = false
gpu_cluster_vm_size        = "Standard_NC4as_T4_v3"
gpu_cluster_max_nodes      = 1
disable_storage_shared_key = false

# Foundry
deploy_foundry = true

# Approved models only. Empty until security agrees the list and you've checked the
# model is offered in the region. Data residency: "GlobalStandard" may process prompts
# in any Azure region; "Standard" keeps processing in the resource's region.
# Example:
#   foundry_model_deployments = [
#     { name = "gpt-4o-mini", model = "gpt-4o-mini", version = "2024-07-18", format = "OpenAI", sku = "Standard", capacity = 10 },
#   ]
foundry_model_deployments = []
