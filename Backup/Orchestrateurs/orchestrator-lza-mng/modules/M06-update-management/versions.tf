# ==============================================================================
# M06 - Update Management (Azure Update Manager) - Terraform Version Constraints
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.57.0"
    }
  }
}
