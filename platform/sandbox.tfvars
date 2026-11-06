# Sandbox settings for the shared platform foundation.
# Fill in the CHANGE-ME values before the first deployment.

location    = "southafricanorth"
region_code = "san"
env         = "sbx"
prefix      = "dna"
instance    = "01"

# Ownership, cost and alerts
owner             = "dna-platform"
cost_centre       = "CHANGE-ME"
alert_email       = "CHANGE-ME@example.com"
monthly_budget    = 100
budget_start_date = "2026-11-01T00:00:00Z"

# Access: object ID printed by bootstrap/get-group-ids.sh
platform_admins_group_id = ""

github_repo                  = "ghadijahd770/dna-ml-platform"
github_environment           = "sandbox"
grant_ci_subscription_access = true

# Filled in by bootstrap/bootstrap-state.sh
tfstate_resource_group_name  = "rg-dna-tfstate-sbx-san-01"
tfstate_storage_account_name = ""
