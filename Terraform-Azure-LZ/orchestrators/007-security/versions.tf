# =============================================================================
# VERSIONS.TF - Terraform and Provider Constraints
# =============================================================================
# Orchestrator: 007-security
# Purpose: Security components deployment (Defender, Sentinel, Key Vault, NSG)
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # ---------------------------------------------------------------------------
  # Backend Configuration (Brainboard managed)
  # ---------------------------------------------------------------------------
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state-aue"
  #   storage_account_name = "stlzterraformstateaue"
  #   container_name       = "tfstate"
  #   key                  = "security.tfstate"
  # }
}

# =============================================================================
# PROVIDER CONFIGURATION
# =============================================================================

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = false
    }
  }
  subscription_id = var.management_subscription_id
}

# Provider alias for Connectivity subscription (Private Endpoints)
provider "azurerm" {
  alias           = "connectivity"
  subscription_id = var.connectivity_subscription_id
  features {}
}

# Provider alias for Identity subscription (Defender)
provider "azurerm" {
  alias           = "identity"
  subscription_id = var.identity_subscription_id
  features {}
}
