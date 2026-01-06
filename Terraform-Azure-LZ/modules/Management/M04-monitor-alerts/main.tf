# =============================================================================
# M04 - Monitor Alerts Module
# main.tf - Azure Monitor Alert Resources
# =============================================================================

# =============================================================================
# DEFAULT ALERTS - SERVICE HEALTH
# =============================================================================

resource "azurerm_monitor_activity_log_alert" "service_health" {
  count = local.create_service_health_alert ? 1 : 0

  name                = local.service_health_alert_name
  resource_group_name = data.azurerm_resource_group.this.name
  location            = "global"
  description         = local.service_health_config.description
  enabled             = true
  scopes              = local.default_scope

  criteria {
    category = "ServiceHealth"

    service_health {
      events   = local.service_health_config.event_types
      locations = local.service_health_config.regions
      services  = length(local.service_health_config.services) > 0 ? local.service_health_config.services : null
    }
  }

  dynamic "action" {
    for_each = lookup(local.get_action_group_for_severity, local.service_health_config.severity, null) != null ? [1] : []
    content {
      action_group_id = local.get_action_group_for_severity[local.service_health_config.severity]
    }
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# DEFAULT ALERTS - RESOURCE HEALTH
# =============================================================================

resource "azurerm_monitor_activity_log_alert" "resource_health" {
  count = local.create_resource_health_alert ? 1 : 0

  name                = local.resource_health_alert_name
  resource_group_name = data.azurerm_resource_group.this.name
  location            = "global"
  description         = local.resource_health_config.description
  enabled             = true
  scopes              = local.default_scope

  criteria {
    category = "ResourceHealth"

    resource_health {
      current  = local.resource_health_config.current_states
      previous = local.resource_health_config.previous_states
      reason   = local.resource_health_config.reason_types
    }
  }

  dynamic "action" {
    for_each = lookup(local.get_action_group_for_severity, local.resource_health_config.severity, null) != null ? [1] : []
    content {
      action_group_id = local.get_action_group_for_severity[local.resource_health_config.severity]
    }
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# DEFAULT ALERTS - ACTIVITY LOG ADMINISTRATIVE (DELETE OPERATIONS)
# =============================================================================

resource "azurerm_monitor_activity_log_alert" "admin_delete" {
  count = local.create_activity_admin_alert ? 1 : 0

  name                = local.activity_admin_alert_name
  resource_group_name = data.azurerm_resource_group.this.name
  location            = "global"
  description         = local.activity_log_admin_config.description
  enabled             = true
  scopes              = local.default_scope

  criteria {
    category       = "Administrative"
    operation_name = local.activity_log_admin_config.operation_names[0]
    level          = "Critical"
  }

  dynamic "action" {
    for_each = lookup(local.get_action_group_for_severity, local.activity_log_admin_config.severity, null) != null ? [1] : []
    content {
      action_group_id = local.get_action_group_for_severity[local.activity_log_admin_config.severity]
    }
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

# Additional alerts for each delete operation type
resource "azurerm_monitor_activity_log_alert" "admin_delete_operations" {
  for_each = local.create_activity_admin_alert ? toset(slice(local.activity_log_admin_config.operation_names, 1, length(local.activity_log_admin_config.operation_names))) : toset([])

  #name                = "${local.activity_admin_alert_name}-${replace(replace(split("/", each.value)[1], "Microsoft.", ""), ".", "-")}"
  name = "${local.name_prefix}-admin-delete-${replace(replace(lower(each.key), "microsoft.", ""), "/", "-")}"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = "global"
  description         = "Alert for: ${each.value}"
  enabled             = true
  scopes              = local.default_scope

  criteria {
    category       = "Administrative"
    operation_name = each.value
  }

  dynamic "action" {
    for_each = lookup(local.get_action_group_for_severity, local.activity_log_admin_config.severity, null) != null ? [1] : []
    content {
      action_group_id = local.get_action_group_for_severity[local.activity_log_admin_config.severity]
    }
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }

}

# =============================================================================
# DEFAULT ALERTS - ACTIVITY LOG SECURITY (POLICY VIOLATIONS)
# =============================================================================

resource "azurerm_monitor_activity_log_alert" "security" {
  count = local.create_activity_security_alert ? 1 : 0

  name                = local.activity_security_alert_name
  resource_group_name = data.azurerm_resource_group.this.name
  location            = "global"
  description         = local.activity_log_security_config.description
  enabled             = true
  scopes              = local.default_scope

  criteria {
    category       = "Security"
    operation_name = local.activity_log_security_config.operation_names[0]
  }

  dynamic "action" {
    for_each = lookup(local.get_action_group_for_severity, local.activity_log_security_config.severity, null) != null ? [1] : []
    content {
      action_group_id = local.get_action_group_for_severity[local.activity_log_security_config.severity]
    }
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

# Additional security operation alerts
resource "azurerm_monitor_activity_log_alert" "security_operations" {
  for_each = local.create_activity_security_alert ? toset(slice(local.activity_log_security_config.operation_names, 1, length(local.activity_log_security_config.operation_names))) : toset([])

  #name                = "${local.activity_security_alert_name}-${lower(replace(replace(split("/", each.value)[length(split("/", each.value)) - 1], ".", "-"), "_", "-"))}"
  name = "${local.name_prefix}-security-${replace(replace(lower(each.key), "microsoft.", ""), "/", "-")}"
  
  resource_group_name = data.azurerm_resource_group.this.name
  location            = "global"
  description         = "Security alert for: ${each.value}"
  enabled             = true
  scopes              = local.default_scope

  criteria {
    category       = "Security"
    operation_name = each.value
  }

  dynamic "action" {
    for_each = lookup(local.get_action_group_for_severity, local.activity_log_security_config.severity, null) != null ? [1] : []
    content {
      action_group_id = local.get_action_group_for_severity[local.activity_log_security_config.severity]
    }
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# CUSTOM ALERTS - ACTIVITY LOG
# =============================================================================

resource "azurerm_monitor_activity_log_alert" "custom" {
  for_each = { for k, v in local.custom_activity_alerts_resolved : k => v if v.enabled }

  name                = "${local.name_prefix}-${each.key}"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = "global"
  description         = each.value.description
  enabled             = true
  scopes              = each.value.resolved_scopes

  criteria {
    category       = each.value.category
    operation_name = each.value.operation_name
    level          = each.value.level
    status         = each.value.status

    dynamic "resource_health" {
      for_each = each.value.category == "ResourceHealth" ? [1] : []
      content {
        current  = ["Degraded", "Unavailable"]
        previous = ["Available"]
      }
    }
  }

  dynamic "action" {
    for_each = each.value.resolved_action_group_ids
    content {
      action_group_id = action.value
    }
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# CUSTOM ALERTS - METRIC ALERTS
# =============================================================================

resource "azurerm_monitor_metric_alert" "custom" {
  for_each = { for k, v in local.custom_metric_alerts_resolved : k => v if v.enabled }

  name                     = "${local.name_prefix}-metric-${each.key}"
  resource_group_name      = data.azurerm_resource_group.this.name
  description              = each.value.description
  enabled                  = true
  scopes                   = each.value.resolved_scopes
  severity                 = each.value.severity_level
  frequency                = each.value.frequency
  window_size              = each.value.window_size
  auto_mitigate            = each.value.auto_mitigate
  target_resource_type     = each.value.target_resource_type
  target_resource_location = each.value.target_resource_location

  dynamic "criteria" {
    for_each = each.value.criteria
    content {
      metric_namespace       = criteria.value.metric_namespace
      metric_name           = criteria.value.metric_name
      aggregation           = criteria.value.aggregation
      operator              = criteria.value.operator
      threshold             = criteria.value.threshold
      skip_metric_validation = criteria.value.skip_metric_validation

      dynamic "dimension" {
        for_each = criteria.value.dimension
        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }
    }
  }

  dynamic "dynamic_criteria" {
    for_each = each.value.dynamic_criteria
    content {
      metric_namespace         = dynamic_criteria.value.metric_namespace
      metric_name             = dynamic_criteria.value.metric_name
      aggregation             = dynamic_criteria.value.aggregation
      operator                = dynamic_criteria.value.operator
      alert_sensitivity       = dynamic_criteria.value.alert_sensitivity
      evaluation_total_count  = dynamic_criteria.value.evaluation_total_count
      evaluation_failure_count = dynamic_criteria.value.evaluation_failure_count
      ignore_data_before      = dynamic_criteria.value.ignore_data_before
      skip_metric_validation  = dynamic_criteria.value.skip_metric_validation

      dynamic "dimension" {
        for_each = dynamic_criteria.value.dimension
        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }
    }
  }

  dynamic "action" {
    for_each = each.value.resolved_action_group_ids
    content {
      action_group_id = action.value
    }
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# CUSTOM ALERTS - LOG QUERY ALERTS (Scheduled Query Rules)
# =============================================================================

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "custom" {
  for_each = { 
    for k, v in var.custom_log_query_alerts : k => local.custom_log_alerts_resolved[k]
    if try(v.enabled, true)
  }

  name                = "${local.name_prefix}-log-${each.key}"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = each.value.location
  description         = each.value.description
  enabled             = true
  scopes              = each.value.resolved_scopes
  severity            = each.value.severity_level

  evaluation_frequency = each.value.evaluation_frequency
  window_duration      = each.value.window_duration

  criteria {
    query                   = each.value.query
    time_aggregation_method = each.value.time_aggregation_method
    threshold               = each.value.threshold
    operator                = each.value.operator
    metric_measure_column   = each.value.metric_measure_column
    resource_id_column      = each.value.resource_id_column

    dynamic "dimension" {
      for_each = each.value.dimension != null ? each.value.dimension : []
      content {
        name     = dimension.value.name
        operator = dimension.value.operator
        values   = dimension.value.values
      }
    }

    dynamic "failing_periods" {
      for_each = each.value.failing_periods != null ? [each.value.failing_periods] : []
      content {
        minimum_failing_periods_to_trigger_alert = failing_periods.value.minimum_failing_periods_to_trigger_alert
        number_of_evaluation_periods             = failing_periods.value.number_of_evaluation_periods
      }
    }
  }

  auto_mitigation_enabled           = each.value.auto_mitigation_enabled
  workspace_alerts_storage_enabled  = each.value.workspace_alerts_storage_enabled
  skip_query_validation             = each.value.skip_query_validation
  mute_actions_after_alert_duration = each.value.mute_actions_after_alert_duration

  dynamic "action" {
    for_each = each.value.resolved_action_group_ids
    content {
      action_groups = [action.value]
    }
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

