terraform {
  required_version = ">= 1.9.0"

  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = "~> 1.0"
    }
  }

  # State lives next to the other stacks. Settings come from backend.sandbox.hcl.
  backend "azurerm" {}
}

# Login comes from environment variables. Locally scripts/deploy.sh sets FABRIC_USE_CLI=true
# after `az login`. The person running this must be an Admin of each team's Fabric workspace.
provider "fabric" {}
