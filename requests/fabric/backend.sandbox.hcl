# Where Terraform keeps the Fabric requests state. bootstrap/bootstrap-state.sh fills in storage_account_name.
resource_group_name  = "rg-dna-tfstate-sbx-san-01"
storage_account_name = "CHANGE-ME"
container_name       = "tfstate"
key                  = "requests-sandbox-fabric.tfstate"
use_azuread_auth     = true
