# =============================================================================
# VERSIONS.TF - Terraform and Provider Constraints
# =============================================================================
# Orchestrator: 05-identity
# Purpose: RBAC Role Assignments and Managed Identities (CAF Compliant)
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.45.0"
    }
  }

  # Backend configuration - uncomment for production
   backend "azurerm" {
    subscription_id      = "ef7442e9-4d15-4a28-939a-f428a3d59487"
    resource_group_name  = "rg-intelly-terraform-state"
    storage_account_name = "stintellytfstate"
    container_name       = "tfstate"
    key                  = "identity.tfstate"
  }
}
