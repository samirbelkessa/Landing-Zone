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
  enable_diagnostic_settings = false

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
  enable_diagnostic_settings = false

  depends_on = [module.m01_log_analytics]
}

################################################################################
# M03 - Monitor Action Groups
# À ajouter dans orchestrator-lza-mng/main.tf après le module M02
# Appelle F02 et F03 EN INTERNE
################################################################################

module "m03_action_groups" {
  source = "./modules/M03-monitor-action-groups"
  count  = local.m03_can_deploy ? 1 : 0

  #-----------------------------------------------------------------------------
  # F02 Naming inputs (passés au module qui appelle F02 en interne)
  #-----------------------------------------------------------------------------
  workload    = var.project_name
  environment = var.environment
  region      = local.primary_region
  instance    = "001"

  # Custom name override (optional - bypasses F02)
  custom_name = var.action_groups_custom_name

  #-----------------------------------------------------------------------------
  # Resource placement
  #-----------------------------------------------------------------------------
  resource_group_name = local.rg_name

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
  # M03 specific configuration
  #-----------------------------------------------------------------------------

  # Default action groups (Critical, Warning, Info)
  create_default_action_groups = var.create_default_action_groups
  default_email_receivers      = var.default_email_receivers
  default_webhook_url          = var.default_webhook_url

  # Custom action groups
  action_groups = var.custom_action_groups

  depends_on = [azurerm_resource_group.management]
}

################################################################################
# M04 - Monitor Alerts
# À ajouter dans orchestrator-lza-mng/main.tf après le module M03
# Appelle F02 et F03 EN INTERNE (même pattern que M01/M02/M03)
################################################################################

module "m04_monitor_alerts" {
  source = "./modules/M04-monitor-alerts"
  count  = local.m04_can_deploy ? 1 : 0

  #-----------------------------------------------------------------------------
  # F02 Naming Convention Inputs (passés au module, F02 appelé en interne)
  #-----------------------------------------------------------------------------
  workload           = var.project_name
  environment        = var.environment
  region             = local.location_abbrev[var.primary_location]
  instance           = "001"
  custom_name_prefix = var.alerts_custom_name_prefix

  #-----------------------------------------------------------------------------
  # F03 Tags Inputs (passés au module, F03 appelé en interne)
  #-----------------------------------------------------------------------------
  owner               = var.owner
  cost_center         = var.cost_center
  application         = var.application
  criticality         = var.criticality
  data_classification = var.data_classification
  project             = var.project
  department          = var.department
  additional_tags     = {}

  #-----------------------------------------------------------------------------
  # Azure Resources
  #-----------------------------------------------------------------------------
  resource_group_name = local.rg_name

  # Log Analytics Workspace from M01 (for log query alerts)
  log_analytics_workspace_id = module.m01_log_analytics[0].id

  #-----------------------------------------------------------------------------
  # Action Groups from M03 (automatic severity mapping)
  #-----------------------------------------------------------------------------
  action_group_ids = module.m03_action_groups[0].outputs_for_m04.action_group_ids

  #-----------------------------------------------------------------------------
  # Scope Configuration (dynamic - from current subscription)
  #-----------------------------------------------------------------------------
  # Uses current subscription by default, override with subscription_ids if needed
  subscription_ids = []  # Empty = uses current subscription from provider

  #-----------------------------------------------------------------------------
  # Default Alerts Configuration
  #-----------------------------------------------------------------------------
  create_default_alerts = var.create_default_alerts

  service_health_alert_config    = var.service_health_alert_config
  resource_health_alert_config   = var.resource_health_alert_config
  activity_log_admin_alert_config   = var.activity_log_admin_alert_config
  activity_log_security_alert_config = var.activity_log_security_alert_config

  #-----------------------------------------------------------------------------
  # Custom Alerts
  #-----------------------------------------------------------------------------
  custom_activity_log_alerts = var.custom_activity_log_alerts
  custom_metric_alerts       = var.custom_metric_alerts
  custom_log_query_alerts    = var.custom_log_query_alerts

  #-----------------------------------------------------------------------------
  # Severity Mapping
  #-----------------------------------------------------------------------------
  severity_action_group_mapping = var.severity_action_group_mapping

  #-----------------------------------------------------------------------------
  # Dependencies
  #-----------------------------------------------------------------------------
  depends_on = [
    module.m01_log_analytics,
    module.m03_action_groups
  ]
}
# M05 - Diagnostic Settings (generic module)
# Diagnostic settings for Log Analytics Workspace
# ============================================================================
# DIAGNOSTIC SETTINGS (M05)
# ============================================================================

# Diagnostic settings for Log Analytics Workspace
module "law_diagnostics" {
  count  = var.enable_diagnostic_settings && var.diagnostic_settings_config != null ? 1 : 0
  source = "./modules/M05-diagnostic-settings"

  target_resource_id         = module.m01_log_analytics[0].id
  name                       = "diag-${module.m01_log_analytics[0].name}"
  log_analytics_workspace_id = module.m01_log_analytics[0].id
  storage_account_id         = var.diagnostic_settings_config.storage_account_id

  log_analytics_destination_type = var.diagnostic_settings_config.log_analytics_destination_type
  logs_retention_days            = var.diagnostic_settings_config.logs_retention_days
  metrics_retention_days         = var.diagnostic_settings_config.metrics_retention_days

  # Utilisation des tags exposés par M01
  tags = module.m01_log_analytics[0].tags

  depends_on = [module.m01_log_analytics]
}

# Diagnostic settings for Automation Account
module "automation_diagnostics" {
  count  = var.enable_diagnostic_settings && var.diagnostic_settings_config != null ? 1 : 0
  source = "./modules/M05-diagnostic-settings"

  target_resource_id         = module.m02_automation_account[0].id
  name                       = "diag-${module.m02_automation_account[0].name}"
  log_analytics_workspace_id = module.m01_log_analytics[0].id
  storage_account_id         = var.diagnostic_settings_config.storage_account_id

  log_analytics_destination_type = var.diagnostic_settings_config.log_analytics_destination_type
  logs_retention_days            = var.diagnostic_settings_config.logs_retention_days
  metrics_retention_days         = var.diagnostic_settings_config.metrics_retention_days

  # Utilisation des tags exposés par M02
  tags = module.m02_automation_account[0].tags

  depends_on = [module.m02_automation_account]
}

################################################################################
# Placeholder modules for future phases (M03-M08)
################################################################################


# M06 - Update Management
# M07 - Data Collection Rules
# M08 - Diagnostics Storage Account
