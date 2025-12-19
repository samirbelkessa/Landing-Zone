################################################################################
# Locals - Management Layer Orchestrator
################################################################################

locals {
  #-----------------------------------------------------------------------------
  # Naming Convention
  #-----------------------------------------------------------------------------
  
  # Location abbreviations
  location_abbrev = {
    "australiaeast"      = "aue"
    "australiasoutheast" = "aus"
    "westeurope"         = "weu"
    "northeurope"        = "neu"
    "eastus"             = "eus"
    "westus2"            = "wus2"
  }

  primary_location_abbrev   = lookup(local.location_abbrev, var.primary_location, "aue")
  secondary_location_abbrev = lookup(local.location_abbrev, var.secondary_location, "aus")

  # Environment abbreviation
  env_abbrev = {
    "prod"    = "prd"
    "nonprod" = "npd"
    "dev"     = "dev"
    "test"    = "tst"
    "sandbox" = "sbx"
  }

  environment_abbrev = lookup(local.env_abbrev, var.environment, "prd")

  # Resource naming pattern: {type}-{project}-{env}-{region}-{instance}
  name_prefix = "${var.project_name}-${local.environment_abbrev}-${local.primary_location_abbrev}"

  #-----------------------------------------------------------------------------
  # Resource Names (auto-generated if not provided)
  #-----------------------------------------------------------------------------

  resource_group_name = var.resource_group_name

  # M01 - Log Analytics
  log_analytics_name = coalesce(
    var.log_analytics_name,
    "law-${local.name_prefix}-001"
  )

  # M02 - Automation Account (for future use)
  automation_account_name = "aa-${local.name_prefix}-001"

  # M03 - Action Groups (for future use)
  action_group_name_prefix = "ag-${local.name_prefix}"

  # M08 - Diagnostics Storage (for future use)
  diagnostics_storage_name = replace("stdiag${var.project_name}${local.environment_abbrev}${local.primary_location_abbrev}", "-", "")

  #-----------------------------------------------------------------------------
  # Tags
  #-----------------------------------------------------------------------------

  default_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Orchestrator = "management-layer"
  }

  common_tags = merge(
    local.default_tags,
    var.owner != "" ? { Owner = var.owner } : {},
    var.cost_center != "" ? { CostCenter = var.cost_center } : {},
    var.tags
  )

  #-----------------------------------------------------------------------------
  # Module Dependencies Tracking
  #-----------------------------------------------------------------------------

  # Track which modules are ready
  modules_status = {
    m01_ready = var.deploy_m01_log_analytics
    m02_ready = var.deploy_m01_log_analytics && var.deploy_m02_automation
    m03_ready = var.deploy_m01_log_analytics && var.deploy_m03_action_groups
    m04_ready = var.deploy_m01_log_analytics && var.deploy_m03_action_groups && var.deploy_m04_alerts
    m05_ready = var.deploy_m01_log_analytics && var.deploy_m05_diagnostic_settings
    m06_ready = var.deploy_m01_log_analytics && var.deploy_m02_automation && var.deploy_m06_update_management
    m07_ready = var.deploy_m01_log_analytics && var.deploy_m07_dcr
    m08_ready = var.deploy_m08_diagnostics_storage
  }

  #-----------------------------------------------------------------------------
  # Validation Messages
  #-----------------------------------------------------------------------------

  deployment_plan = {
    phase_1 = var.deploy_m01_log_analytics ? "M01 Log Analytics" : "Skipped"
    phase_2 = var.deploy_m02_automation ? "M02 Automation Account" : "Skipped"
    phase_3 = var.deploy_m03_action_groups ? "M03 Action Groups" : "Skipped"
    phase_4 = var.deploy_m04_alerts ? "M04 Alerts" : "Skipped"
    phase_5 = var.deploy_m07_dcr ? "M07 Data Collection Rules" : "Skipped"
    phase_6 = var.deploy_m08_diagnostics_storage ? "M08 Diagnostics Storage" : "Skipped"
  }
}