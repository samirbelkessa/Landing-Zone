################################################################################
# locals.tf - M01 Log Analytics Workspace Module
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
  workspace_name = var.custom_name != null ? var.custom_name : module.naming.name

  #-----------------------------------------------------------------------------
  # Secondary Workspace Name (for DR)
  #-----------------------------------------------------------------------------
  secondary_workspace_name = "${local.workspace_name}-dr"

  #-----------------------------------------------------------------------------
  # SKU Configuration
  #-----------------------------------------------------------------------------
  use_capacity_reservation = var.sku == "CapacityReservation"

  #-----------------------------------------------------------------------------
  # Archive Retention Calculation
  #-----------------------------------------------------------------------------
  archive_retention_days = var.total_retention_in_days - var.retention_in_days

  #-----------------------------------------------------------------------------
  # Solutions to Deploy
  #-----------------------------------------------------------------------------
  solutions_to_deploy = var.deploy_solutions ? {
    for sol in var.solutions : "${sol.name}-${sol.publisher}" => sol
  } : {}

  #-----------------------------------------------------------------------------
  # Diagnostic Settings
  #-----------------------------------------------------------------------------
  enable_diagnostics = var.enable_diagnostic_settings

  diagnostic_logs = [
    for category in var.diagnostic_categories : {
      category = category
      enabled  = true
    }
  ]
}
