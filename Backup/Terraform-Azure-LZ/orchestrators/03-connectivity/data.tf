# =============================================================================
# DATA.TF - REMOTE STATE REFERENCES (LOCAL BACKEND)
# =============================================================================
# This file reads outputs from other orchestrators to enable dynamic
# configuration without hardcoding values.
#
# Folder structure expected:
# Terraform-Azure-LZ/
# └── orchestrators/
#     ├── 01-foundation/
#     │   └── terraform.tfstate
#     ├── 02-management/
#     │   └── terraform.tfstate
#     └── 03-connectivity/
#         ├── main.tf
#         ├── data.tf  ← THIS FILE
#         └── terraform.tfstate
# =============================================================================

# -----------------------------------------------------------------------------
# FOUNDATION LAYER (01-foundation)
# -----------------------------------------------------------------------------
# Provides: Management Groups, Naming Conventions, Tags, Subscription Placement
# -----------------------------------------------------------------------------

data "terraform_remote_state" "foundation" {
  backend = "local"

  config = {
    path = "${path.module}/../01-foundation/terraform.tfstate"
  }
}

# -----------------------------------------------------------------------------
# MANAGEMENT LAYER (02-management)
# -----------------------------------------------------------------------------
# Provides: Log Analytics, Automation Account, Action Groups, Alerts, DCR
# -----------------------------------------------------------------------------

data "terraform_remote_state" "management" {
  backend = "local"

  config = {
    path = "${path.module}/../02-management/terraform.tfstate"
  }
}

# =============================================================================
# LOCAL VALUES FROM REMOTE STATE
# =============================================================================
# These locals provide easy access to outputs from other layers with fallbacks
# =============================================================================

locals {
  # ---------------------------------------------------------------------------
  # FOUNDATION LAYER OUTPUTS
  # ---------------------------------------------------------------------------
  foundation = {
    # Management Groups
    management_group_ids = try(
      data.terraform_remote_state.foundation.outputs.management_group_ids,
      {}
    )
    root_management_group_id = try(
      data.terraform_remote_state.foundation.outputs.root_management_group_id,
      null
    )

    # Naming Convention (F02)
    naming_convention = try(
      data.terraform_remote_state.foundation.outputs.naming_convention,
      null
    )

    # Tags (F03)
    default_tags = try(
      data.terraform_remote_state.foundation.outputs.default_tags,
      {}
    )

    # Subscription Placement
    subscription_ids = try(
      data.terraform_remote_state.foundation.outputs.subscription_ids,
      {}
    )
  }

  # ---------------------------------------------------------------------------
  # MANAGEMENT LAYER OUTPUTS
  # ---------------------------------------------------------------------------
  management = {
    # Resource Group
    resource_group_name = try(
      data.terraform_remote_state.management.outputs.resource_group_name,
      null
    )
    resource_group_location = try(
      data.terraform_remote_state.management.outputs.resource_group_location,
      null
    )

    # M01 - Log Analytics Workspace
    log_analytics_id = try(
      data.terraform_remote_state.management.outputs.m01_log_analytics_id,
      null
    )
    log_analytics_workspace_id = try(
      data.terraform_remote_state.management.outputs.m01_log_analytics_workspace_id,
      null
    )
    log_analytics_name = try(
      data.terraform_remote_state.management.outputs.m01_log_analytics_name,
      null
    )
    log_analytics_primary_key = try(
      data.terraform_remote_state.management.outputs.m01_log_analytics_primary_key,
      null
    )

    # M02 - Automation Account
    automation_account_id = try(
      data.terraform_remote_state.management.outputs.m02_automation_account_id,
      null
    )
    automation_account_name = try(
      data.terraform_remote_state.management.outputs.m02_automation_account_name,
      null
    )
    automation_principal_id = try(
      data.terraform_remote_state.management.outputs.m02_automation_principal_id,
      null
    )

    # M03 - Action Groups
    action_group_ids = try(
      data.terraform_remote_state.management.outputs.m03_action_group_ids,
      {}
    )
    critical_action_group_id = try(
      data.terraform_remote_state.management.outputs.m03_critical_action_group_id,
      null
    )
    warning_action_group_id = try(
      data.terraform_remote_state.management.outputs.m03_warning_action_group_id,
      null
    )
    info_action_group_id = try(
      data.terraform_remote_state.management.outputs.m03_info_action_group_id,
      null
    )

    # M07 - Data Collection Rules
    dcr_ids = try(
      data.terraform_remote_state.management.outputs.m07_dcr_ids,
      {}
    )

    # M08 - Diagnostics Storage
    diagnostics_storage_id = try(
      data.terraform_remote_state.management.outputs.m08_storage_account_id,
      null
    )

    # Complete Management Layer Config
    management_layer_config = try(
      data.terraform_remote_state.management.outputs.management_layer_config,
      null
    )
  }

  # ---------------------------------------------------------------------------
  # EFFECTIVE VALUES (with variable overrides and fallbacks)
  # ---------------------------------------------------------------------------
  # These values use variable overrides first, then remote state, then defaults

  effective_log_analytics_workspace_id = coalesce(
    var.log_analytics_workspace_id,
    local.management.log_analytics_id,
    ""
  )

  effective_log_analytics_name = coalesce(
    local.management.log_analytics_name,
    ""
  )

  effective_management_resource_group = coalesce(
    local.management.resource_group_name,
    ""
  )

  # ---------------------------------------------------------------------------
  # VALIDATION FLAGS
  # ---------------------------------------------------------------------------
  # Use these to check if remote state data is available

  has_foundation_state = (
    try(data.terraform_remote_state.foundation.outputs, null) != null
  )

  has_management_state = (
    try(data.terraform_remote_state.management.outputs, null) != null
  )

  has_log_analytics = (
    local.effective_log_analytics_workspace_id != ""
  )
}

# =============================================================================
# AZURE DATA SOURCES (Optional - for additional lookups)
# =============================================================================

# Get current Azure client configuration
data "azurerm_client_config" "current" {}

# Get current subscription details
data "azurerm_subscription" "current" {}

# =============================================================================
# OUTPUTS FOR DEBUGGING (Optional - comment out in production)
# =============================================================================

# Uncomment these outputs to debug remote state connectivity:
#
# output "debug_foundation_available" {
#   description = "DEBUG: Foundation state available"
#   value       = local.has_foundation_state
# }
#
# output "debug_management_available" {
#   description = "DEBUG: Management state available"
#   value       = local.has_management_state
# }
#
# output "debug_management_outputs" {
#   description = "DEBUG: All management outputs"
#   value       = try(data.terraform_remote_state.management.outputs, {})
#   sensitive   = true
# }
#
# output "debug_effective_log_analytics_id" {
#   description = "DEBUG: Effective Log Analytics ID being used"
#   value       = local.effective_log_analytics_workspace_id
# }
