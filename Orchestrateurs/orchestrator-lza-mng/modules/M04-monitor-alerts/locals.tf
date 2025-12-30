# =============================================================================
# M04 - Monitor Alerts Module
# locals.tf - Local Variables and Computed Values
# =============================================================================

locals {
  # ---------------------------------------------------------------------------
  # Environment Mapping (aligns with F02/F03)
  # ---------------------------------------------------------------------------
  environment_map = {
    prod    = "prd"
    nonprod = "npd"
    dev     = "dev"
    test    = "tst"
    sandbox = "sbx"
  }
  env_short = lookup(local.environment_map, var.environment, "dev")

  # ---------------------------------------------------------------------------
  # Naming Convention (F02 Integration)
  # ---------------------------------------------------------------------------
  name_prefix = var.custom_name_prefix != null ? var.custom_name_prefix : "alert-${var.workload}-${local.env_short}-${var.region}-${var.instance}"

  # ---------------------------------------------------------------------------
  # Default Tags (F03 Integration)
  # ---------------------------------------------------------------------------
  default_tags = {
    ManagedBy          = "Terraform"
    Module             = "M04-monitor-alerts"
    Environment        = var.environment
    Owner              = var.owner
    CostCenter         = var.cost_center
    Application        = var.application
    Criticality        = var.criticality
    DataClassification = var.data_classification
  }

  optional_tags = merge(
    var.project != null ? { Project = var.project } : {},
    var.department != null ? { Department = var.department } : {}
  )

  tags = merge(local.default_tags, local.optional_tags, var.additional_tags)

  # ---------------------------------------------------------------------------
  # Scope Configuration (Dynamic - no hardcoding)
  # Priority: 1) Explicit scopes variable, 2) Subscription IDs variable, 3) Current subscription
  # ---------------------------------------------------------------------------
  # Build subscription scope from subscription_ids if provided
  subscription_scopes = [
    for sub_id in var.subscription_ids : "/subscriptions/${sub_id}"
  ]
  
  # Determine final scopes: explicit scopes > subscription_ids > current subscription
  default_scope = length(var.default_scopes) > 0 ? var.default_scopes : (
    length(local.subscription_scopes) > 0 ? local.subscription_scopes : [local.current_subscription_scope]
  )
  
  # Current subscription as fallback (derived from provider context)
  current_subscription_scope = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"

  # ---------------------------------------------------------------------------
  # Action Group Resolution
  # ---------------------------------------------------------------------------
  # Map severity to action group ID, with fallback to warning
  resolve_action_group = {
    for severity, ag_key in var.severity_action_group_mapping :
    severity => lookup(var.action_group_ids, ag_key, lookup(var.action_group_ids, "warning", null))
  }

  # Helper function to get action group ID for a severity
  get_action_group_for_severity = {
    critical = lookup(local.resolve_action_group, "critical", null)
    high     = lookup(local.resolve_action_group, "high", null)
    warning  = lookup(local.resolve_action_group, "warning", null)
    medium   = lookup(local.resolve_action_group, "medium", null)
    info     = lookup(local.resolve_action_group, "info", null)
    low      = lookup(local.resolve_action_group, "low", null)
    security = lookup(local.resolve_action_group, "security", null)
    backup   = lookup(local.resolve_action_group, "backup", null)
    network  = lookup(local.resolve_action_group, "network", null)
  }

  # ---------------------------------------------------------------------------
  # Default Alerts Configuration
  # ---------------------------------------------------------------------------
  service_health_config = merge({
    enabled       = true
    name          = "Service Health Alert"
    description   = "Alert for Azure service health incidents and maintenance"
    event_types   = ["Incident", "Maintenance"]
    regions       = ["Australia East", "Australia Southeast", "Global"]
    services      = []
    severity      = "critical"
  }, var.service_health_alert_config)

  resource_health_config = merge({
    enabled         = true
    name            = "Resource Health Alert"
    description     = "Alert for Azure resource health degradation"
    current_states  = ["Degraded", "Unavailable"]
    previous_states = ["Available"]
    reason_types    = ["PlatformInitiated", "Unknown"]
    severity        = "warning"
  }, var.resource_health_alert_config)

  activity_log_admin_config = merge({
    enabled = true
    name    = "Critical Resource Deletion Alert"
    description = "Alert for delete operations on critical resources"
    operation_names = [
      "Microsoft.Resources/subscriptions/resourceGroups/delete",
      "Microsoft.Compute/virtualMachines/delete",
      "Microsoft.Sql/servers/delete",
      "Microsoft.Storage/storageAccounts/delete",
      "Microsoft.KeyVault/vaults/delete",
      "Microsoft.Network/virtualNetworks/delete",
      "Microsoft.RecoveryServices/vaults/delete"
    ]
    severity = "warning"
  }, var.activity_log_admin_alert_config)

  activity_log_security_config = merge({
    enabled     = true
    name        = "Security Policy Violation Alert"
    description = "Alert for security-related events and policy violations"
    operation_names = [
      "Microsoft.Authorization/policyAssignments/delete",
      "Microsoft.Authorization/policyExemptions/write",
      "Microsoft.Security/securityContacts/delete",
      "Microsoft.Security/pricings/write"
    ]
    categories = ["Security", "Policy"]
    severity   = "security"
  }, var.activity_log_security_alert_config)

  # ---------------------------------------------------------------------------
  # Default Alerts - Enabled Flags
  # ---------------------------------------------------------------------------
  create_service_health_alert     = var.create_default_alerts && local.service_health_config.enabled
  create_resource_health_alert    = var.create_default_alerts && local.resource_health_config.enabled
  create_activity_admin_alert     = var.create_default_alerts && local.activity_log_admin_config.enabled
  create_activity_security_alert  = var.create_default_alerts && local.activity_log_security_config.enabled

  # ---------------------------------------------------------------------------
  # Alert Names with Prefix
  # ---------------------------------------------------------------------------
  service_health_alert_name     = "${local.name_prefix}-svchealth"
  resource_health_alert_name    = "${local.name_prefix}-reshealth"
  activity_admin_alert_name     = "${local.name_prefix}-admin-delete"
  activity_security_alert_name  = "${local.name_prefix}-security"

  # ---------------------------------------------------------------------------
  # Custom Alerts - Resolved Action Groups
  # ---------------------------------------------------------------------------
  custom_activity_alerts_resolved = {
    for key, config in var.custom_activity_log_alerts : key => merge(config, {
      resolved_action_group_ids = length(config.action_group_ids) > 0 ? config.action_group_ids : (
        lookup(local.get_action_group_for_severity, config.severity, null) != null ? 
        [local.get_action_group_for_severity[config.severity]] : []
      )
      resolved_scopes = length(config.scopes) > 0 ? config.scopes : local.default_scope
    })
  }

  custom_metric_alerts_resolved = {
    for key, config in var.custom_metric_alerts : key => merge(config, {
      resolved_action_group_ids = length(config.action_group_ids) > 0 ? config.action_group_ids : (
        lookup(local.get_action_group_for_severity, config.severity, null) != null ? 
        [local.get_action_group_for_severity[config.severity]] : []
      )
    })
  }

custom_log_alerts_resolved = {
  for key, config in var.custom_log_query_alerts : key => merge(config, {
    resolved_action_group_ids = length(try(config.action_group_ids, [])) > 0 ? config.action_group_ids : (
      lookup(local.get_action_group_for_severity, config.severity, null) != null ? 
      [local.get_action_group_for_severity[config.severity]] : []
    )
    resolved_scopes = length(config.scopes) > 0 ? config.scopes : (
      var.log_analytics_workspace_id != null ? [var.log_analytics_workspace_id] : []
    )
  })
}

  # ---------------------------------------------------------------------------
  # Alert Summary for Outputs
  # ---------------------------------------------------------------------------
  default_alerts_summary = {
    service_health = {
      enabled = local.create_service_health_alert
      name    = local.create_service_health_alert ? azurerm_monitor_activity_log_alert.service_health[0].name : null
      id      = local.create_service_health_alert ? azurerm_monitor_activity_log_alert.service_health[0].id : null
    }
    resource_health = {
      enabled = local.create_resource_health_alert
      name    = local.create_resource_health_alert ? azurerm_monitor_activity_log_alert.resource_health[0].name : null
      id      = local.create_resource_health_alert ? azurerm_monitor_activity_log_alert.resource_health[0].id : null
    }
    activity_admin = {
      enabled = local.create_activity_admin_alert
      name    = local.create_activity_admin_alert ? azurerm_monitor_activity_log_alert.admin_delete[0].name : null
      id      = local.create_activity_admin_alert ? azurerm_monitor_activity_log_alert.admin_delete[0].id : null
    }
    activity_security = {
      enabled = local.create_activity_security_alert
      name    = local.create_activity_security_alert ? azurerm_monitor_activity_log_alert.security[0].name : null
      id      = local.create_activity_security_alert ? azurerm_monitor_activity_log_alert.security[0].id : null
    }
  }

}

# ---------------------------------------------------------------------------
# Data Sources
# ---------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}
