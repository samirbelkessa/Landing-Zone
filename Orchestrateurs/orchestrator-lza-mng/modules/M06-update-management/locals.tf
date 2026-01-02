# ==============================================================================
# M06 - Update Management - Local Values
# ==============================================================================

locals {
  #-----------------------------------------------------------------------------
  # F02 Naming Convention Integration
  #-----------------------------------------------------------------------------
  
  # Maintenance Configurations don't have a standard F02 type
  # Build name manually using F02 pattern: {type}-{workload}-{env}-{region}-{instance}
  name_prefix = var.custom_name_prefix != null ? var.custom_name_prefix : (
    "mc-${var.workload}-${var.environment}-${var.region}-${var.instance}"
  )

  #-----------------------------------------------------------------------------
  # F03 Tags Integration
  #-----------------------------------------------------------------------------
  
  # Call F03 module to generate standardized tags
  module_tags = module.tags.all_tags

  #-----------------------------------------------------------------------------
  # Configuration Names
  #-----------------------------------------------------------------------------
  
  # Generate full names for each maintenance configuration
  # Format: {name_prefix}-{configuration_key}
  # Example: mc-platform-prd-aue-001-critical-monthly
  configuration_names = {
    for key, config in local.all_configurations :
    key => "${local.name_prefix}-${key}"
  }

  #-----------------------------------------------------------------------------
  # Default Locations
  #-----------------------------------------------------------------------------
  
  default_locations = length(var.default_target_locations) > 0 ? var.default_target_locations : [var.location]

  #-----------------------------------------------------------------------------
  # Next Sunday Calculation (for default configs)
  #-----------------------------------------------------------------------------
  
  next_sunday = formatdate("YYYY-MM-DD", timeadd(timestamp(), "168h"))

  #-----------------------------------------------------------------------------
  # Default Windows Maintenance Configuration
  #-----------------------------------------------------------------------------
  
  default_windows_config = var.create_default_windows_config ? {
    "default-windows" = {
      description = "Default Windows maintenance - Critical and Security updates every Sunday"
      scope       = "InGuestPatch"
      visibility  = "Custom"

      window = {
        start_date_time = "${local.next_sunday} 02:00"
        duration        = "02:00"
        time_zone       = var.default_timezone
        recur_every     = "1Week Sunday"
      }

      install_patches = {
        reboot = "IfRequired"

        windows = {
          classifications_to_include = ["Critical", "Security"]
          kb_numbers_to_exclude       = []
          kb_numbers_to_include       = []
        }

        linux = null
      }

      in_guest_user_patch_mode = "User"
    }
  } : {}

  #-----------------------------------------------------------------------------
  # Default Linux Maintenance Configuration
  #-----------------------------------------------------------------------------
  
  default_linux_config = var.create_default_linux_config ? {
    "default-linux" = {
      description = "Default Linux maintenance - Critical and Security updates every Sunday"
      scope       = "InGuestPatch"
      visibility  = "Custom"

      window = {
        start_date_time = "${local.next_sunday} 03:00"
        duration        = "02:00"
        time_zone       = var.default_timezone
        recur_every     = "1Week Sunday"
      }

      install_patches = {
        reboot = "IfRequired"

        linux = {
          classifications_to_include    = ["Critical", "Security"]
          package_names_mask_to_exclude = []
          package_names_mask_to_include = []
        }

        windows = null
      }

      in_guest_user_patch_mode = "User"
    }
  } : {}

  #-----------------------------------------------------------------------------
  # All Configurations (Custom + Defaults)
  #-----------------------------------------------------------------------------
  
  all_configurations = merge(
    var.maintenance_configurations,
    local.default_windows_config,
    local.default_linux_config
  )

  #-----------------------------------------------------------------------------
  # Tags Merger
  #-----------------------------------------------------------------------------
  
  default_tags = {
    ManagedBy = "Terraform"
    Module    = "M06-update-management"
  }

  merged_tags = merge(
    local.default_tags,
    local.module_tags,
    var.additional_tags
  )

  # Already defined above, adding integration flags here
  log_analytics_integration_enabled = var.log_analytics_workspace_id != null
  alerts_integration_enabled        = length(var.action_group_ids) > 0


}

#-------------------------------------------------------------------------------
# F03 Tags Module Call
#-------------------------------------------------------------------------------

module "tags" {
  source = "../F03-tags"

  # Map environment to F03 format
  environment = var.environment == "prod" ? "Production" : (
    var.environment == "dev" ? "Development" : (
      var.environment == "test" ? "Test" : (
        var.environment == "uat" ? "UAT" : "Staging"
      )
    )
  )

  owner               = var.owner
  cost_center         = var.cost_center
  application         = var.application
  criticality         = var.criticality
  data_classification = var.data_classification
  project             = var.project
  department          = var.department
  module_name         = "M06-update-management"
}
