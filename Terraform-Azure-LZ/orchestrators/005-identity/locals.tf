# =============================================================================
# LOCALS.TF - Data Transformations
# =============================================================================
# Orchestrator: 05-identity
# Purpose: Transform inputs and resolve scopes from remote state
# =============================================================================

locals {
  # ---------------------------------------------------------------------------
  # Tags (CAF Compliant)
  # ---------------------------------------------------------------------------
  default_tags = {
    Environment = var.environment
    Owner       = var.owner
    CostCenter  = var.cost_center
    Application = var.application
    ManagedBy   = "Terraform"
    Module      = "05-identity"
  }
  tags = merge(local.default_tags, var.tags)

  # ---------------------------------------------------------------------------
  # Location short codes for naming
  # ---------------------------------------------------------------------------
  location_short_codes = {
    "australiaeast"      = "aue"
    "australiasoutheast" = "ause"
    "eastus"             = "eus"
    "westus"             = "wus"
    "westeurope"         = "weu"
    "northeurope"        = "neu"
  }
  location_short = try(local.location_short_codes[var.location], substr(var.location, 0, 4))

  # ---------------------------------------------------------------------------
  # Resource Group (for Managed Identities if enabled)
  # ---------------------------------------------------------------------------
  resource_group_name = "rg-${var.project_name}-${local.location_short}-001"

  # ---------------------------------------------------------------------------
  # Foundation - Management Group IDs from Remote State
  # ---------------------------------------------------------------------------
  # Get all MG IDs from foundation state
  all_mg_ids = try(data.terraform_remote_state.foundation.outputs.all_mg_ids, {})

  # Also try individual outputs as fallback
  mg_id_fallbacks = {
    root           = try(data.terraform_remote_state.foundation.outputs.root_mg_id, null)
    platform       = try(data.terraform_remote_state.foundation.outputs.platform_mg_id, null)
    management     = try(data.terraform_remote_state.foundation.outputs.management_mg_id, null)
    connectivity   = try(data.terraform_remote_state.foundation.outputs.connectivity_mg_id, null)
    identity       = try(data.terraform_remote_state.foundation.outputs.identity_mg_id, null)
    landing_zones  = try(data.terraform_remote_state.foundation.outputs.landing_zones_mg_id, null)
    corp_prod      = try(data.terraform_remote_state.foundation.outputs.corp_prod_mg_id, null)
    corp_nonprod   = try(data.terraform_remote_state.foundation.outputs.corp_nonprod_mg_id, null)
    online_prod    = try(data.terraform_remote_state.foundation.outputs.online_prod_mg_id, null)
    online_nonprod = try(data.terraform_remote_state.foundation.outputs.online_nonprod_mg_id, null)
    sandbox        = try(data.terraform_remote_state.foundation.outputs.sandbox_mg_id, null)
    decommissioned = try(data.terraform_remote_state.foundation.outputs.decommissioned_mg_id, null)
  }

  # ---------------------------------------------------------------------------
  # Management Group Name to ID Mapping
  # ---------------------------------------------------------------------------
  # This maps MG display names/short names to their full resource IDs
  # Supports multiple naming patterns for flexibility
  mg_name_to_id = merge(
    # From all_mg_ids output (primary source)
    {
      for key, value in local.all_mg_ids :
      key => tostring(value)
    },
    # Add name-based lookups (e.g., "intelly" -> root MG ID)
    {
      for key, value in local.all_mg_ids :
      try(regex("managementGroups/([^/]+)$", tostring(value))[0], key) => tostring(value)
      if value != null
    },
    # Fallback individual outputs
    {
      for key, value in local.mg_id_fallbacks :
      key => tostring(value)
      if value != null
    }
  )

  # ---------------------------------------------------------------------------
  # Role Assignments - Resolve Scopes
  # ---------------------------------------------------------------------------
  role_assignments_resolved = {
    for key, assignment in var.role_assignments : key => {
      group_display_name = assignment.group_display_name
      principal_id       = data.azuread_group.groups[assignment.group_display_name].object_id
      role_name          = assignment.role_name
      description        = assignment.description
      scope = (
        assignment.scope_type == "management_group" ?
        try(
          local.mg_name_to_id[assignment.scope_name],
          local.mg_name_to_id[replace(assignment.scope_name, "-", "_")],
          null
        ) :
        assignment.scope_type == "subscription" ?
        "/subscriptions/${assignment.scope_id}" :
        null
      )
    }
  }

  # ---------------------------------------------------------------------------
  # Managed Identities - Resolve Role Assignment Scopes
  # ---------------------------------------------------------------------------
  managed_identities_resolved = {
    for key, mi in var.managed_identities : key => {
      name        = mi.name != null ? mi.name : "uami-${var.project_name}-${key}-${local.location_short}-001"
      description = mi.description
      role_assignments = {
        for ra_key, ra in mi.role_assignments : ra_key => {
          role_name = ra.role_name
          scope = (
            ra.scope_type == "management_group" ?
            try(
              local.mg_name_to_id[ra.scope_name],
              local.mg_name_to_id[replace(ra.scope_name, "-", "_")],
              null
            ) :
            ra.scope_type == "subscription" ?
            "/subscriptions/${ra.scope_id}" :
            null
          )
        }
      }
    }
  }
}
