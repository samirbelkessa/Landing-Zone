################################################################################
# versions.tf - Terraform and Provider Version Constraints
# Module: naming-convention (F02)
################################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    # No provider required - this is a pure Terraform module
    # using only local values and outputs
  }
}
provider "azurerm" {
  subscription_id = "ef7442e9-4d15-4a28-939a-f428a3d59487"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
