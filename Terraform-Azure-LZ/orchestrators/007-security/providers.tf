# =============================================================================
# PROVIDERS.TF - Azure Provider Configuration
# =============================================================================
# Orchestrator: 07-security
# Purpose: Configure providers for Security deployment across subscriptions
# =============================================================================

# -----------------------------------------------------------------------------
# DEFAULT PROVIDER - Management Subscription
# -----------------------------------------------------------------------------
# Used for: Key Vault, Sentinel, Security RG
# -----------------------------------------------------------------------------
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  tenant_id       = var.tenant_id
  subscription_id = var.management_subscription_id
}

# -----------------------------------------------------------------------------
# TERRAFORM STATE PROVIDER
# -----------------------------------------------------------------------------
provider "azurerm" {
  alias = "tfstate"

  features {}

  tenant_id       = var.tenant_id
  subscription_id = var.terraform_state_subscription_id
}

# -----------------------------------------------------------------------------
# CONNECTIVITY SUBSCRIPTION PROVIDER
# -----------------------------------------------------------------------------
# Used for: Private Endpoint in Hub VNet (if needed)
# -----------------------------------------------------------------------------
provider "azurerm" {
  alias = "connectivity"

  features {}

  tenant_id       = var.tenant_id
  subscription_id = var.connectivity_subscription_id
}

# -----------------------------------------------------------------------------
# IDENTITY SUBSCRIPTION PROVIDER
# -----------------------------------------------------------------------------
provider "azurerm" {
  alias = "identity"

  features {}

  tenant_id       = var.tenant_id
  subscription_id = var.identity_subscription_id
}

# -----------------------------------------------------------------------------
# AZURE AD PROVIDER
# -----------------------------------------------------------------------------
provider "azuread" {
  tenant_id = var.tenant_id
}
