# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Data Sources - Orchestrator 03-Management                                     ║
# ║ Reads outputs from foundation.tfstate and governance.tfstate                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════════════════════════════════════════════════════════════════════════════
# Remote State - Foundation (01-foundation)
# ══════════════════════════════════════════════════════════════════════════════
# Provides:
# - primary_location, secondary_location, allowed_regions
# - root_mg_id, all_mg_ids
# - common_tags, tenant_id

data "terraform_remote_state" "foundation" {
  backend = "azurerm"

  config = {
    subscription_id      = "ef7442e9-4d15-4a28-939a-f428a3d59487"
    resource_group_name  = "rg-intelly-terraform-state"
    storage_account_name = "stintellytfstate"
    container_name       = "tfstate"
    key                  = "Foundation"
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Remote State - Governance (02-governance)
# ══════════════════════════════════════════════════════════════════════════════
# Provides:
# - policy_definition_ids
# - all_initiative_ids
# - all_assignment_ids

data "terraform_remote_state" "governance" {
  backend = "azurerm"

  config = {
    subscription_id      = "ef7442e9-4d15-4a28-939a-f428a3d59487"
    resource_group_name  = "rg-intelly-terraform-state"
    storage_account_name = "stintellytfstate"
    container_name       = "tfstate"
    key                  = "Governance"
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Data Source - Current Subscription
# ══════════════════════════════════════════════════════════════════════════════

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

# ══════════════════════════════════════════════════════════════════════════════
# Outputs disponibles depuis foundation.tfstate:
# ══════════════════════════════════════════════════════════════════════════════
# 
# data.terraform_remote_state.foundation.outputs.root_mg_id
# data.terraform_remote_state.foundation.outputs.root_id
# data.terraform_remote_state.foundation.outputs.root_name
# data.terraform_remote_state.foundation.outputs.tenant_id
# data.terraform_remote_state.foundation.outputs.all_mg_ids
# data.terraform_remote_state.foundation.outputs.primary_location
# data.terraform_remote_state.foundation.outputs.secondary_location
# data.terraform_remote_state.foundation.outputs.allowed_regions
# data.terraform_remote_state.foundation.outputs.common_tags
#
# ══════════════════════════════════════════════════════════════════════════════
# Outputs disponibles depuis governance.tfstate:
# ══════════════════════════════════════════════════════════════════════════════
#
# data.terraform_remote_state.governance.outputs.policy_definition_ids
# data.terraform_remote_state.governance.outputs.all_initiative_ids
# data.terraform_remote_state.governance.outputs.all_assignment_ids
# data.terraform_remote_state.governance.outputs.caf_initiative_ids
# ══════════════════════════════════════════════════════════════════════════════
