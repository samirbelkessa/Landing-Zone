################################################################################
# variables.tf - Management Layer Orchestrator
################################################################################

#-------------------------------------------------------------------------------
# PROJECT CONFIGURATION
#-------------------------------------------------------------------------------

variable "project_name" {
  description = "Project name for resource naming (e.g., 'platform', 'lz')."
  type        = string
  default     = "platform"

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.project_name)) && length(var.project_name) >= 2
    error_message = "Project name must be lowercase alphanumeric with optional hyphens."
  }
}

variable "environment" {
  description = "Environment: prod, nonprod, dev, test, uat, stg, sandbox."
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["prod", "nonprod", "dev", "test", "uat", "stg", "sandbox"], var.environment)
    error_message = "Environment must be one of: prod, nonprod, dev, test, uat, stg, sandbox."
  }
}

#-------------------------------------------------------------------------------
# LOCATION CONFIGURATION
#-------------------------------------------------------------------------------

variable "primary_location" {
  description = "Primary Azure region (e.g., 'australiaeast')."
  type        = string
  default     = "australiaeast"
}

variable "secondary_location" {
  description = "Secondary Azure region for DR."
  type        = string
  default     = "australiasoutheast"
}

#-------------------------------------------------------------------------------
# RESOURCE GROUP
#-------------------------------------------------------------------------------

variable "resource_group_name" {
  description = "Name of the Management resource group."
  type        = string
}

variable "create_resource_group" {
  description = "Create the resource group if it doesn't exist."
  type        = bool
  default     = true
}

#===============================================================================
# F02 - NAMING CONVENTION INPUTS (Shared across ALL modules)
#===============================================================================

variable "workload" {
  description = "Workload name for F02 naming convention (e.g., 'platform', 'app')."
  type        = string

  validation {
    condition     = length(var.workload) >= 2 && length(var.workload) <= 10
    error_message = "Workload must be between 2 and 10 characters."
  }
}

variable "region" {
  description = "Azure region abbreviation for F02 naming (e.g., 'aue' for Australia East)."
  type        = string
  default     = "aue"

  validation {
    condition     = length(var.region) >= 2 && length(var.region) <= 4
    error_message = "Region abbreviation must be between 2 and 4 characters."
  }
}

variable "instance" {
  description = "Instance number for F02 naming convention (e.g., '001', '002')."
  type        = string
  default     = "001"

  validation {
    condition     = can(regex("^[0-9]{3}$", var.instance))
    error_message = "Instance must be a 3-digit number (e.g., '001')."
  }
}
#-------------------------------------------------------------------------------
# TAGGING - F03 Required Inputs
#-------------------------------------------------------------------------------

variable "owner" {
  description = "Owner email address for F03 tags (required)."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.owner))
    error_message = "Owner must be a valid email address."
  }
}

variable "cost_center" {
  description = "Cost center code for F03 tags (required)."
  type        = string

  validation {
    condition     = length(var.cost_center) >= 3 && length(var.cost_center) <= 20
    error_message = "Cost center must be between 3 and 20 characters."
  }
}

variable "application" {
  description = "Application name for F03 tags."
  type        = string
  default     = "Platform Management"
}

variable "criticality" {
  description = "Business criticality: Critical, High, Medium, Low."
  type        = string
  default     = "Critical"
}

variable "data_classification" {
  description = "Data classification: Public, Internal, Confidential, Restricted."
  type        = string
  default     = "Internal"
}

variable "project" {
  description = "Project name for F03 tags."
  type        = string
  default     = "Azure-Landing-Zone"
}

variable "department" {
  description = "Department for F03 tags."
  type        = string
  default     = null
}

#-------------------------------------------------------------------------------
# MODULE DEPLOYMENT FLAGS
#-------------------------------------------------------------------------------

variable "deploy_m01_log_analytics" {
  description = "Deploy M01 Log Analytics Workspace."
  type        = bool
  default     = true
}

variable "deploy_m02_automation" {
  description = "Deploy M02 Automation Account. Requires M01."
  type        = bool
  default     = false
}

variable "deploy_m03_action_groups" {
  description = "Deploy M03 Action Groups."
  type        = bool
  default     = false
}


variable "deploy_m06_update_management" {
  description = "Deploy M06 Update Management."
  type        = bool
  default     = false
}

variable "deploy_m07_dcr" {
  description = "Deploy M07 Data Collection Rules."
  type        = bool
  default     = false
}

variable "deploy_m08_diagnostics_storage" {
  description = "Deploy M08 Diagnostics Storage Account."
  type        = bool
  default     = false
}

#-------------------------------------------------------------------------------
# M01 - LOG ANALYTICS CONFIGURATION
#-------------------------------------------------------------------------------

variable "log_analytics_custom_name" {
  description = "Custom name for Log Analytics workspace. Auto-generated via F02 if not provided."
  type        = string
  default     = null
}

variable "log_analytics_retention_days" {
  description = "Interactive retention in days (30-730)."
  type        = number
  default     = 90
}

variable "log_analytics_total_retention_days" {
  description = "Total retention including archive."
  type        = number
  default     = 400
}

variable "log_analytics_sku" {
  description = "Log Analytics SKU."
  type        = string
  default     = "PerGB2018"
}

variable "enable_log_analytics_dr" {
  description = "Create secondary workspace in DR region."
  type        = bool
  default     = false
}

#-------------------------------------------------------------------------------
# M02 - AUTOMATION ACCOUNT CONFIGURATION
#-------------------------------------------------------------------------------

variable "automation_custom_name" {
  description = "Custom name for Automation Account. Auto-generated via F02 if not provided."
  type        = string
  default     = null
}

variable "automation_public_access" {
  description = "Allow public network access to Automation Account."
  type        = bool
  default     = true
}

variable "deploy_default_runbooks" {
  description = "Deploy default platform runbooks."
  type        = bool
  default     = true
}

variable "deploy_default_schedules" {
  description = "Deploy default schedules."
  type        = bool
  default     = true
}

#-------------------------------------------------------------------------------
# M03 - ACTION GROUPS CONFIGURATION
# À ajouter dans orchestrator-lza-mng/variables.tf après les variables M02
#-------------------------------------------------------------------------------

variable "action_groups_custom_name" {
  description = "Custom name for Action Groups base name. Auto-generated via F02 if not provided."
  type        = string
  default     = null
}

variable "create_default_action_groups" {
  description = "Create default action groups (Critical, Warning, Info)."
  type        = bool
  default     = true
}

variable "default_email_receivers" {
  description = "Default email receivers for built-in action groups."
  type = list(object({
    name          = string
    email_address = string
  }))
  default = []
}

variable "default_webhook_url" {
  description = "Default webhook URL for action groups (e.g., Teams, Slack)."
  type        = string
  default     = null
}

variable "custom_action_groups" {
  description = "Map of custom action groups to create in addition to defaults."
  type = map(object({
    short_name = string
    enabled    = optional(bool, true)

    email_receivers = optional(list(object({
      name                    = string
      email_address           = string
      use_common_alert_schema = optional(bool, true)
    })), [])

    sms_receivers = optional(list(object({
      name         = string
      country_code = string
      phone_number = string
    })), [])

    webhook_receivers = optional(list(object({
      name                    = string
      service_uri             = string
      use_common_alert_schema = optional(bool, true)
      aad_auth = optional(object({
        object_id      = string
        identifier_uri = optional(string)
        tenant_id      = optional(string)
      }))
    })), [])

    azure_function_receivers = optional(list(object({
      name                     = string
      function_app_resource_id = string
      function_name            = string
      http_trigger_url         = string
      use_common_alert_schema  = optional(bool, true)
    })), [])

    logic_app_receivers = optional(list(object({
      name                    = string
      resource_id             = string
      callback_url            = string
      use_common_alert_schema = optional(bool, true)
    })), [])

    automation_runbook_receivers = optional(list(object({
      name                    = string
      automation_account_id   = string
      runbook_name            = string
      webhook_resource_id     = string
      is_global_runbook       = optional(bool, false)
      service_uri             = string
      use_common_alert_schema = optional(bool, true)
    })), [])

    voice_receivers = optional(list(object({
      name         = string
      country_code = string
      phone_number = string
    })), [])

    arm_role_receivers = optional(list(object({
      name                    = string
      role_id                 = string
      use_common_alert_schema = optional(bool, true)
    })), [])

    event_hub_receivers = optional(list(object({
      name                    = string
      event_hub_namespace     = optional(string)
      event_hub_name          = optional(string)
      subscription_id         = optional(string)
      tenant_id               = optional(string)
      use_common_alert_schema = optional(bool, true)
    })), [])

    itsm_receivers = optional(list(object({
      name                 = string
      workspace_id         = string
      connection_id        = string
      ticket_configuration = string
      region               = string
    })), [])
  }))
  default = {}
}

#-------------------------------------------------------------------------------
# M04 - MONITOR ALERTS CONFIGURATION
# À ajouter dans orchestrator-lza-mng/variables.tf après la section M03
#-------------------------------------------------------------------------------

variable "deploy_m04_alerts" {
  description = "Deploy M04 Monitor Alerts module. Requires M01 and M03 to be deployed."
  type        = bool
  default     = false
}

variable "alerts_custom_name_prefix" {
  description = "Custom name prefix for alerts. Auto-generated via F02 if not provided."
  type        = string
  default     = null
}

variable "create_default_alerts" {
  description = "Create default platform alerts (Service Health, Resource Health, Activity Log)."
  type        = bool
  default     = true
}


#===============================================================================
# M06 - UPDATE MANAGEMENT CONFIGURATION
#===============================================================================

variable "update_management_custom_name_prefix" {
  description = "Custom name prefix for M06 (bypasses F02 if set)."
  type        = string
  default     = null
}

variable "create_default_windows_config" {
  description = "Create default Windows Maintenance Configuration."
  type        = bool
  default     = false
}

variable "create_default_linux_config" {
  description = "Create default Linux Maintenance Configuration."
  type        = bool
  default     = false
}

variable "default_timezone" {
  description = "Default timezone for maintenance windows."
  type        = string
  default     = "UTC"
}

variable "update_target_locations" {
  description = "Default Azure regions to target for updates."
  type        = list(string)
  default     = []
}

variable "maintenance_configurations" {
  description = "Map of custom Maintenance Configurations."
  type        = any
  default     = {}
}

variable "vm_assignments" {
  description = "Map of static VM assignments."
  type        = any
  default     = {}
}

variable "dynamic_scope_assignments" {
  description = "Map of dynamic scope assignments."
  type        = any
  default     = {}
}

variable "update_management_additional_tags" {
  description = "Additional tags for Update Management resources."
  type        = map(string)
  default     = {}
}

# ============================================================================
# DIAGNOSTIC SETTINGS (Optional)
# ============================================================================

variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings for management resources"
  type        = bool
  default     = true
}

variable "diagnostic_settings_config" {
  description = "Configuration for diagnostic settings on management resources"
  type = object({
    
    storage_account_id             = optional(string)
    log_analytics_destination_type = optional(string, "Dedicated")
    logs_retention_days            = optional(number, 90)
    metrics_retention_days         = optional(number, 90)
  })
  default = null
}



#-------------------------------------------------------------------------------
# Service Health Alert Configuration
#-------------------------------------------------------------------------------

variable "service_health_alert_config" {
  description = "Configuration for Service Health alerts."
  type = object({
    enabled     = optional(bool, true)
    name        = optional(string, "Service Health Alert")
    description = optional(string, "Alert for Azure service health incidents and maintenance")
    event_types = optional(list(string), ["Incident", "Maintenance"])
    regions     = optional(list(string), ["Australia East", "Australia Southeast", "Global"])
    services    = optional(list(string), [])
    severity    = optional(string, "critical")
  })
  default = {}
}

#-------------------------------------------------------------------------------
# Resource Health Alert Configuration
#-------------------------------------------------------------------------------

variable "resource_health_alert_config" {
  description = "Configuration for Resource Health alerts."
  type = object({
    enabled         = optional(bool, true)
    name            = optional(string, "Resource Health Alert")
    description     = optional(string, "Alert for Azure resource health degradation")
    current_states  = optional(list(string), ["Degraded", "Unavailable"])
    previous_states = optional(list(string), ["Available"])
    reason_types    = optional(list(string), ["PlatformInitiated", "Unknown"])
    severity        = optional(string, "warning")
  })
  default = {}
}

#-------------------------------------------------------------------------------
# Activity Log Administrative Alert Configuration
#-------------------------------------------------------------------------------

variable "activity_log_admin_alert_config" {
  description = "Configuration for Activity Log Administrative alerts (delete operations)."
  type = object({
    enabled     = optional(bool, true)
    name        = optional(string, "Critical Resource Deletion Alert")
    description = optional(string, "Alert for delete operations on critical resources")
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

#-------------------------------------------------------------------------------
# Activity Log Security Alert Configuration
#-------------------------------------------------------------------------------

variable "activity_log_security_alert_config" {
  description = "Configuration for Activity Log Security alerts (policy violations)."
  type = object({
    enabled     = optional(bool, true)
    name        = optional(string, "Security Policy Violation Alert")
    description = optional(string, "Alert for security-related events and policy violations")
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

#-------------------------------------------------------------------------------
# Custom Activity Log Alerts
#-------------------------------------------------------------------------------

variable "custom_activity_log_alerts" {
  description = "Map of custom Activity Log alerts to create."
  type = map(object({
    description    = optional(string, "Custom Activity Log Alert")
    enabled        = optional(bool, true)
    scopes         = optional(list(string), [])
    operation_name = optional(string, null)
    category       = optional(string, "Administrative")
    level          = optional(string, null)
    status         = optional(string, null)
    severity       = optional(string, "warning")
  }))
  default = {}
}

#-------------------------------------------------------------------------------
# Custom Metric Alerts
#-------------------------------------------------------------------------------

variable "custom_metric_alerts" {
  description = "Map of custom metric alerts to create. Scopes should reference module outputs."
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
      metric_namespace        = string
      metric_name             = string
      aggregation             = string
      operator                = string
      threshold               = number
      skip_metric_validation  = optional(bool, false)
      dimension = optional(list(object({
        name     = string
        operator = string
        values   = list(string)
      })), [])
    }))
    dynamic_criteria = optional(list(object({
      metric_namespace          = string
      metric_name               = string
      aggregation               = string
      operator                  = string
      alert_sensitivity         = string
      evaluation_total_count    = optional(number, 4)
      evaluation_failure_count  = optional(number, 4)
      ignore_data_before        = optional(string, null)
      skip_metric_validation    = optional(bool, false)
    })), [])
    severity = optional(string, "warning")
  }))
  default = {}
}

#-------------------------------------------------------------------------------
# Custom Log Query Alerts
#-------------------------------------------------------------------------------

variable "custom_log_query_alerts" {
  description = "Map of custom Log Analytics query alerts to create."
  type = map(object({
    description              = optional(string, "Custom Log Query Alert")
    enabled                  = optional(bool, true)
    location                 = optional(string, "australiaeast")
    scopes                   = list(string)
    severity_level           = optional(number, 2)
    evaluation_frequency     = optional(string, "PT5M")
    window_duration          = optional(string, "PT15M")
    query                    = string
    threshold                = optional(number, 0)
    operator                 = optional(string, "GreaterThan")
    time_aggregation_method  = optional(string, "Count")
    metric_measure_column    = optional(string, null)
    resource_id_column       = optional(string, null)
    auto_mitigation_enabled  = optional(bool, true)
    skip_query_validation    = optional(bool, false)
    failing_periods = optional(object({
      minimum_failing_periods_to_trigger_alert = number
      number_of_evaluation_periods             = number
    }), null)
    severity = optional(string, "warning")
  }))
  default = {}
}

#-------------------------------------------------------------------------------
# Severity to Action Group Mapping
#-------------------------------------------------------------------------------

variable "severity_action_group_mapping" {
  description = "Custom mapping of severity levels to action group keys from M03."
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

