################################################################################
# main.tf - M01 Log Analytics Workspace Module
# Log Analytics Workspace with F02 Naming and F03 Tags
################################################################################

#-------------------------------------------------------------------------------
# F02 - Naming Convention Module
#-------------------------------------------------------------------------------

module "naming" {
  source = "../F02-naming-convention"

  resource_type = "log"
  workload      = var.workload
  environment   = var.environment
  region        = var.region
  instance      = var.instance
}

#-------------------------------------------------------------------------------
# F03 - Tags Module
#-------------------------------------------------------------------------------

module "tags" {
  source = "../F03-tags"

  environment         = local.f03_environment
  owner               = var.owner
  cost_center         = var.cost_center
  application         = var.application
  criticality         = var.criticality
  data_classification = var.data_classification
  project             = var.project
  department          = var.department
  module_name         = "M01-log-analytics-workspace"
  additional_tags     = var.additional_tags
}

#-------------------------------------------------------------------------------
# Primary Log Analytics Workspace
#-------------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "this" {
  name                = local.workspace_name
  resource_group_name = var.resource_group_name
  location            = var.location

  # SKU and Capacity
  sku               = var.sku
  retention_in_days = var.retention_in_days
  daily_quota_gb    = var.daily_quota_gb

  # Capacity Reservation (only when SKU is CapacityReservation)
  reservation_capacity_in_gb_per_day = local.use_capacity_reservation ? var.reservation_capacity_in_gb_per_day : null

  # Network Access
  internet_ingestion_enabled    = var.internet_ingestion_enabled
  internet_query_enabled        = var.internet_query_enabled
  local_authentication_disabled = var.local_authentication_disabled

  # Tags from F03
  tags = module.tags.all_tags

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
    prevent_destroy = false
  }
}

resource "time_sleep" "wait_for_workspace" {
  depends_on = [azurerm_log_analytics_workspace.this]

  create_duration = "60s"
}

#-------------------------------------------------------------------------------
# Table-Level Archive Configuration
#-------------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace_table" "archive" {
  for_each = var.enable_table_level_archive ? var.archive_tables : {}

  workspace_id        = azurerm_log_analytics_workspace.this.id
  name                = each.key
  total_retention_in_days = each.value
  retention_in_days   = var.retention_in_days
  depends_on = [
    azurerm_log_analytics_solution.solutions,
    time_sleep.wait_for_solutions
  ]
}

#-------------------------------------------------------------------------------
# Log Analytics Solutions
#-------------------------------------------------------------------------------

resource "azurerm_log_analytics_solution" "solutions" {
  for_each = local.solutions_to_deploy

  solution_name         = each.value.name
  resource_group_name   = var.resource_group_name
  location              = var.location
  workspace_resource_id = azurerm_log_analytics_workspace.this.id
  workspace_name        = azurerm_log_analytics_workspace.this.name

  plan {
    publisher = each.value.publisher
    product   = "OMSGallery/${each.value.name}"
  }

  tags = module.tags.all_tags
  depends_on = [time_sleep.wait_for_workspace]
}

resource "time_sleep" "wait_for_solutions" {
  depends_on = [azurerm_log_analytics_solution.solutions]

  create_duration = "60s"
}
#-------------------------------------------------------------------------------
# Secondary Workspace (DR)
#-------------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "secondary" {
  count = var.enable_cross_region_workspace ? 1 : 0

  name                = local.secondary_workspace_name
  resource_group_name = var.resource_group_name
  location            = var.secondary_location

  sku               = "PerGB2018"
  retention_in_days = var.secondary_retention_in_days

  internet_ingestion_enabled    = var.internet_ingestion_enabled
  internet_query_enabled        = var.internet_query_enabled
  local_authentication_disabled = var.local_authentication_disabled

  tags = merge(module.tags.all_tags, {
    Purpose = "DR-Secondary"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }
}

#-------------------------------------------------------------------------------
# Diagnostic Settings (Self-logging)
#-------------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "this" {
  count = local.enable_diagnostics ? 1 : 0

  name                       = "diag-${local.workspace_name}"
  target_resource_id         = azurerm_log_analytics_workspace.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  storage_account_id         = var.diagnostic_storage_account_id

  dynamic "enabled_log" {
    for_each = local.diagnostic_logs
    content {
      category = enabled_log.value.category
    }
  }
  lifecycle {
    ignore_changes = [
      name,
    ]
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
