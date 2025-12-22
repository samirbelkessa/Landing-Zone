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
