# Where Terraform keeps the state for the Fabric workspace access.
# scripts/bootstrap-state.sh fills in storage_account_name.
resource_group_name  = "rg-dna-tfstate-sbx-san-01"
storage_account_name = "CHANGE-ME"
container_name       = "tfstate"
key                  = "dna-sandbox-fabric.tfstate"
use_azuread_auth     = true
