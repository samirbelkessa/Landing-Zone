# ============================================================================
# DATA SOURCES
# ============================================================================

# Retrieve available diagnostic categories for the target resource
data "azurerm_monitor_diagnostic_categories" "this" {
  resource_id = var.target_resource_id
}

# ============================================================================
# DIAGNOSTIC SETTINGS
# ============================================================================

resource "azurerm_monitor_diagnostic_setting" "this" {
  name = local.diagnostic_setting_name

  target_resource_id = var.target_resource_id

  # Destinations
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  storage_account_id             = var.storage_account_id
  eventhub_authorization_rule_id = var.eventhub_authorization_rule_id
  eventhub_name                  = var.eventhub_name

  # Log Analytics destination type (Dedicated vs AzureDiagnostics table)
  log_analytics_destination_type = var.log_analytics_workspace_id != null ? var.log_analytics_destination_type : null

  # Dynamic block for enabled log categories
  dynamic "enabled_log" {
    for_each = local.selected_log_categories

    content {
      category = enabled_log.value
    }
  }

  # Dynamic block for enabled metric categories
  dynamic "metric" {
    for_each = local.selected_metric_categories

    content {
      category = metric.value
      enabled  = true
    }
  }

  # Lifecycle management with validation
  lifecycle {
    # Prevent accidental deletion of diagnostic settings
    prevent_destroy = false

    # Validate that at least one destination is configured
    precondition {
      condition     = local.has_destination
      error_message = "At least one destination must be specified (log_analytics_workspace_id, storage_account_id, or eventhub_authorization_rule_id)."
    }
  }
}
