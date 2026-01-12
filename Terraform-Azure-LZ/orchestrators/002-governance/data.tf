# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Data Sources - Orchestrator 02-Governance                                     ║
# ║ Reads outputs from 01-foundation tfstate                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════════════════════════════════════════════════════════════════════════════
# Remote State - Foundation (F01)
# ══════════════════════════════════════════════════════════════════════════════
# Reads the management group hierarchy created by 01-foundation
# This avoids recreating MGs and ensures consistency

data "terraform_remote_state" "foundation" {
  backend = "azurerm"

  config = {
    subscription_id      = "ef7442e9-4d15-4a28-939a-f428a3d59487"  # ← Ta sub tfstate
    resource_group_name  = "rg-intelly-terraform-state"
    storage_account_name = "stintellytfstate"
    container_name       = "tfstate"
    key                  = "foundation.tfstate"
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Outputs disponibles depuis foundation.tfstate:
# ══════════════════════════════════════════════════════════════════════════════
# 
# data.terraform_remote_state.foundation.outputs.root_mg_id
# data.terraform_remote_state.foundation.outputs.root_id
# data.terraform_remote_state.foundation.outputs.root_name
# data.terraform_remote_state.foundation.outputs.tenant_id
# data.terraform_remote_state.foundation.outputs.all_mg_ids
# data.terraform_remote_state.foundation.outputs.all_mg_names
# data.terraform_remote_state.foundation.outputs.deployment_flags
# data.terraform_remote_state.foundation.outputs.primary_location
# data.terraform_remote_state.foundation.outputs.secondary_location
# data.terraform_remote_state.foundation.outputs.allowed_regions
# data.terraform_remote_state.foundation.outputs.common_tags
#
# Management Group IDs individuels:
# data.terraform_remote_state.foundation.outputs.platform_mg_id
# data.terraform_remote_state.foundation.outputs.management_mg_id
# data.terraform_remote_state.foundation.outputs.connectivity_mg_id
# data.terraform_remote_state.foundation.outputs.identity_mg_id
# data.terraform_remote_state.foundation.outputs.landing_zones_mg_id
# data.terraform_remote_state.foundation.outputs.corp_prod_mg_id
# data.terraform_remote_state.foundation.outputs.corp_nonprod_mg_id
# data.terraform_remote_state.foundation.outputs.online_prod_mg_id
# data.terraform_remote_state.foundation.outputs.online_nonprod_mg_id
# data.terraform_remote_state.foundation.outputs.sandbox_mg_id
# data.terraform_remote_state.foundation.outputs.decommissioned_mg_id
# ══════════════════════════════════════════════════════════════════════════════
