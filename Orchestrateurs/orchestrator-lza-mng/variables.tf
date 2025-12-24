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

variable "deploy_m04_alerts" {
  description = "Deploy M04 Alerts."
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
