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
    m01_log_analytics      = var.deploy_m01_log_analytics ? "deployed" : "skipped"
    m02_automation_account = local.m02_can_deploy ? "deployed" : (var.deploy_m02_automation ? "blocked_missing_m01" : "skipped")
    m03_action_groups      = local.m03_can_deploy ? "deployed" : (var.deploy_m03_action_groups ? "blocked_missing_deps" : "skipped")
    m04_alerts             = local.m04_can_deploy ? "deployed" : (var.deploy_m04_alerts ? "blocked_missing_deps" : "skipped")
    m06_update_management  = local.m06_can_deploy ? "deployed" : (var.deploy_m06_update_management ? "blocked_missing_deps" : "skipped")
    m07_dcr                = local.m07_can_deploy ? "deployed" : (var.deploy_m07_dcr ? "blocked_missing_m01" : "skipped")
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
    log_analytics_id           = try(module.m01_log_analytics[0].id, null)
    log_analytics_workspace_id = try(module.m01_log_analytics[0].workspace_id, null)
    automation_account_id      = try(module.m02_automation_account[0].id, null)
    automation_principal_id    = try(module.m02_automation_account[0].principal_id, null)
    environment                = var.environment
    is_production              = contains(["prod", "nonprod"], var.environment)
  }
}
