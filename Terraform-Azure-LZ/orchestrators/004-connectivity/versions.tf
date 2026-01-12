# =============================================================================
# VERSIONS.TF - TERRAFORM AND PROVIDER CONSTRAINTS
# =============================================================================
# Orchestrator: 04-connectivity
# Description:  Deploys Hub VNets, Azure Firewall, Bastion, DNS, Gateways
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
      version = ">= 2.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }

  # ===========================================================================
  # BACKEND CONFIGURATION - Azure Storage
  # ===========================================================================
  # Replace placeholders before running terraform init:
  # - __TFSTATE_SUBSCRIPTION_ID__  : Subscription containing tfstate storage
  # - __TFSTATE_RESOURCE_GROUP__   : Resource group name
  # - __TFSTATE_STORAGE_ACCOUNT__  : Storage account name
  # ===========================================================================
  backend "azurerm" {
    subscription_id      = "ef7442e9-4d15-4a28-939a-f428a3d59487"
    resource_group_name  = "rg-intelly-terraform-state"
    storage_account_name = "stintellytfstate"
    container_name       = "tfstate"
    key                  = "connectivity.tfstate"
  }
}
