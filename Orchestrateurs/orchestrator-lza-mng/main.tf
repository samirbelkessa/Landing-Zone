################################################################################
# main.tf - Management Layer Orchestrator
# Module Orchestration with F02 and F03 Integration
################################################################################

#-------------------------------------------------------------------------------
# F03 Tags for Resource Group
#-------------------------------------------------------------------------------

module "tags_rg" {
  source = "./modules/F03-tags"

  environment         = local.f03_environment
  owner               = var.owner
  cost_center         = var.cost_center
  application         = var.application
  criticality         = var.criticality
  data_classification = var.data_classification
  project             = var.project
  department          = var.department
  module_name         = "orchestrator-management"
}

#-------------------------------------------------------------------------------
# Resource Group (Optional Creation)
#-------------------------------------------------------------------------------

resource "azurerm_resource_group" "management" {
  count = var.create_resource_group ? 1 : 0

  name     = var.resource_group_name
  location = var.primary_location

  tags = module.tags_rg.all_tags
}

################################################################################
# M01 - Log Analytics Workspace
# Appelle F02 et F03 EN INTERNE
################################################################################

module "m01_log_analytics" {
  source = "./modules/M01-log-analytics-workspace"
  count  = var.deploy_m01_log_analytics ? 1 : 0

  #-----------------------------------------------------------------------------
  # F02 Naming inputs (passés au module qui appelle F02 en interne)
  #-----------------------------------------------------------------------------
  workload    = var.project_name
  environment = var.environment
  region      = local.primary_region
  instance    = "001"

  # Custom name override (optional - bypasses F02)
  custom_name = var.log_analytics_custom_name

  #-----------------------------------------------------------------------------
  # Resource placement
  #-----------------------------------------------------------------------------
  resource_group_name = local.rg_name
  location            = local.rg_location

  #-----------------------------------------------------------------------------
  # F03 Tagging inputs (passés au module qui appelle F03 en interne)
  #-----------------------------------------------------------------------------
  owner               = var.owner
  cost_center         = var.cost_center
  application         = var.application
  criticality         = var.criticality
  data_classification = var.data_classification
  project             = var.project
  department          = var.department

  #-----------------------------------------------------------------------------
  # M01 specific configuration
  #-----------------------------------------------------------------------------
  retention_in_days       = var.log_analytics_retention_days
  total_retention_in_days = var.log_analytics_total_retention_days
  sku                     = var.log_analytics_sku

  # Archive configuration per table
  enable_table_level_archive = true
  archive_tables = {
    "SecurityEvent" = 400
    "SigninLogs"    = 400
    "AuditLogs"     = 400
    "AzureActivity" = 400
    "Syslog"        = 400
    "Perf"          = 180
    "AzureMetrics"  = 180
  }

  # Solutions
  deploy_solutions = true
  solutions = [
    { name = "SecurityInsights", publisher = "Microsoft" },
    { name = "AzureActivity", publisher = "Microsoft" },
    { name = "ChangeTracking", publisher = "Microsoft" },
    { name = "Updates", publisher = "Microsoft" },
    { name = "VMInsights", publisher = "Microsoft" },
    { name = "ServiceMap", publisher = "Microsoft" },
    { name = "AgentHealthAssessment", publisher = "Microsoft" },
  ]

  # DR Configuration
  enable_cross_region_workspace = var.enable_log_analytics_dr
  secondary_location            = var.secondary_location
  secondary_retention_in_days   = 30

  # Diagnostic Settings
  enable_diagnostic_settings = true

  depends_on = [azurerm_resource_group.management]
}

################################################################################
# M02 - Automation Account
# Appelle F02 et F03 EN INTERNE
################################################################################

module "m02_automation_account" {
  source = "./modules/M02-automation-account"
  count  = local.m02_can_deploy ? 1 : 0

  #-----------------------------------------------------------------------------
  # F02 Naming inputs (passés au module qui appelle F02 en interne)
  #-----------------------------------------------------------------------------
  workload    = var.project_name
  environment = var.environment
  region      = local.primary_region
  instance    = "001"

  # Custom name override (optional - bypasses F02)
  custom_name = var.automation_custom_name

  #-----------------------------------------------------------------------------
  # Resource placement
  #-----------------------------------------------------------------------------
  resource_group_name = local.rg_name
  location            = local.rg_location

  #-----------------------------------------------------------------------------
  # F03 Tagging inputs (passés au module qui appelle F03 en interne)
  #-----------------------------------------------------------------------------
  owner               = var.owner
  cost_center         = var.cost_center
  application         = var.application
  criticality         = var.criticality
  data_classification = var.data_classification
  project             = var.project
  department          = var.department

  #-----------------------------------------------------------------------------
  # M02 specific configuration
  #-----------------------------------------------------------------------------

  # Link to M01 Log Analytics
  log_analytics_workspace_id = module.m01_log_analytics[0].id
  create_la_linked_service   = true

  # Security settings
  public_network_access_enabled = var.automation_public_access
  local_authentication_enabled  = true
  identity_type                 = "SystemAssigned"

  # Runbooks
  runbooks = local.default_runbooks

  # Schedules
  schedules = local.default_schedules

  # Diagnostic settings
  enable_diagnostic_settings = true

  depends_on = [module.m01_log_analytics]
}

################################################################################
# Placeholder modules for future phases (M03-M08)
################################################################################

# M03 - Action Groups
# M04 - Alerts
# M05 - Diagnostic Settings (generic module)
# M06 - Update Management
# M07 - Data Collection Rules
# M08 - Diagnostics Storage Account
