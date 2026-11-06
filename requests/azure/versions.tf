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

  # State lives in the storage account created by bootstrap/bootstrap-state.sh.
  backend "azurerm" {}
}

provider "azurerm" {
  # The subscription comes from ARM_SUBSCRIPTION_ID (set by scripts/deploy.sh or the workflow).
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
