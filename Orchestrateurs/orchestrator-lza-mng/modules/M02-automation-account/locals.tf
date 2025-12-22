################################################################################
# locals.tf - M02 Automation Account Module
# Local Values and Calculations
################################################################################

locals {
  #-----------------------------------------------------------------------------
  # Environment Mapping for F03 Tags
  # F02 uses lowercase short names, F03 uses full names
  #-----------------------------------------------------------------------------
  environment_mapping = {
    "prod"    = "Production"
    "nonprod" = "PreProduction"
    "dev"     = "Development"
    "test"    = "Test"
    "uat"     = "PreProduction"
    "stg"     = "PreProduction"
    "sandbox" = "Sandbox"
  }

  f03_environment = local.environment_mapping[var.environment]

  #-----------------------------------------------------------------------------
  # Final Resource Name (from F02 or custom)
  #-----------------------------------------------------------------------------
  automation_account_name = var.custom_name != null ? var.custom_name : module.naming.name

  #-----------------------------------------------------------------------------
  # Identity Configuration
  #-----------------------------------------------------------------------------
  identity_ids = var.identity_type == "SystemAssigned" ? null : var.identity_ids

  #-----------------------------------------------------------------------------
  # Diagnostic Settings
  #-----------------------------------------------------------------------------
  enable_diagnostics = var.enable_diagnostic_settings && var.log_analytics_workspace_id != null && var.log_analytics_workspace_id != ""

  diagnostic_logs = var.enable_diagnostic_settings ? [
    for category in var.diagnostic_log_categories : {
      category = category
      enabled  = true
    }
  ] : []

  diagnostic_metrics = var.enable_diagnostic_settings ? [
    for category in var.diagnostic_metric_categories : {
      category = category
      enabled  = true
    }
  ] : []

  #-----------------------------------------------------------------------------
  # Linked Service
  #-----------------------------------------------------------------------------
  create_linked_service = var.create_la_linked_service && var.log_analytics_workspace_id != null && var.log_analytics_workspace_id != ""
}
