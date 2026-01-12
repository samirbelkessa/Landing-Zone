# =============================================================================
# DATA.TF - Remote State and Data Sources
# =============================================================================
# Orchestrator: 07-security
# Purpose: Retrieve outputs from other orchestrators
# =============================================================================

# -----------------------------------------------------------------------------
# REMOTE STATE - 01-FOUNDATION
# -----------------------------------------------------------------------------
# Provides: Management Group IDs, Subscription IDs
# -----------------------------------------------------------------------------
data "terraform_remote_state" "foundation" {
  backend = "azurerm"

  config = {
    subscription_id      = var.terraform_state_subscription_id
    resource_group_name  = var.remote_state_resource_group
    storage_account_name = var.remote_state_storage_account
    container_name       = var.remote_state_container
    key                  = "foundation.tfstate"
  }
}

# -----------------------------------------------------------------------------
# REMOTE STATE - 03-MANAGEMENT
# -----------------------------------------------------------------------------
# Provides: Log Analytics Workspace ID, Resource Group
# -----------------------------------------------------------------------------
data "terraform_remote_state" "management" {
  backend = "azurerm"

  config = {
    subscription_id      = var.terraform_state_subscription_id
    resource_group_name  = var.remote_state_resource_group
    storage_account_name = var.remote_state_storage_account
    container_name       = var.remote_state_container
    key                  = "management.tfstate"
  }
}

# -----------------------------------------------------------------------------
# REMOTE STATE - 04-CONNECTIVITY
# -----------------------------------------------------------------------------
# Provides: Hub VNet ID, Subnet IDs, Private DNS Zone IDs
# -----------------------------------------------------------------------------
data "terraform_remote_state" "connectivity" {
  backend = "azurerm"

  config = {
    subscription_id      = var.terraform_state_subscription_id
    resource_group_name  = var.remote_state_resource_group
    storage_account_name = var.remote_state_storage_account
    container_name       = var.remote_state_container
    key                  = "connectivity.tfstate"
  }
}

# -----------------------------------------------------------------------------
# CURRENT CLIENT CONFIGURATION
# -----------------------------------------------------------------------------
data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}

# -----------------------------------------------------------------------------
# MANAGEMENT SUBSCRIPTION
# -----------------------------------------------------------------------------
data "azurerm_subscription" "management" {
  subscription_id = var.management_subscription_id
}

# -----------------------------------------------------------------------------
# CONNECTIVITY SUBSCRIPTION
# -----------------------------------------------------------------------------
data "azurerm_subscription" "connectivity" {
  provider        = azurerm.connectivity
  subscription_id = var.connectivity_subscription_id
}

# -----------------------------------------------------------------------------
# IDENTITY SUBSCRIPTION
# -----------------------------------------------------------------------------
data "azurerm_subscription" "identity" {
  provider        = azurerm.identity
  subscription_id = var.identity_subscription_id
}
