# Where Terraform keeps the platform state. bootstrap/bootstrap-state.sh fills in storage_account_name.
resource_group_name  = "rg-dna-tfstate-sbx-san-01"
storage_account_name = "CHANGE-ME"
container_name       = "tfstate"
key                  = "platform-sandbox.tfstate"
use_azuread_auth     = true
