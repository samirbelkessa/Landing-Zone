# =============================================================================
# PROVIDERS.TF - Azure Provider Configuration
# =============================================================================
# Orchestrator: 06-landing-zones
# Purpose: Configure providers for Landing Zone deployment
# =============================================================================

# -----------------------------------------------------------------------------
# DEFAULT PROVIDER - For general operations
# -----------------------------------------------------------------------------
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  tenant_id       = var.tenant_id
  subscription_id = var.management_subscription_id
}

# -----------------------------------------------------------------------------
# TERRAFORM STATE PROVIDER - For Remote State Access
# -----------------------------------------------------------------------------
# Used to access the Storage Account containing Terraform state files
# -----------------------------------------------------------------------------
provider "azurerm" {
  alias = "tfstate"

  features {}

  tenant_id       = var.tenant_id
  subscription_id = var.terraform_state_subscription_id
}

# -----------------------------------------------------------------------------
# CONNECTIVITY PROVIDER - For Hub VNet Peering & DNS
# -----------------------------------------------------------------------------
# Required to create peering from Hub side and manage DNS zone links
# -----------------------------------------------------------------------------
provider "azurerm" {
  alias = "connectivity"

  features {}

  tenant_id       = var.tenant_id
  subscription_id = var.connectivity_subscription_id
}

# -----------------------------------------------------------------------------
# AZAPI PROVIDER - For Advanced Azure Operations
# -----------------------------------------------------------------------------
# Used by AVM modules for subscription vending operations
# -----------------------------------------------------------------------------
provider "azapi" {
  tenant_id = var.tenant_id
}
