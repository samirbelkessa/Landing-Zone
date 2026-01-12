# =============================================================================
# PROVIDERS.TF - Azure Provider Configuration
# =============================================================================
# Orchestrator: 05-identity
# Purpose: Configure providers for Identity deployment
# =============================================================================

# -----------------------------------------------------------------------------
# DEFAULT PROVIDER - Identity Subscription
# -----------------------------------------------------------------------------
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  tenant_id       = var.tenant_id
  subscription_id = var.identity_subscription_id
}

# -----------------------------------------------------------------------------
# TERRAFORM STATE PROVIDER - For Remote State Access
# -----------------------------------------------------------------------------
provider "azurerm" {
  alias = "tfstate"

  features {}

  tenant_id       = var.tenant_id
  subscription_id = var.terraform_state_subscription_id
}

# -----------------------------------------------------------------------------
# AZURE AD PROVIDER - For Entra ID Operations
# -----------------------------------------------------------------------------
provider "azuread" {
  tenant_id = var.tenant_id
}
