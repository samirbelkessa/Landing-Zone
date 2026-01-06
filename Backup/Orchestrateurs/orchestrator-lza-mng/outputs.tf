################################################################################
# outputs.tf - Management Layer Orchestrator
################################################################################

#-------------------------------------------------------------------------------
# Resource Group
#-------------------------------------------------------------------------------

output "resource_group_name" {
  description = "Name of the Management resource group."
  value       = local.rg_name
}

output "resource_group_location" {
  description = "Location of the Management resource group."
  value       = local.rg_location
}

#-------------------------------------------------------------------------------
# M01 - Log Analytics Workspace
#-------------------------------------------------------------------------------

output "m01_log_analytics_id" {
  description = "Resource ID of the Log Analytics workspace."
  value       = try(module.m01_log_analytics[0].id, null)
}

output "m01_log_analytics_workspace_id" {
  description = "Workspace ID (GUID) of the Log Analytics workspace."
  value       = try(module.m01_log_analytics[0].workspace_id, null)
}

output "m01_log_analytics_name" {
  description = "Name of the Log Analytics workspace."
  value       = try(module.m01_log_analytics[0].name, null)
}

output "m01_log_analytics_primary_key" {
  description = "Primary shared key for the Log Analytics workspace."
  value       = try(module.m01_log_analytics[0].primary_shared_key, null)
  sensitive   = true
}

output "m01_configuration" {
  description = "Full configuration summary of M01."
  value       = try(module.m01_log_analytics[0].configuration, null)
}

output "m01_naming_details" {
  description = "F02 naming details for M01."
  value       = try(module.m01_log_analytics[0].naming_details, null)
}

output "m01_tags" {
  description = "F03 tags applied to M01."
  value       = try(module.m01_log_analytics[0].tags, null)
}

output "m01_tags_details" {
  description = "F03 tags details for M01."
  value       = try(module.m01_log_analytics[0].tags_details, null)
}

#-------------------------------------------------------------------------------
# M02 - Automation Account
#-------------------------------------------------------------------------------

output "m02_automation_account_id" {
  description = "Resource ID of the Automation Account."
  value       = try(module.m02_automation_account[0].id, null)
}

output "m02_automation_account_name" {
  description = "Name of the Automation Account."
  value       = try(module.m02_automation_account[0].name, null)
}

output "m02_automation_principal_id" {
  description = "Principal ID of the Automation Account managed identity."
  value       = try(module.m02_automation_account[0].principal_id, null)
}

output "m02_automation_dsc_endpoint" {
  description = "DSC Server endpoint URL."
  value       = try(module.m02_automation_account[0].dsc_server_endpoint, null)
}

output "m02_configuration" {
  description = "Full configuration summary of M02."
  value       = try(module.m02_automation_account[0].configuration, null)
}

output "m02_naming_details" {
  description = "F02 naming details for M02."
  value       = try(module.m02_automation_account[0].naming_details, null)
}

output "m02_tags" {
  description = "F03 tags applied to M02."
  value       = try(module.m02_automation_account[0].tags, null)
}

output "m02_tags_details" {
  description = "F03 tags details for M02."
  value       = try(module.m02_automation_account[0].tags_details, null)
}

output "m02_runbooks" {
  description = "Map of deployed runbooks."
  value       = try(module.m02_automation_account[0].runbooks, null)
}

output "m02_schedules" {
  description = "Map of deployed schedules."
  value       = try(module.m02_automation_account[0].schedules, null)
}

output "m02_linked_service_id" {
  description = "ID of the Log Analytics linked service."
  value       = try(module.m02_automation_account[0].linked_service_id, null)
}

#-------------------------------------------------------------------------------
# Deployment Status
#-------------------------------------------------------------------------------

output "deployment_status" {
  description = "Status of each module deployment."
  value = {
    m01_log_analytics        = var.deploy_m01_log_analytics ? "deployed" : "skipped"
    m02_automation_account   = local.m02_can_deploy ? "deployed" : (var.deploy_m02_automation ? "blocked_missing_m01" : "skipped")
    m03_action_groups        = local.m03_can_deploy ? "deployed" : "skipped"
    m04_alerts               = local.m04_can_deploy ? "deployed" : (var.deploy_m04_alerts ? "blocked_missing_deps" : "skipped")
    m05_diagnostic_settings  = var.enable_diagnostic_settings && var.diagnostic_settings_config != null ? "deployed" : "skipped"  # ← AJOUTE
    m06_update_management    = local.m06_can_deploy ? "deployed" : (var.deploy_m06_update_management ? "blocked_missing_deps" : "skipped")
    m07_dcr                  = local.m07_can_deploy ? "deployed" : (var.deploy_m07_dcr ? "blocked_missing_m01" : "skipped")
    m08_diagnostics_storage  = var.deploy_m08_diagnostics_storage ? "deployed" : "skipped"
  }
}


#-------------------------------------------------------------------------------
# Cross-Module References (for downstream use)
#-------------------------------------------------------------------------------

output "management_layer_config" {
  description = "Complete configuration for downstream consumption."
  value = {
    resource_group_name        = local.rg_name
    location                   = local.rg_location
    # M01 Log Analytics
    log_analytics_id           = try(module.m01_log_analytics[0].id, null)
    log_analytics_workspace_id = try(module.m01_log_analytics[0].workspace_id, null)
    # M02 Automation Account
    automation_account_id      = try(module.m02_automation_account[0].id, null)
    automation_principal_id    = try(module.m02_automation_account[0].principal_id, null)
    environment                = var.environment
    # M03 Action Groups
    action_group_ids           = try(module.m03_action_groups[0].action_group_ids, {})
    critical_action_group_id   = try(module.m03_action_groups[0].critical_action_group_id, null)
    warning_action_group_id    = try(module.m03_action_groups[0].warning_action_group_id, null)
    info_action_group_id       = try(module.m03_action_groups[0].info_action_group_id, null)
    is_production              = contains(["prod", "nonprod"], var.environment)
    # M04 - AJOUTER CETTE SECTION
    alerts = {
      service_health_alert_id  = try(module.m04_monitor_alerts[0].service_health_alert_id, null)
      resource_health_alert_id = try(module.m04_monitor_alerts[0].resource_health_alert_id, null)
      admin_delete_alert_id    = try(module.m04_monitor_alerts[0].admin_delete_alert_id, null)
      security_alert_id        = try(module.m04_monitor_alerts[0].security_alert_id, null)
      all_alert_ids            = try(module.m04_monitor_alerts[0].all_alert_ids, {})
      alert_count              = try(module.m04_monitor_alerts[0].alert_count, 0)
    }
  }
}

################################################################################
# M03 - Action Groups Outputs
# À ajouter dans orchestrator-lza-mng/outputs.tf
################################################################################

#-------------------------------------------------------------------------------
# Naming Outputs (F02)
#-------------------------------------------------------------------------------

output "m03_generated_name" {
  description = "Name generated by F02 for M03 Action Groups."
  value       = try(module.m03_action_groups[0].generated_name, null)
}

output "m03_naming_details" {
  description = "Full F02 naming details for M03."
  value       = try(module.m03_action_groups[0].naming_details, null)
}

#-------------------------------------------------------------------------------
# Tags Outputs (F03)
#-------------------------------------------------------------------------------

output "m03_tags" {
  description = "All F03 tags applied to M03 resources."
  value       = try(module.m03_action_groups[0].tags, null)
}

output "m03_tags_details" {
  description = "F03 tag details for M03."
  value       = try(module.m03_action_groups[0].tags_details, null)
}

#-------------------------------------------------------------------------------
# Primary Outputs
#-------------------------------------------------------------------------------

output "m03_action_group_ids" {
  description = "Map of Action Group IDs by key."
  value       = try(module.m03_action_groups[0].action_group_ids, {})
}

output "m03_action_group_names" {
  description = "Map of Action Group names by key."
  value       = try(module.m03_action_groups[0].action_group_names, {})
}

output "m03_critical_action_group_id" {
  description = "Resource ID of the Critical Action Group."
  value       = try(module.m03_action_groups[0].critical_action_group_id, null)
}

output "m03_warning_action_group_id" {
  description = "Resource ID of the Warning Action Group."
  value       = try(module.m03_action_groups[0].warning_action_group_id, null)
}

output "m03_info_action_group_id" {
  description = "Resource ID of the Info Action Group."
  value       = try(module.m03_action_groups[0].info_action_group_id, null)
}

output "m03_configuration" {
  description = "Complete M03 configuration summary."
  value       = try(module.m03_action_groups[0].configuration, null)
}

#-------------------------------------------------------------------------------
# Outputs for M04 (Alerts)
#-------------------------------------------------------------------------------

output "m03_outputs_for_m04" {
  description = "Pre-formatted outputs for M04 monitor-alerts module."
  value       = try(module.m03_action_groups[0].outputs_for_m04, null)
}

################################################################################
# M04 - Monitor Alerts Outputs
# À ajouter dans orchestrator-lza-mng/outputs.tf après les outputs M03
################################################################################

#-------------------------------------------------------------------------------
# M04 - Monitor Alerts
#-------------------------------------------------------------------------------

output "m04_generated_name_prefix" {
  description = "Name prefix generated by F02 for M04 alerts."
  value       = try(module.m04_monitor_alerts[0].generated_name_prefix, null)
}

output "m04_tags" {
  description = "Tags applied to M04 alerts (from F03)."
  value       = try(module.m04_monitor_alerts[0].tags, null)
}

output "m04_service_health_alert_id" {
  description = "Resource ID of the Service Health alert."
  value       = try(module.m04_monitor_alerts[0].service_health_alert_id, null)
}

output "m04_service_health_alert_name" {
  description = "Name of the Service Health alert."
  value       = try(module.m04_monitor_alerts[0].service_health_alert_name, null)
}

output "m04_resource_health_alert_id" {
  description = "Resource ID of the Resource Health alert."
  value       = try(module.m04_monitor_alerts[0].resource_health_alert_id, null)
}

output "m04_resource_health_alert_name" {
  description = "Name of the Resource Health alert."
  value       = try(module.m04_monitor_alerts[0].resource_health_alert_name, null)
}

output "m04_admin_delete_alert_id" {
  description = "Resource ID of the Administrative delete alert."
  value       = try(module.m04_monitor_alerts[0].admin_delete_alert_id, null)
}

output "m04_security_alert_id" {
  description = "Resource ID of the Security alert."
  value       = try(module.m04_monitor_alerts[0].security_alert_id, null)
}

output "m04_custom_activity_alert_ids" {
  description = "Map of custom Activity Log alert IDs."
  value       = try(module.m04_monitor_alerts[0].custom_activity_alert_ids, {})
}

output "m04_custom_metric_alert_ids" {
  description = "Map of custom Metric alert IDs."
  value       = try(module.m04_monitor_alerts[0].custom_metric_alert_ids, {})
}

output "m04_custom_log_alert_ids" {
  description = "Map of custom Log Query alert IDs."
  value       = try(module.m04_monitor_alerts[0].custom_log_alert_ids, {})
}

output "m04_default_alerts_summary" {
  description = "Summary of all default alerts created by M04."
  value       = try(module.m04_monitor_alerts[0].default_alerts_summary, null)
}

output "m04_all_alert_ids" {
  description = "All alert IDs created by M04 (flat map)."
  value       = try(module.m04_monitor_alerts[0].all_alert_ids, {})
}

output "m04_alert_count" {
  description = "Total number of alerts created by M04."
  value       = try(module.m04_monitor_alerts[0].alert_count, 0)
}

output "m04_configuration" {
  description = "Complete configuration summary of M04 deployment."
  value       = try(module.m04_monitor_alerts[0].configuration, null)
}

#-------------------------------------------------------------------------------
# M05 - Diagnostic Settings
#-------------------------------------------------------------------------------

output "m05_law_diagnostics_id" {
  description = "Diagnostic setting ID for Log Analytics Workspace"
  value       = try(module.law_diagnostics[0].id, null)
}

output "m05_automation_diagnostics_id" {
  description = "Diagnostic setting ID for Automation Account"
  value       = try(module.automation_diagnostics[0].id, null)
}

output "m05_diagnostic_settings_names" {
  description = "Names of diagnostic settings created"
  value = {
    law        = try(module.law_diagnostics[0].name, null)
    automation = try(module.automation_diagnostics[0].name, null)
  }
}

#===============================================================================
# M06 - UPDATE MANAGEMENT OUTPUTS
#===============================================================================

output "m06_update_management" {
  description = "M06 Update Management module outputs."
  value = var.deploy_m06_update_management ? {
    deployed                      = true
    generated_name                = module.m06_update_management[0].generated_name
    maintenance_configuration_ids = module.m06_update_management[0].maintenance_configuration_ids
    windows_configurations        = module.m06_update_management[0].windows_configurations
    linux_configurations          = module.m06_update_management[0].linux_configurations
    configuration                 = module.m06_update_management[0].configuration
  } : {
    deployed                      = false
    generated_name                = null
    maintenance_configuration_ids = {}
    windows_configurations        = []
    linux_configurations          = []
    configuration                 = null
  }
}

#===============================================================================
# M07 - DATA COLLECTION RULES OUTPUTS
#===============================================================================

output "m07_dcr_ids" {
  description = "Map of DCR names to resource IDs from M07 module."
  value       = var.deploy_m07_dcr ? module.m07_data_collection_rules[0].dcr_ids : {}
}

output "m07_dcr_immutable_ids" {
  description = "Map of DCR names to immutable IDs from M07 module."
  value       = var.deploy_m07_dcr ? module.m07_data_collection_rules[0].dcr_immutable_ids : {}
}

output "m07_outputs_for_g03" {
  description = "M07 outputs for G03 Policy Assignments (VM Insights DCR IDs)."
  value       = var.deploy_m07_dcr ? module.m07_data_collection_rules[0].outputs_for_g03 : {
    vm_insights_windows_dcr_id = null
    vm_insights_linux_dcr_id   = null
    all_dcr_ids                = {}
  }
}

output "m07_configuration" {
  description = "M07 DCR deployment configuration summary."
  value       = var.deploy_m07_dcr ? module.m07_data_collection_rules[0].configuration : null
}

output "m07_dcr_ready" {
  description = "Indicates M07 DCRs are ready for use by dependent modules."
  value       = var.deploy_m07_dcr ? module.m07_data_collection_rules[0].ready : false
}

#===============================================================================
# M08 - DIAGNOSTICS STORAGE ACCOUNT OUTPUTS
#===============================================================================

output "m08_diagnostics_storage_id" {
  description = "ID of the diagnostics storage account."
  value       = var.deploy_m08_diagnostics_storage ? module.m08_diagnostics_storage[0].id : null
}

output "m08_diagnostics_storage_name" {
  description = "Name of the diagnostics storage account."
  value       = var.deploy_m08_diagnostics_storage ? module.m08_diagnostics_storage[0].name : null
}

output "m08_diagnostics_storage_primary_blob_endpoint" {
  description = "Primary blob endpoint of the diagnostics storage account."
  value       = var.deploy_m08_diagnostics_storage ? module.m08_diagnostics_storage[0].primary_blob_endpoint : null
}

output "m08_diagnostics_storage" {
  description = "M08 Diagnostics Storage Account module outputs."
  value = var.deploy_m08_diagnostics_storage ? {
    deployed               = true
    id                     = module.m08_diagnostics_storage[0].id
    name                   = module.m08_diagnostics_storage[0].name
    primary_blob_endpoint  = module.m08_diagnostics_storage[0].primary_blob_endpoint
    primary_access_key     = module.m08_diagnostics_storage[0].primary_access_key
    secondary_access_key   = module.m08_diagnostics_storage[0].secondary_access_key
    container_ids          = module.m08_diagnostics_storage[0].container_ids
    configuration          = module.m08_diagnostics_storage[0].configuration
  } : {
    deployed               = false
    id                     = null
    name                   = null
    primary_blob_endpoint  = null
    primary_access_key     = null
    secondary_access_key   = null
    container_ids          = {}
    configuration          = null
  }
  sensitive = true
}

output "m08_naming_details" {
  description = "M08 naming details from F02."
  value       = var.deploy_m08_diagnostics_storage ? module.m08_diagnostics_storage[0].naming_details : null
}

output "m08_tags" {
  description = "M08 tags from F03."
  value       = var.deploy_m08_diagnostics_storage ? module.m08_diagnostics_storage[0].tags : null
}

#-------------------------------------------------------------------------------
# M08 Self-Diagnostics Outputs
#-------------------------------------------------------------------------------

output "m08_self_diagnostics_id" {
  description = "Diagnostic setting ID for M08 Storage Account."
  value       = try(module.m08_self_diagnostics[0].id, null)
}

output "m08_blob_diagnostics_id" {
  description = "Diagnostic setting ID for M08 Blob Service."
  value       = try(module.m08_blob_diagnostics[0].id, null)
}