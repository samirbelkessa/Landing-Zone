# =============================================================================
# DATA.TF - Remote State and Data Sources
# =============================================================================
# Orchestrator: 05-identity
# Purpose: Retrieve outputs from foundation for MG scopes
# =============================================================================

# -----------------------------------------------------------------------------
# REMOTE STATE - 01-FOUNDATION
# -----------------------------------------------------------------------------
# Provides: Management Group IDs for role assignment scopes
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
# CURRENT CLIENT CONFIGURATION
# -----------------------------------------------------------------------------
data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}

# -----------------------------------------------------------------------------
# IDENTITY SUBSCRIPTION
# -----------------------------------------------------------------------------
data "azurerm_subscription" "identity" {
  subscription_id = var.identity_subscription_id
}

# -----------------------------------------------------------------------------
# ENTRA ID GROUPS - Dynamic lookup by display name
# -----------------------------------------------------------------------------
data "azuread_group" "groups" {
  for_each = toset([
    for assignment in var.role_assignments : assignment.group_display_name
  ])

  display_name     = each.value
  security_enabled = true
}
