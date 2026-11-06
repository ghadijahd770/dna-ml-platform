terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }

    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }

  # State is stored in the storage account created by scripts/bootstrap-state.sh.
  # Settings come from backend.sandbox.hcl (terraform init -backend-config=backend.sandbox.hcl).
  backend "azurerm" {}
}

provider "azurerm" {
  # The subscription comes from ARM_SUBSCRIPTION_ID (set by scripts/deploy-sandbox.sh or the workflow).
  # Storage is managed with Entra login, not shared keys.
  storage_use_azuread = true

  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }

    resource_group {
      prevent_deletion_if_contains_resources = true
    }

    cognitive_account {
      purge_soft_delete_on_destroy = false
    }
  }
}

provider "azapi" {}
