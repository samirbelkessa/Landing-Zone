# ==============================================================================
# M06 - Update Management (Azure Update Manager) - Outputs
# ==============================================================================

#-------------------------------------------------------------------------------
# F02 Naming Outputs
#-------------------------------------------------------------------------------

output "generated_name" {
  description = "Generated name from F02 pattern (or custom prefix)."
  value       = local.name_prefix
}

output "naming_details" {
  description = "Full naming details."
  value = {
    resource_type = "mc"
    workload      = var.workload
    environment   = var.environment
    region        = var.region
    instance      = var.instance
    name_prefix   = local.name_prefix
    custom_name_used = var.custom_name_prefix != null
  }
}

#-------------------------------------------------------------------------------
# F03 Tags Outputs
#-------------------------------------------------------------------------------

output "tags" {
  description = "All tags (F03 + additional)."
  value       = local.merged_tags
}

output "tags_details" {
  description = "Detailed tags information from F03 module."
  value = {
    environment          = module.tags.environment
    owner                = module.tags.owner
    cost_center          = module.tags.cost_center
    application          = module.tags.application
    criticality          = module.tags.criticality
    data_classification  = module.tags.data_classification
    is_production        = module.tags.is_production
    is_critical          = module.tags.is_critical
  }
}

#-------------------------------------------------------------------------------
# Maintenance Configuration Outputs
#-------------------------------------------------------------------------------

output "maintenance_configuration_ids" {
  description = "Map of maintenance configuration keys to their resource IDs."
  value = {
    for k, v in azurerm_maintenance_configuration.this :
    k => v.id
  }
}

output "maintenance_configuration_names" {
  description = "Map of maintenance configuration keys to their generated names."
  value       = local.configuration_names
}

output "maintenance_configuration_full_names" {
  description = "List of all maintenance configuration full names (as created in Azure)."
  value       = [for k, v in azurerm_maintenance_configuration.this : v.name]
}

output "windows_configurations" {
  description = "List of maintenance configuration keys for Windows."
  value = [
    for k, v in azurerm_maintenance_configuration.this :
    k if try(v.install_patches[0].windows, null) != null
  ]
}

output "linux_configurations" {
  description = "List of maintenance configuration keys for Linux."
  value = [
    for k, v in azurerm_maintenance_configuration.this :
    k if try(v.install_patches[0].linux, null) != null
  ]
}

#-------------------------------------------------------------------------------
# Assignment Outputs
#-------------------------------------------------------------------------------

output "vm_assignment_ids" {
  description = "Map of VM assignment keys to their resource IDs."
  value = {
    for k, v in azurerm_maintenance_assignment_virtual_machine.this :
    k => v.id
  }
}

output "dynamic_scope_assignment_ids" {
  description = "Map of dynamic scope assignment keys to their resource IDs."
  value = {
    for k, v in azurerm_maintenance_assignment_dynamic_scope.this :
    k => v.id
  }
}

output "dynamic_scope_assignment_names" {
  description = "Map of dynamic scope assignment keys to their generated names."
  value = {
    for k, v in azurerm_maintenance_assignment_dynamic_scope.this :
    k => v.name
  }
}

#-------------------------------------------------------------------------------
# Configuration Summary (for orchestrator)
#-------------------------------------------------------------------------------

output "configuration" {
  description = "Summary of Update Management configuration for orchestrator."
  value = {
    # Resource details
    resource_group_name = var.resource_group_name
    location            = var.location

    # Naming
    name_prefix          = local.name_prefix
    custom_name_used     = var.custom_name_prefix != null
    f02_naming_used      = var.custom_name_prefix == null

    # Counts
    total_maintenance_configurations = length(azurerm_maintenance_configuration.this)
    windows_configurations_count     = length([for k, v in azurerm_maintenance_configuration.this : k if try(v.install_patches[0].windows, null) != null])
    linux_configurations_count       = length([for k, v in azurerm_maintenance_configuration.this : k if try(v.install_patches[0].linux, null) != null])
    vm_assignments_count             = length(azurerm_maintenance_assignment_virtual_machine.this)
    dynamic_scope_assignments_count  = length(azurerm_maintenance_assignment_dynamic_scope.this)

    # Default configs
    default_windows_created = var.create_default_windows_config
    default_linux_created   = var.create_default_linux_config
    default_timezone        = var.default_timezone

    # Integration status
    log_analytics_integrated = local.log_analytics_integration_enabled
    alerts_integrated        = local.alerts_integration_enabled

    # Tags
    tags         = local.merged_tags
    is_production = module.tags.is_production
    is_critical   = module.tags.is_critical
  }
}

#-------------------------------------------------------------------------------
# Module Integration Outputs (for M04 Alerts)
#-------------------------------------------------------------------------------

output "outputs_for_m04" {
  description = "Outputs specifically needed by M04 (Alerts) module for Update Manager monitoring."
  value = {
    maintenance_configuration_ids = {
      for k, v in azurerm_maintenance_configuration.this :
      k => v.id
    }
    resource_group_name = var.resource_group_name
    location            = var.location
    
    # Suggested alert scopes
    alert_scopes = [
      for k, v in azurerm_maintenance_configuration.this :
      v.id
    ]

    # Integration enabled flag
    integration_ready = true
  }
}

#-------------------------------------------------------------------------------
# Ready flag for orchestrator dependencies
#-------------------------------------------------------------------------------

output "ready" {
  description = "Indicates Update Management is fully deployed and ready."
  value       = true

  depends_on = [
    azurerm_maintenance_configuration.this,
    azurerm_maintenance_assignment_virtual_machine.this,
    azurerm_maintenance_assignment_dynamic_scope.this
  ]
}