# =============================================================================
# M04 - Monitor Alerts Module
# variables.tf - Input Variables
# =============================================================================

# -----------------------------------------------------------------------------
# REQUIRED VARIABLES - F02 Naming Convention Integration
# -----------------------------------------------------------------------------

variable "workload" {
  description = "Workload name for resource naming via F02 module (e.g., 'platform', 'monitoring')."
  type        = string

  validation {
    condition     = length(var.workload) >= 2 && length(var.workload) <= 30
    error_message = "Workload name must be between 2 and 30 characters."
  }
}

variable "environment" {
  description = "Environment for naming and tagging. Valid values: prod, nonprod, dev, test, sandbox."
  type        = string

  validation {
    condition     = contains(["prod", "nonprod", "dev", "test", "sandbox"], var.environment)
    error_message = "Environment must be one of: prod, nonprod, dev, test, sandbox."
  }
}

# -----------------------------------------------------------------------------
# REQUIRED VARIABLES - F03 Tags Integration
# -----------------------------------------------------------------------------

variable "owner" {
  description = "Email address of the resource owner (required for F03 tags)."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.owner))
    error_message = "Owner must be a valid email address."
  }
}

variable "cost_center" {
  description = "Cost center code for billing (required for F03 tags)."
  type        = string

  validation {
    condition     = length(var.cost_center) >= 3
    error_message = "Cost center must be at least 3 characters."
  }
}

variable "application" {
  description = "Application name for tagging (required for F03 tags)."
  type        = string

  validation {
    condition     = length(var.application) >= 2
    error_message = "Application name must be at least 2 characters."
  }
}

# -----------------------------------------------------------------------------
# REQUIRED VARIABLES - Azure Resources
# -----------------------------------------------------------------------------

variable "resource_group_name" {
  description = "Name of the resource group where alerts will be created."
  type        = string
}

# -----------------------------------------------------------------------------
# OPTIONAL VARIABLES - F02 Naming Convention
# -----------------------------------------------------------------------------

variable "region" {
  description = "Azure region abbreviation for naming (e.g., 'aue' for Australia East)."
  type        = string
  default     = "aue"
}

variable "instance" {
  description = "Instance number for multiple resources (e.g., '001', '002')."
  type        = string
  default     = "001"
}

variable "custom_name_prefix" {
  description = "Custom name prefix for alerts (bypasses F02 naming if set)."
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# OPTIONAL VARIABLES - F03 Tags
# -----------------------------------------------------------------------------

variable "criticality" {
  description = "Business criticality level. Valid values: Critical, High, Medium, Low."
  type        = string
  default     = "High"

  validation {
    condition     = contains(["Critical", "High", "Medium", "Low"], var.criticality)
    error_message = "Criticality must be one of: Critical, High, Medium, Low."
  }
}

variable "data_classification" {
  description = "Data classification level. Valid values: Public, Internal, Confidential, Restricted."
  type        = string
  default     = "Internal"

  validation {
    condition     = contains(["Public", "Internal", "Confidential", "Restricted"], var.data_classification)
    error_message = "Data classification must be one of: Public, Internal, Confidential, Restricted."
  }
}

variable "project" {
  description = "Project name for F03 tags."
  type        = string
  default     = null
}

variable "department" {
  description = "Department for F03 tags."
  type        = string
  default     = null
}

variable "additional_tags" {
  description = "Additional custom tags to merge with F03 generated tags."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# OPTIONAL VARIABLES - Action Groups (from M03)
# -----------------------------------------------------------------------------

variable "action_group_ids" {
  description = "Map of action group IDs by severity key from M03 module. Expected keys: critical, warning, info, security, backup, network."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for key in keys(var.action_group_ids) :
      contains(["critical", "warning", "info", "security", "backup", "network"], key)
    ])
    error_message = "Action group keys must be one of: critical, warning, info, security, backup, network."
  }
}

# -----------------------------------------------------------------------------
# OPTIONAL VARIABLES - Default Alerts Configuration
# -----------------------------------------------------------------------------

variable "create_default_alerts" {
  description = "Create default platform alerts (Service Health, Resource Health, Activity Log)."
  type        = bool
  default     = true
}

variable "service_health_alert_config" {
  description = "Configuration for Service Health alerts."
  type = object({
    enabled       = optional(bool, true)
    name          = optional(string, "Service Health Alert")
    description   = optional(string, "Alert for Azure service health incidents and maintenance")
    event_types   = optional(list(string), ["Incident", "Maintenance"])
    regions       = optional(list(string), ["Australia East", "Australia Southeast", "Global"])
    services      = optional(list(string), [])
    severity      = optional(string, "critical")
  })
  default = {}
}

variable "resource_health_alert_config" {
  description = "Configuration for Resource Health alerts."
  type = object({
    enabled        = optional(bool, true)
    name           = optional(string, "Resource Health Alert")
    description    = optional(string, "Alert for Azure resource health degradation")
    current_states = optional(list(string), ["Degraded", "Unavailable"])
    previous_states = optional(list(string), ["Available"])
    reason_types   = optional(list(string), ["PlatformInitiated", "Unknown"])
    severity       = optional(string, "warning")
  })
  default = {}
}

variable "activity_log_admin_alert_config" {
  description = "Configuration for Activity Log Administrative alerts (delete operations)."
  type = object({
    enabled         = optional(bool, true)
    name            = optional(string, "Critical Resource Deletion Alert")
    description     = optional(string, "Alert for delete operations on critical resources")
    operation_names = optional(list(string), [
      "Microsoft.Resources/subscriptions/resourceGroups/delete",
      "Microsoft.Compute/virtualMachines/delete",
      "Microsoft.Sql/servers/delete",
      "Microsoft.Storage/storageAccounts/delete",
      "Microsoft.KeyVault/vaults/delete",
      "Microsoft.Network/virtualNetworks/delete",
      "Microsoft.RecoveryServices/vaults/delete"
    ])
    severity = optional(string, "warning")
  })
  default = {}
}

variable "activity_log_security_alert_config" {
  description = "Configuration for Activity Log Security alerts (policy violations)."
  type = object({
    enabled         = optional(bool, true)
    name            = optional(string, "Security Policy Violation Alert")
    description     = optional(string, "Alert for security-related events and policy violations")
    operation_names = optional(list(string), [
      "Microsoft.Authorization/policyAssignments/delete",
      "Microsoft.Authorization/policyExemptions/write",
      "Microsoft.Security/securityContacts/delete",
      "Microsoft.Security/pricings/write"
    ])
    categories = optional(list(string), ["Security", "Policy"])
    severity   = optional(string, "security")
  })
  default = {}
}

# -----------------------------------------------------------------------------
# OPTIONAL VARIABLES - Custom Alerts
# -----------------------------------------------------------------------------

variable "custom_activity_log_alerts" {
  description = "Map of custom Activity Log alerts to create."
  type = map(object({
    description        = optional(string, "Custom Activity Log Alert")
    enabled            = optional(bool, true)
    scopes             = optional(list(string), [])
    operation_name     = optional(string, null)
    category           = optional(string, "Administrative")
    level              = optional(string, null)
    status             = optional(string, null)
    resource_provider  = optional(string, null)
    resource_type      = optional(string, null)
    resource_group     = optional(string, null)
    resource_id        = optional(string, null)
    caller             = optional(string, null)
    severity           = optional(string, "warning")
    action_group_ids   = optional(list(string), [])
  }))
  default = {}
}

variable "custom_metric_alerts" {
  description = "Map of custom metric alerts to create."
  type = map(object({
    description              = optional(string, "Custom Metric Alert")
    enabled                  = optional(bool, true)
    scopes                   = list(string)
    severity_level           = optional(number, 2)
    frequency                = optional(string, "PT5M")
    window_size              = optional(string, "PT15M")
    auto_mitigate            = optional(bool, true)
    target_resource_type     = optional(string, null)
    target_resource_location = optional(string, null)
    criteria = list(object({
      metric_namespace       = string
      metric_name           = string
      aggregation           = string
      operator              = string
      threshold             = number
      skip_metric_validation = optional(bool, false)
      dimension = optional(list(object({
        name     = string
        operator = string
        values   = list(string)
      })), [])
    }))
    dynamic_criteria = optional(list(object({
      metric_namespace         = string
      metric_name             = string
      aggregation             = string
      operator                = string
      alert_sensitivity       = string
      evaluation_total_count  = optional(number, 4)
      evaluation_failure_count = optional(number, 4)
      ignore_data_before      = optional(string, null)
      skip_metric_validation  = optional(bool, false)
      dimension = optional(list(object({
        name     = string
        operator = string
        values   = list(string)
      })), [])
    })), [])
    severity           = optional(string, "warning")
    action_group_ids   = optional(list(string), [])
  }))
  default = {}
}

variable "custom_log_query_alerts" {
  description = "Map of custom Log Analytics query alerts to create."
  type = map(object({
    description                      = optional(string, "Custom Log Query Alert")
    enabled                          = optional(bool, true)
    location                         = optional(string, "australiaeast")
    scopes                           = list(string)
    severity_level                   = optional(number, 2)
    evaluation_frequency             = optional(string, "PT5M")
    window_duration                  = optional(string, "PT15M")
    query                            = string
    threshold                        = optional(number, 0)
    operator                         = optional(string, "GreaterThan")
    time_aggregation_method          = optional(string, "Count")
    metric_measure_column            = optional(string, null)
    resource_id_column               = optional(string, null)
    auto_mitigation_enabled          = optional(bool, true)
    workspace_alerts_storage_enabled = optional(bool, false)
    skip_query_validation            = optional(bool, false)
    mute_actions_after_alert_duration = optional(string, null)
    dimension = optional(list(object({
      name     = string
      operator = string
      values   = list(string)
    })), [])
    failing_periods = optional(object({
      minimum_failing_periods_to_trigger_alert = number
      number_of_evaluation_periods             = number
    }), null)
    severity           = optional(string, "warning")
    action_group_ids   = optional(list(string), [])
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# OPTIONAL VARIABLES - Scope Configuration
# -----------------------------------------------------------------------------

variable "subscription_ids" {
  description = "List of subscription IDs to monitor. If empty and default_scopes is empty, uses current subscription from provider context."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for id in var.subscription_ids :
      can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", id))
    ])
    error_message = "All subscription IDs must be valid UUIDs."
  }
}

variable "default_scopes" {
  description = "Full resource IDs to use as alert scopes. Takes precedence over subscription_ids. If empty, falls back to subscription_ids or current subscription."
  type        = list(string)
  default     = []
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace for log-based alerts (from M01 module output)."
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# OPTIONAL VARIABLES - Severity to Action Group Mapping
# -----------------------------------------------------------------------------

variable "severity_action_group_mapping" {
  description = "Custom mapping of severity levels to action group keys. Defaults use standard mapping."
  type        = map(string)
  default = {
    critical = "critical"
    high     = "critical"
    warning  = "warning"
    medium   = "warning"
    info     = "info"
    low      = "info"
    security = "security"
    backup   = "backup"
    network  = "network"
  }
}
