################################################################################
# Management Layer Orchestrator - Main
# Phase 1: M01 Log Analytics Workspace
################################################################################

#-------------------------------------------------------------------------------
# Resource Group (Optional Creation)
#-------------------------------------------------------------------------------

resource "azurerm_resource_group" "management" {
  count = var.create_resource_group ? 1 : 0

  name     = local.resource_group_name
  location = var.primary_location

  tags = merge(local.common_tags, {
    Purpose = "Management Layer Resources"
  })
}

# Data source for existing resource group
data "azurerm_resource_group" "management" {
  count = var.create_resource_group ? 0 : 1

  name = local.resource_group_name
}

locals {
  # Unified resource group reference
  rg_name     = var.create_resource_group ? azurerm_resource_group.management[0].name : data.azurerm_resource_group.management[0].name
  rg_location = var.create_resource_group ? azurerm_resource_group.management[0].location : data.azurerm_resource_group.management[0].location
}

################################################################################
# M01 - Log Analytics Workspace
################################################################################

module "m01_log_analytics" {
  source = "./modules/M01-log-analytics-workspace"
  count  = var.deploy_m01_log_analytics ? 1 : 0

  # Core Configuration
  name                = local.log_analytics_name
  resource_group_name = local.rg_name
  location            = local.rg_location

  # Retention Configuration
  retention_in_days       = var.log_analytics_retention_days
  total_retention_in_days = var.log_analytics_total_retention_days

  # Archive Configuration
  enable_table_level_archive = true
  archive_tables             = var.log_analytics_archive_tables

  # SKU and Quota
  sku            = var.log_analytics_sku
  daily_quota_gb = var.log_analytics_daily_quota_gb

  # Solutions
  deploy_solutions = true
  solutions        = var.log_analytics_solutions

  # Network Access
  internet_ingestion_enabled = true
  internet_query_enabled     = true

  # Diagnostic Settings (self-logging)
  enable_diagnostic_settings = true

  # DR Configuration
  enable_cross_region_workspace = var.enable_log_analytics_dr
  secondary_location            = var.secondary_location
  secondary_retention_in_days   = 30

  # Tags
  tags = merge(local.common_tags, {
    Module = "M01-LogAnalytics"
  })

  depends_on = [
    azurerm_resource_group.management
  ]
}

################################################################################
# M02 - Automation Account (Phase 2 - À activer après test M01)
################################################################################

# module "m02_automation_account" {
#   source = "../../modules/automation-account"
#   count  = var.deploy_m02_automation ? 1 : 0
#
#   name                = local.automation_account_name
#   resource_group_name = local.rg_name
#   location            = local.rg_location
#
#   # Link to Log Analytics
#   log_analytics_workspace_id = module.m01_log_analytics[0].id
#
#   tags = merge(local.common_tags, {
#     Module = "M02-Automation"
#   })
#
#   depends_on = [module.m01_log_analytics]
# }

################################################################################
# M03 - Action Groups (Phase 3 - À activer après test M02)
################################################################################

# module "m03_action_groups" {
#   source = "../../modules/monitor-action-groups"
#   count  = var.deploy_m03_action_groups ? 1 : 0
#   ...
# }

################################################################################
# M04 - Alerts (Phase 4 - À activer après test M03)
################################################################################

# module "m04_alerts" {
#   source = "../../modules/monitor-alerts"
#   count  = var.deploy_m04_alerts ? 1 : 0
#   ...
# }

################################################################################
# M07 - Data Collection Rules (Phase 5 - À activer après test M01)
################################################################################

# module "m07_dcr" {
#   source = "../../modules/data-collection-rules"
#   count  = var.deploy_m07_dcr ? 1 : 0
#   ...
# }

################################################################################
# M08 - Diagnostics Storage Account (Phase 6 - À activer après test M01)
################################################################################

# module "m08_diagnostics_storage" {
#   source = "../../modules/diagnostics-storage-account"
#   count  = var.deploy_m08_diagnostics_storage ? 1 : 0
#   ...
# }