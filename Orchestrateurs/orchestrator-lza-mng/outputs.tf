################################################################################
# Outputs - Management Layer Orchestrator
# Phase 1: M01 Log Analytics Workspace
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

output "m01_log_analytics_configuration" {
  description = "Full configuration summary of M01."
  value       = try(module.m01_log_analytics[0].configuration, null)
}

output "m01_solutions_deployed" {
  description = "List of solutions deployed in Log Analytics."
  value       = try(module.m01_log_analytics[0].solutions, null)
}

output "m01_archive_tables" {
  description = "Tables configured with archive retention."
  value       = try(module.m01_log_analytics[0].archive_tables, null)
}

output "m01_dr_workspace_id" {
  description = "Resource ID of the DR workspace (if enabled)."
  value       = try(module.m01_log_analytics[0].secondary_workspace_id, null)
}

#-------------------------------------------------------------------------------
# M02 - Automation Account (Phase 2)
#-------------------------------------------------------------------------------

# output "m02_automation_account_id" {
#   description = "Resource ID of the Automation Account."
#   value       = try(module.m02_automation_account[0].id, null)
# }

#-------------------------------------------------------------------------------
# Deployment Status
#-------------------------------------------------------------------------------

output "deployment_status" {
  description = "Status of each module deployment."
  value = {
    m01_log_analytics      = var.deploy_m01_log_analytics ? "Deployed" : "Skipped"
    m02_automation         = var.deploy_m02_automation ? "Deployed" : "Skipped"
    m03_action_groups      = var.deploy_m03_action_groups ? "Deployed" : "Skipped"
    m04_alerts             = var.deploy_m04_alerts ? "Deployed" : "Skipped"
    m05_diagnostic_settings = var.deploy_m05_diagnostic_settings ? "Deployed" : "Skipped"
    m06_update_management  = var.deploy_m06_update_management ? "Deployed" : "Skipped"
    m07_dcr                = var.deploy_m07_dcr ? "Deployed" : "Skipped"
    m08_diagnostics_storage = var.deploy_m08_diagnostics_storage ? "Deployed" : "Skipped"
  }
}

output "deployment_plan" {
  description = "Planned deployment phases."
  value       = local.deployment_plan
}

#-------------------------------------------------------------------------------
# Cross-Module Dependencies (for downstream consumers)
#-------------------------------------------------------------------------------

output "log_analytics_for_downstream" {
  description = "Log Analytics outputs for downstream modules (Connectivity, Security, etc.)."
  value = var.deploy_m01_log_analytics ? {
    workspace_id          = module.m01_log_analytics[0].id
    workspace_guid        = module.m01_log_analytics[0].workspace_id
    workspace_name        = module.m01_log_analytics[0].name
    resource_group_name   = local.rg_name
    location              = local.rg_location
    sentinel_solution_id  = module.m01_log_analytics[0].sentinel_solution_id
  } : null
}

#-------------------------------------------------------------------------------
# Summary
#-------------------------------------------------------------------------------

output "summary" {
  description = "Summary of the Management layer deployment."
  value = {
    project          = var.project_name
    environment      = var.environment
    primary_region   = var.primary_location
    secondary_region = var.secondary_location
    resource_group   = local.rg_name
    modules_deployed = sum([
      var.deploy_m01_log_analytics ? 1 : 0,
      var.deploy_m02_automation ? 1 : 0,
      var.deploy_m03_action_groups ? 1 : 0,
      var.deploy_m04_alerts ? 1 : 0,
      var.deploy_m05_diagnostic_settings ? 1 : 0,
      var.deploy_m06_update_management ? 1 : 0,
      var.deploy_m07_dcr ? 1 : 0,
      var.deploy_m08_diagnostics_storage ? 1 : 0,
    ])
  }
}