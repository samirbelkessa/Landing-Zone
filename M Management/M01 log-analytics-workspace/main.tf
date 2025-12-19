################################################################################
# Log Analytics Workspace (M01)
# Primary workspace for centralized logging, monitoring, and security
################################################################################

#-------------------------------------------------------------------------------
# Primary Log Analytics Workspace
#-------------------------------------------------------------------------------
resource "azurerm_log_analytics_workspace" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  # SKU and Capacity
  sku               = var.sku
  retention_in_days = var.retention_in_days
  daily_quota_gb    = var.daily_quota_gb

  # Capacity Reservation (only when SKU is CapacityReservation)
  reservation_capacity_in_gb_per_day = local.use_capacity_reservation ? var.reservation_capacity_in_gb_per_day : null

  # Network Access
  internet_ingestion_enabled = var.internet_ingestion_enabled
  internet_query_enabled     = var.internet_query_enabled

  # Authentication
  local_authentication_disabled   = var.local_authentication_disabled
  allow_resource_only_permissions = var.allow_resource_only_permissions

  tags = local.tags

  lifecycle {
    prevent_destroy = false # Set to true in production
    ignore_changes = [
      # Ignore changes made by Azure services
      tags["hidden-title"],
    ]
  }
}

#-------------------------------------------------------------------------------
# Table-Level Archive Configuration
# Enables long-term retention beyond interactive period
#-------------------------------------------------------------------------------
resource "azurerm_log_analytics_workspace_table" "archive" {
  for_each = local.archive_table_configs

  workspace_id        = azurerm_log_analytics_workspace.this.id
  name                = each.value.name
  retention_in_days   = var.retention_in_days
  total_retention_in_days = each.value.total_retention_in_days

  lifecycle {
    # Tables may be created automatically by solutions
    create_before_destroy = true
  }

  depends_on = [azurerm_log_analytics_workspace.this]
}

#-------------------------------------------------------------------------------
# Log Analytics Solutions
# Pre-configured solutions for common scenarios
#-------------------------------------------------------------------------------
resource "azurerm_log_analytics_solution" "solutions" {
  for_each = local.solutions_to_deploy

  solution_name         = each.value.name
  workspace_resource_id = azurerm_log_analytics_workspace.this.id
  workspace_name        = azurerm_log_analytics_workspace.this.name
  location              = azurerm_log_analytics_workspace.this.location
  resource_group_name   = var.resource_group_name

  plan {
    publisher = each.value.publisher
    product   = "OMSGallery/${each.value.name}"
  }

  tags = local.tags

  lifecycle {
    # Solutions can be modified externally
    ignore_changes = [tags]
  }
}

#-------------------------------------------------------------------------------
# Linked Service - Automation Account
# Required for Update Management, Change Tracking, Inventory
#-------------------------------------------------------------------------------
resource "azurerm_log_analytics_linked_service" "automation" {
  count = var.link_automation_account && var.automation_account_id != null ? 1 : 0

  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  read_access_id      = var.automation_account_id

  lifecycle {
    # Link may be managed by Automation Account
    ignore_changes = [write_access_id]
  }
}

#-------------------------------------------------------------------------------
# Diagnostic Settings for the Workspace Itself
# Captures audit logs and operational metrics
#-------------------------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.enable_diagnostic_settings ? 1 : 0

  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_log_analytics_workspace.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  storage_account_id         = var.diagnostic_storage_account_id

  # Audit logs
  dynamic "enabled_log" {
    for_each = var.diagnostic_categories
    content {
      category = enabled_log.value
    }
  }

  # Metrics
  metric {
    category = "AllMetrics"
    enabled  = true
  }

  lifecycle {
    ignore_changes = [
      # Azure may add additional categories
      enabled_log,
    ]
  }
}

################################################################################
# Secondary Workspace (DR Region)
# Optional workspace for cross-region redundancy
################################################################################

resource "azurerm_log_analytics_workspace" "secondary" {
  count = var.enable_cross_region_workspace ? 1 : 0

  name                = local.secondary_workspace_name
  resource_group_name = var.resource_group_name
  location            = var.secondary_location

  # Simplified configuration for DR
  sku               = var.sku
  retention_in_days = var.secondary_retention_in_days

  # Network Access - same as primary
  internet_ingestion_enabled = var.internet_ingestion_enabled
  internet_query_enabled     = var.internet_query_enabled

  # Authentication - same as primary
  local_authentication_disabled   = var.local_authentication_disabled
  allow_resource_only_permissions = var.allow_resource_only_permissions

  tags = merge(local.tags, {
    Role         = "DR"
    PrimaryPair  = azurerm_log_analytics_workspace.this.name
  })

  lifecycle {
    prevent_destroy = false
  }
}

################################################################################
# Saved Searches (Optional)
# Common queries for operational use
################################################################################

resource "azurerm_log_analytics_saved_search" "heartbeat_failures" {
  name                       = "HeartbeatFailures"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  category     = "General Monitoring"
  display_name = "Agents with Failed Heartbeat"
  query        = <<-QUERY
    Heartbeat
    | summarize LastHeartbeat = max(TimeGenerated) by Computer, Category
    | where LastHeartbeat < ago(5m)
    | project Computer, Category, LastHeartbeat, MinutesSinceLastHeartbeat = datetime_diff('minute', now(), LastHeartbeat)
    | order by MinutesSinceLastHeartbeat desc
  QUERY

  function_alias      = "FailedHeartbeats"
  function_parameters = null

  tags = local.tags
}

resource "azurerm_log_analytics_saved_search" "high_cpu_vms" {
  name                       = "HighCPUVMs"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  category     = "Performance"
  display_name = "VMs with High CPU Utilization"
  query        = <<-QUERY
    Perf
    | where ObjectName == "Processor" and CounterName == "% Processor Time" and InstanceName == "_Total"
    | summarize AvgCPU = avg(CounterValue), MaxCPU = max(CounterValue) by Computer, bin(TimeGenerated, 5m)
    | where AvgCPU > 80
    | order by TimeGenerated desc
  QUERY

  function_alias = "HighCPUVMs"

  tags = local.tags
}

resource "azurerm_log_analytics_saved_search" "failed_logins" {
  name                       = "FailedLogins"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  category     = "Security"
  display_name = "Failed Login Attempts"
  query        = <<-QUERY
    SecurityEvent
    | where EventID == 4625
    | summarize FailedAttempts = count() by Account, Computer, IpAddress, bin(TimeGenerated, 1h)
    | where FailedAttempts > 5
    | order by FailedAttempts desc
  QUERY

  function_alias = "FailedLogins"

  tags = local.tags
}

################################################################################
# Query Pack (Optional)
# Reusable query collections
################################################################################

resource "azurerm_log_analytics_query_pack" "caf_queries" {
  name                = "caf-queries-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = local.tags
}

resource "azurerm_log_analytics_query_pack_query" "resource_changes" {
  query_pack_id = azurerm_log_analytics_query_pack.caf_queries.id
  
  body         = <<-QUERY
    AzureActivity
    | where OperationNameValue endswith "write" or OperationNameValue endswith "delete"
    | where ActivityStatusValue == "Success"
    | project TimeGenerated, Caller, OperationNameValue, ResourceGroup, Resource = _ResourceId
    | order by TimeGenerated desc
  QUERY
  display_name = "Resource Changes in Last 24 Hours"
  description  = "Shows all successful write and delete operations"
  
  categories   = ["Azure Resources"]

  additional_settings_json = jsonencode({
    createdBy = "Terraform"
  })
}