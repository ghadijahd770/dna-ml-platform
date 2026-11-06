terraform {
  required_version = ">= 1.9.0"

  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = "~> 1.0"
    }
  }

  # State is stored next to the Azure state. Settings come from backend.sandbox.hcl.
  backend "azurerm" {}
}

# Login comes from environment variables:
#   local: FABRIC_USE_CLI=true after `az login` (scripts/deploy-fabric.sh sets it)
# The person running this must be an Admin of the Fabric workspace.
provider "fabric" {}
