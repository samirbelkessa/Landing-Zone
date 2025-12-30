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
    m01_log_analytics       = var.deploy_m01_log_analytics ? "deployed" : "skipped"
    m02_automation_account  = local.m02_can_deploy ? "deployed" : (var.deploy_m02_automation ? "blocked_missing_m01" : "skipped")
    m03_action_groups       = local.m03_can_deploy ? "deployed" : "skipped"  # ← MODIFIÉ
    m04_alerts = local.m04_can_deploy ? "deployed" : (var.deploy_m04_alerts ? "blocked_missing_deps" : "skipped")
    m06_update_management   = local.m06_can_deploy ? "deployed" : (var.deploy_m06_update_management ? "blocked_missing_deps" : "skipped")
    m07_dcr                 = local.m07_can_deploy ? "deployed" : (var.deploy_m07_dcr ? "blocked_missing_m01" : "skipped")
    m08_diagnostics_storage = var.deploy_m08_diagnostics_storage ? "deployed" : "skipped"
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
