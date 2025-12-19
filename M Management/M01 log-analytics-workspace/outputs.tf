################################################################################
# Outputs - Log Analytics Workspace (M01)
################################################################################

#-------------------------------------------------------------------------------
# Primary Workspace - Core Identifiers
#-------------------------------------------------------------------------------

output "id" {
  description = "Resource ID of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.id
}

output "workspace_id" {
  description = "Workspace ID (GUID) - used for agent configuration and API calls."
  value       = azurerm_log_analytics_workspace.this.workspace_id
}

output "name" {
  description = "Name of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.name
}

output "resource_group_name" {
  description = "Resource group containing the workspace."
  value       = azurerm_log_analytics_workspace.this.resource_group_name
}

output "location" {
  description = "Azure region of the workspace."
  value       = azurerm_log_analytics_workspace.this.location
}

#-------------------------------------------------------------------------------
# Primary Workspace - Keys (for Legacy Agent Configuration)
#-------------------------------------------------------------------------------

output "primary_shared_key" {
  description = "Primary shared key for agent authentication. Use managed identity when possible."
  value       = azurerm_log_analytics_workspace.this.primary_shared_key
  sensitive   = true
}

output "secondary_shared_key" {
  description = "Secondary shared key for agent authentication."
  value       = azurerm_log_analytics_workspace.this.secondary_shared_key
  sensitive   = true
}

#-------------------------------------------------------------------------------
# Primary Workspace - Configuration
#-------------------------------------------------------------------------------

output "sku" {
  description = "SKU of the workspace."
  value       = azurerm_log_analytics_workspace.this.sku
}

output "retention_in_days" {
  description = "Interactive retention period in days."
  value       = azurerm_log_analytics_workspace.this.retention_in_days
}

output "total_retention_in_days" {
  description = "Total retention period including archive."
  value       = var.total_retention_in_days
}

output "archive_retention_in_days" {
  description = "Archive retention period (total - interactive)."
  value       = local.archive_retention_days
}

output "daily_quota_gb" {
  description = "Daily ingestion quota in GB (-1 = unlimited)."
  value       = azurerm_log_analytics_workspace.this.daily_quota_gb
}

#-------------------------------------------------------------------------------
# Primary Workspace - Network Configuration
#-------------------------------------------------------------------------------

output "internet_ingestion_enabled" {
  description = "Whether public internet ingestion is enabled."
  value       = azurerm_log_analytics_workspace.this.internet_ingestion_enabled
}

output "internet_query_enabled" {
  description = "Whether public internet queries are enabled."
  value       = azurerm_log_analytics_workspace.this.internet_query_enabled
}

#-------------------------------------------------------------------------------
# Solutions Deployed
#-------------------------------------------------------------------------------

output "solutions" {
  description = "Map of deployed solutions."
  value = {
    for k, v in azurerm_log_analytics_solution.solutions : k => {
      name      = v.solution_name
      id        = v.id
      plan      = v.plan[0].product
    }
  }
}

output "solution_ids" {
  description = "List of solution resource IDs."
  value       = [for s in azurerm_log_analytics_solution.solutions : s.id]
}

output "sentinel_solution_id" {
  description = "Resource ID of the SecurityInsights (Sentinel) solution, if deployed."
  value       = try(azurerm_log_analytics_solution.solutions["SecurityInsights-Microsoft"].id, null)
}

#-------------------------------------------------------------------------------
# Linked Services
#-------------------------------------------------------------------------------

output "automation_account_linked" {
  description = "Whether an Automation Account is linked."
  value       = var.link_automation_account && var.automation_account_id != null
}

output "automation_linked_service_id" {
  description = "Resource ID of the Automation Account linked service."
  value       = try(azurerm_log_analytics_linked_service.automation[0].id, null)
}

#-------------------------------------------------------------------------------
# Archive Table Configuration
#-------------------------------------------------------------------------------

output "archive_tables" {
  description = "Map of tables configured with archive retention."
  value = {
    for k, v in azurerm_log_analytics_workspace_table.archive : k => {
      name                    = v.name
      retention_in_days       = v.retention_in_days
      total_retention_in_days = v.total_retention_in_days
    }
  }
}

output "archive_enabled" {
  description = "Whether archive is enabled for any tables."
  value       = local.archive_enabled
}

#-------------------------------------------------------------------------------
# Secondary Workspace (DR)
#-------------------------------------------------------------------------------

output "secondary_workspace_id" {
  description = "Resource ID of the secondary (DR) workspace."
  value       = try(azurerm_log_analytics_workspace.secondary[0].id, null)
}

output "secondary_workspace_guid" {
  description = "Workspace ID (GUID) of the secondary workspace."
  value       = try(azurerm_log_analytics_workspace.secondary[0].workspace_id, null)
}

output "secondary_workspace_name" {
  description = "Name of the secondary workspace."
  value       = try(azurerm_log_analytics_workspace.secondary[0].name, null)
}

output "secondary_location" {
  description = "Location of the secondary workspace."
  value       = try(azurerm_log_analytics_workspace.secondary[0].location, null)
}

output "dr_enabled" {
  description = "Whether DR workspace is enabled."
  value       = var.enable_cross_region_workspace
}

#-------------------------------------------------------------------------------
# Query Pack
#-------------------------------------------------------------------------------

output "query_pack_id" {
  description = "Resource ID of the Log Analytics Query Pack."
  value       = azurerm_log_analytics_query_pack.caf_queries.id
}

output "query_pack_name" {
  description = "Name of the Query Pack."
  value       = azurerm_log_analytics_query_pack.caf_queries.name
}

#-------------------------------------------------------------------------------
# Diagnostic Settings
#-------------------------------------------------------------------------------

output "diagnostic_settings_id" {
  description = "Resource ID of the diagnostic settings for the workspace."
  value       = try(azurerm_monitor_diagnostic_setting.this[0].id, null)
}

#-------------------------------------------------------------------------------
# Configuration Summary (for orchestrator)
#-------------------------------------------------------------------------------

output "configuration" {
  description = "Summary of workspace configuration for downstream modules."
  value = {
    id                      = azurerm_log_analytics_workspace.this.id
    workspace_id            = azurerm_log_analytics_workspace.this.workspace_id
    name                    = azurerm_log_analytics_workspace.this.name
    resource_group_name     = azurerm_log_analytics_workspace.this.resource_group_name
    location                = azurerm_log_analytics_workspace.this.location
    sku                     = azurerm_log_analytics_workspace.this.sku
    retention_interactive   = var.retention_in_days
    retention_total         = var.total_retention_in_days
    retention_archive       = local.archive_retention_days
    internet_ingestion      = var.internet_ingestion_enabled
    internet_query          = var.internet_query_enabled
    solutions_deployed      = keys(local.solutions_to_deploy)
    dr_enabled              = var.enable_cross_region_workspace
    dr_workspace_id         = try(azurerm_log_analytics_workspace.secondary[0].id, null)
  }
}

#-------------------------------------------------------------------------------
# For Orchestrator Module Dependencies
#-------------------------------------------------------------------------------

output "ready" {
  description = "Indicates the workspace is ready for dependent modules (M02-M08)."
  value       = true

  depends_on = [
    azurerm_log_analytics_workspace.this,
    azurerm_log_analytics_solution.solutions,
    azurerm_log_analytics_workspace_table.archive
  ]
}

output "outputs_for_m02" {
  description = "Outputs specifically needed by M02 (Automation Account)."
  value = {
    workspace_id            = azurerm_log_analytics_workspace.this.id
    workspace_name          = azurerm_log_analytics_workspace.this.name
    resource_group_name     = azurerm_log_analytics_workspace.this.resource_group_name
    location                = azurerm_log_analytics_workspace.this.location
  }
}

output "outputs_for_m05" {
  description = "Outputs specifically needed by M05 (Diagnostic Settings)."
  value = {
    workspace_id = azurerm_log_analytics_workspace.this.id
  }
}

output "outputs_for_m07" {
  description = "Outputs specifically needed by M07 (Data Collection Rules)."
  value = {
    workspace_id            = azurerm_log_analytics_workspace.this.id
    workspace_resource_id   = azurerm_log_analytics_workspace.this.workspace_id
    location                = azurerm_log_analytics_workspace.this.location
  }
}

output "outputs_for_s01" {
  description = "Outputs specifically needed by S01 (Defender for Cloud)."
  value = {
    workspace_id = azurerm_log_analytics_workspace.this.id
  }
}

output "outputs_for_s02" {
  description = "Outputs specifically needed by S02 (Sentinel)."
  value = {
    workspace_id             = azurerm_log_analytics_workspace.this.id
    workspace_name           = azurerm_log_analytics_workspace.this.name
    resource_group_name      = azurerm_log_analytics_workspace.this.resource_group_name
    sentinel_solution_id     = try(azurerm_log_analytics_solution.solutions["SecurityInsights-Microsoft"].id, null)
  }
}