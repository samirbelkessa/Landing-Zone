locals {
  alerts_integration_enabled = length(var.action_group_ids) > 0

  all_configurations = merge(
    var.maintenance_configurations,
    local.default_windows_config,
    local.default_linux_config
  )

  configuration_names = {
    for key, config in local.all_configurations :
    key => "${local.name_prefix}-${key}"
  }

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

  default_locations = length(var.default_target_locations) > 0 ? var.default_target_locations : [var.location]

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
          kb_numbers_to_exclude      = []
          kb_numbers_to_include      = []
        }

        linux = null
      }

      in_guest_user_patch_mode = "User"
    }
  } : {}

  log_analytics_integration_enabled = var.log_analytics_workspace_id != null

  name_prefix = var.custom_name_prefix != null ? var.custom_name_prefix : (
    "mc-${var.workload}-${var.environment}-${var.region}-${var.instance}"
  )

  next_sunday = formatdate("YYYY-MM-DD", timeadd(timestamp(), "168h"))

  tags = merge(
    var.tags,
    {
      Module = "M06-update-management"
    }
  )

}
