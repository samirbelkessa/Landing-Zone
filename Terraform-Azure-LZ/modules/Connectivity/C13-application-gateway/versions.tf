# -----------------------------------------------------------------------------
# C13 - APPLICATION GATEWAY MODULE
# Provider and Terraform version constraints
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.57.0"
    }
  }
}
