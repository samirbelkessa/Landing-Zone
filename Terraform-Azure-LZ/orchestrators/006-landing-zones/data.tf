# =============================================================================
# DATA.TF - Remote State and Data Sources
# =============================================================================
# Orchestrator: 06-landing-zones
# Purpose: Retrieve outputs from foundation, governance, management, connectivity
# =============================================================================

# -----------------------------------------------------------------------------
# REMOTE STATE - 01-FOUNDATION
# -----------------------------------------------------------------------------
# Provides: Management Group IDs for archetype placement
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
# REMOTE STATE - 02-GOVERNANCE
# -----------------------------------------------------------------------------
# Provides: Policy definitions and assignments (inherited via MG)
# -----------------------------------------------------------------------------
data "terraform_remote_state" "governance" {
  backend = "azurerm"

  config = {
    subscription_id      = var.terraform_state_subscription_id
    resource_group_name  = var.remote_state_resource_group
    storage_account_name = var.remote_state_storage_account
    container_name       = var.remote_state_container
    key                  = "governance.tfstate"
  }
}

# -----------------------------------------------------------------------------
# REMOTE STATE - 03-MANAGEMENT
# -----------------------------------------------------------------------------
# Provides: Log Analytics workspace ID for diagnostics
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
# Provides: Hub VNet IDs, Firewall IPs, DNS servers, Route Tables, DNS Zones
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
# DATA SOURCES - Private DNS Zones in Connectivity Subscription
# -----------------------------------------------------------------------------
# DNS Zone IDs are retrieved from the connectivity remote state output
# No data source needed - we use the outputs directly
# -----------------------------------------------------------------------------

# Note: Private DNS Zone IDs come from:
# data.terraform_remote_state.connectivity.outputs.private_dns_zone_ids
