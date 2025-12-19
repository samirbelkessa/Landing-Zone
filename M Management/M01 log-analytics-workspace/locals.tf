################################################################################
# Locals - Log Analytics Workspace (M01)
################################################################################

locals {
  #-----------------------------------------------------------------------------
  # Tags
  #-----------------------------------------------------------------------------
  default_tags = {
    ManagedBy = "Terraform"
    Module    = "log-analytics-workspace"
  }

  tags = merge(local.default_tags, var.tags)

  #-----------------------------------------------------------------------------
  # Workspace Configuration
  #-----------------------------------------------------------------------------
  
  # Determine if we need capacity reservation
  use_capacity_reservation = var.sku == "CapacityReservation" && var.reservation_capacity_in_gb_per_day != null

  # Calculate archive retention (total - interactive)
  archive_retention_days = var.total_retention_in_days - var.retention_in_days

  # Validate archive configuration
  archive_enabled = local.archive_retention_days > 0 && var.enable_table_level_archive

  #-----------------------------------------------------------------------------
  # Solutions Configuration
  #-----------------------------------------------------------------------------
  
  # Filter solutions to deploy
  solutions_to_deploy = var.deploy_solutions ? {
    for solution in var.solutions : "${solution.name}-${solution.publisher}" => solution
  } : {}

  #-----------------------------------------------------------------------------
  # Archive Tables Configuration
  #-----------------------------------------------------------------------------
  
  # Only configure archive if enabled and there are tables defined
  archive_table_configs = var.enable_table_level_archive ? {
    for table_name, retention in var.archive_tables : table_name => {
      name                         = table_name
      total_retention_in_days      = retention
      archive_retention_in_days    = retention - var.retention_in_days
    }
    if retention > var.retention_in_days
  } : {}

  #-----------------------------------------------------------------------------
  # Diagnostic Settings
  #-----------------------------------------------------------------------------
  
  # Determine diagnostic settings destination
  diagnostic_destination = var.diagnostic_storage_account_id != null ? "storage_and_workspace" : "workspace_only"

  #-----------------------------------------------------------------------------
  # Secondary Workspace (DR)
  #-----------------------------------------------------------------------------
  
  secondary_workspace_name = var.enable_cross_region_workspace ? "${var.name}${var.secondary_name_suffix}" : null

  #-----------------------------------------------------------------------------
  # Output Helpers
  #-----------------------------------------------------------------------------
  
  # Summary of workspace configuration
  workspace_config_summary = {
    sku                    = var.sku
    retention_interactive  = var.retention_in_days
    retention_total        = var.total_retention_in_days
    retention_archive      = local.archive_retention_days
    archive_enabled        = local.archive_enabled
    solutions_count        = length(local.solutions_to_deploy)
    internet_ingestion     = var.internet_ingestion_enabled
    internet_query         = var.internet_query_enabled
    local_auth_disabled    = var.local_authentication_disabled
    dr_enabled             = var.enable_cross_region_workspace
  }
}