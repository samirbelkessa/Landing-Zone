# =============================================================================
# VERSIONS.TF - Terraform and Provider Constraints
# =============================================================================
# Orchestrator: 06-landing-zones
# Purpose: Deploy Landing Zone subscriptions with VNets, subnets, and Hub peering
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0, < 5.0.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">= 1.9.0"
    }
  }

  # ---------------------------------------------------------------------------
  # BACKEND CONFIGURATION
  # ---------------------------------------------------------------------------
  # Brainboard manages the backend configuration automatically.
  # For local development, uncomment and configure:
  # ---------------------------------------------------------------------------
   backend "azurerm" {
    subscription_id      = "ef7442e9-4d15-4a28-939a-f428a3d59487"
    resource_group_name  = "rg-intelly-terraform-state"
    storage_account_name = "stintellytfstate"
    container_name       = "tfstate"
     key                  = "landing-zones.tfstate"
   }
}
