resource "azurerm_maintenance_configuration" "this" {
  visibility               = try(each.value.visibility, "Custom")
  tags                     = local.tags
  scope                    = each.value.scope
  resource_group_name      = var.resource_group_name
  name                     = local.configuration_names[each.key]
  location                 = var.location
  in_guest_user_patch_mode = try(each.value.in_guest_user_patch_mode, "User")
  for_each                 = local.all_configurations

  window {
    time_zone            = each.value.window.time_zone
    start_date_time      = each.value.window.start_date_time
    recur_every          = each.value.window.recur_every
    expiration_date_time = try(each.value.window.expiration_date_time, null)
    duration             = each.value.window.duration
  }

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [window[0].start_date_time]
  }

  dynamic "install_patches" {
    for_each = each.value.scope == "InGuestPatch" && each.value.install_patches != null ? [each.value.install_patches] : []

    content {
      reboot = try(install_patches.value.reboot, "IfRequired")

      # Linux configuration
      dynamic "linux" {
        for_each = try(install_patches.value.linux, null) != null ? [install_patches.value.linux] : []

        content {
          classifications_to_include    = try(linux.value.classifications_to_include, ["Critical", "Security"])
          package_names_mask_to_exclude = try(linux.value.package_names_mask_to_exclude, null)
          package_names_mask_to_include = try(linux.value.package_names_mask_to_include, null)
        }
      }

      # Windows configuration
      dynamic "windows" {
        for_each = try(install_patches.value.windows, null) != null ? [install_patches.value.windows] : []

        content {
          classifications_to_include = try(windows.value.classifications_to_include, ["Critical", "Security"])
          kb_numbers_to_exclude      = try(windows.value.kb_numbers_to_exclude, null)
          kb_numbers_to_include      = try(windows.value.kb_numbers_to_include, null)
        }
      }
    }
  }
}

resource "azurerm_maintenance_assignment_virtual_machine" "this" {
  virtual_machine_id           = each.value.vm_ids[0]
  maintenance_configuration_id = azurerm_maintenance_configuration.this[each.value.config_key].id
  location                     = var.location
  for_each = {
    for assignment_key, assignment in var.vm_assignments :
    assignment_key => {
      config_key = assignment.maintenance_configuration_key
      vm_ids     = assignment.virtual_machine_ids
    }
  }

  depends_on = [
    azurerm_maintenance_configuration.this,
  ]
}

resource "azurerm_maintenance_assignment_dynamic_scope" "this" {
  name                         = "${local.name_prefix}-assignment-${each.key}"
  maintenance_configuration_id = azurerm_maintenance_configuration.this[each.value.maintenance_configuration_key].id
  for_each                     = var.dynamic_scope_assignments

  depends_on = [
    azurerm_maintenance_configuration.this,
  ]

  filter {
    resource_types  = try(each.value.filter.resource_types, ["Microsoft.Compute/virtualMachines", "Microsoft.HybridCompute/machines"])
    resource_groups = try(each.value.filter.resource_groups, null)
    os_types        = try(each.value.filter.os_types, null)
    locations       = try(each.value.filter.locations, local.default_locations)
  }

  lifecycle {
    ignore_changes = [
      filter,
    ]
  }
}

