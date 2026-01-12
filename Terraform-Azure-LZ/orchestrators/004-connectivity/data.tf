# =============================================================================
# DATA.TF - REMOTE STATE REFERENCES
# =============================================================================
# Orchestrator: 04-connectivity
# 
# This file reads outputs from other orchestrators:
# - foundation.tfstate  → Locations, tenant_id, root_id, common_tags
# - governance.tfstate  → Policy IDs (for reference)
# - management.tfstate  → Log Analytics, Action Groups, Storage Account
#
# Replace placeholders before terraform init:
# - __TFSTATE_SUBSCRIPTION_ID__
# - __TFSTATE_RESOURCE_GROUP__
# - __TFSTATE_STORAGE_ACCOUNT__
# =============================================================================

# -----------------------------------------------------------------------------
# FOUNDATION LAYER (01-foundation)
# -----------------------------------------------------------------------------
# Provides: Management Groups, Locations, Tags, Tenant ID
# -----------------------------------------------------------------------------
data "terraform_remote_state" "foundation" {
  backend = "azurerm"

  config = {
    subscription_id      = "ef7442e9-4d15-4a28-939a-f428a3d59487"
    resource_group_name  = "rg-intelly-terraform-state"
    storage_account_name = "stintellytfstate"
    container_name       = "tfstate"
    key                  = "foundation.tfstate"
  }
}

# -----------------------------------------------------------------------------
# GOVERNANCE LAYER (02-governance)
# -----------------------------------------------------------------------------
# Provides: Policy Definition IDs, Initiative IDs, Assignment IDs
# -----------------------------------------------------------------------------
data "terraform_remote_state" "governance" {
  backend = "azurerm"

  config = {
    subscription_id      = "ef7442e9-4d15-4a28-939a-f428a3d59487"
    resource_group_name  = "rg-intelly-terraform-state"
    storage_account_name = "stintellytfstate"
    container_name       = "tfstate"
    key                  = "governance.tfstate"
  }
}

# -----------------------------------------------------------------------------
# MANAGEMENT LAYER (03-management)
# -----------------------------------------------------------------------------
# Provides: Log Analytics, Automation Account, Action Groups, Alerts, DCR
# -----------------------------------------------------------------------------
data "terraform_remote_state" "management" {
  backend = "azurerm"

  config = {
    subscription_id      = "ef7442e9-4d15-4a28-939a-f428a3d59487"
    resource_group_name  = "rg-intelly-terraform-state"
    storage_account_name = "stintellytfstate"
    container_name       = "tfstate"
    key                  = "management.tfstate"
  }
}

# =============================================================================
# AZURE DATA SOURCES
# =============================================================================
data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

# =============================================================================
# OUTPUTS AVAILABLE FROM REMOTE STATES (for reference)
# =============================================================================
# 
# FOUNDATION (data.terraform_remote_state.foundation.outputs.*):
# ├── root_mg_id              → Root Management Group ID
# ├── root_id                 → Root ID (e.g., "intelly")
# ├── tenant_id               → Azure Tenant ID
# ├── all_mg_ids              → Map of all Management Group IDs
# ├── primary_location        → "australiaeast"
# ├── secondary_location      → "australiasoutheast"
# ├── allowed_regions         → ["australiaeast", "australiasoutheast"]
# └── common_tags             → Default tags for all resources
#
# GOVERNANCE (data.terraform_remote_state.governance.outputs.*):
# ├── policy_definition_ids   → Map of custom policy definition IDs
# ├── all_initiative_ids      → Map of initiative IDs
# └── all_assignment_ids      → Map of assignment IDs
#
# MANAGEMENT (data.terraform_remote_state.management.outputs.*):
# ├── resource_group_name           → "rg-management-prd-aue-001"
# ├── resource_group_location       → "australiaeast"
# ├── m01_log_analytics_id          → Log Analytics Resource ID
# ├── m01_log_analytics_workspace_id→ Workspace GUID
# ├── m01_log_analytics_name        → "log-platform-prd-aue-001"
# ├── m03_action_group_ids          → Map of action group IDs
# ├── m03_critical_action_group_id  → Critical action group ID
# ├── m08_diagnostics_storage_id    → Diagnostics storage account ID
# └── management_layer_config       → Complete management config object
# =============================================================================
