# ============================================================================
# LOCAL VARIABLES
# ============================================================================

locals {
  # Extract resource name from resource ID for naming
  resource_name = element(split("/", var.target_resource_id), length(split("/", var.target_resource_id)) - 1)

  # Generate diagnostic setting name if not provided
  diagnostic_setting_name = coalesce(
    var.name,
    "diag-${local.resource_name}"
  )

  # Default tags following CAF conventions
  default_tags = {
    ManagedBy = "Terraform"
    Module    = "diagnostic-settings"
  }

  # Merge default tags with user-provided tags
  tags = merge(local.default_tags, var.tags)

  # Validate that at least one destination is provided
  has_destination = (
    var.log_analytics_workspace_id != null ||
    var.storage_account_id != null ||
    var.eventhub_authorization_rule_id != null
  )

  # Determine if we should enable logs based on configuration
  enable_logs = var.enabled_log_categories != null ? !contains(var.enabled_log_categories, "none") : true

  # Determine if we should enable metrics based on configuration
  enable_metrics = var.enabled_metric_categories != null ? !contains(var.enabled_metric_categories, "none") : true

  # Filter log categories based on user input
  # If enabled_log_categories is null or empty, enable all categories
  # If it contains specific categories, filter to those
  # If it contains "none", disable all logs
  selected_log_categories = local.enable_logs ? (
    var.enabled_log_categories != null && length(var.enabled_log_categories) > 0 ?
    [for category in data.azurerm_monitor_diagnostic_categories.this.log_category_types :
      category if contains(var.enabled_log_categories, category)
    ] :
    data.azurerm_monitor_diagnostic_categories.this.log_category_types
  ) : []

  # Filter metric categories based on user input
  selected_metric_categories = local.enable_metrics ? (
    var.enabled_metric_categories != null && length(var.enabled_metric_categories) > 0 ?
    [for category in data.azurerm_monitor_diagnostic_categories.this.metrics :
      category if contains(var.enabled_metric_categories, category)
    ] :
    data.azurerm_monitor_diagnostic_categories.this.metrics
  ) : []
}
