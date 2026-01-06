# ============================================================================
# OUTPUTS
# ============================================================================

output "id" {
  description = "The ID of the diagnostic setting."
  value       = azurerm_monitor_diagnostic_setting.this.id
}

output "name" {
  description = "The name of the diagnostic setting."
  value       = azurerm_monitor_diagnostic_setting.this.name
}

output "target_resource_id" {
  description = "The ID of the resource on which diagnostic settings are configured."
  value       = azurerm_monitor_diagnostic_setting.this.target_resource_id
}

# ============================================================================
# DESTINATIONS
# ============================================================================

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace where diagnostics are sent (if configured)."
  value       = azurerm_monitor_diagnostic_setting.this.log_analytics_workspace_id
}

output "storage_account_id" {
  description = "The ID of the Storage Account where diagnostics are archived (if configured)."
  value       = azurerm_monitor_diagnostic_setting.this.storage_account_id
}

output "eventhub_authorization_rule_id" {
  description = "The ID of the Event Hub authorization rule where diagnostics are streamed (if configured)."
  value       = azurerm_monitor_diagnostic_setting.this.eventhub_authorization_rule_id
}

output "eventhub_name" {
  description = "The name of the Event Hub where diagnostics are streamed (if configured)."
  value       = azurerm_monitor_diagnostic_setting.this.eventhub_name
}

# ============================================================================
# ENABLED CATEGORIES
# ============================================================================

output "enabled_log_categories" {
  description = "List of enabled log categories for this diagnostic setting."
  value       = local.selected_log_categories
}

output "enabled_metric_categories" {
  description = "List of enabled metric categories for this diagnostic setting."
  value       = local.selected_metric_categories
}

output "available_log_categories" {
  description = "List of all available log categories for the target resource (discovered via data source)."
  value       = data.azurerm_monitor_diagnostic_categories.this.log_category_types
}

output "available_metric_categories" {
  description = "List of all available metric categories for the target resource (discovered via data source)."
  value       = data.azurerm_monitor_diagnostic_categories.this.metrics
}

# ============================================================================
# CONFIGURATION
# ============================================================================

output "logs_retention_days" {
  description = "Number of days logs are retained (applies to Storage Account destination only)."
  value       = var.logs_retention_days
}

output "metrics_retention_days" {
  description = "Number of days metrics are retained (applies to Storage Account destination only)."
  value       = var.metrics_retention_days
}

output "log_analytics_destination_type" {
  description = "The Log Analytics destination type (Dedicated or AzureDiagnostics)."
  value       = azurerm_monitor_diagnostic_setting.this.log_analytics_destination_type
}
