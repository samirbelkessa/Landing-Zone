################################################################################
# Variables - Management Layer Orchestrator
# Common variables used across M01-M08 modules
################################################################################

#-------------------------------------------------------------------------------
# REQUIRED - Core Configuration
#-------------------------------------------------------------------------------

variable "project_name" {
  description = "Project name used for resource naming. Example: 'platform', 'acme'."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{2,20}$", var.project_name))
    error_message = "Project name must be 2-20 lowercase alphanumeric characters or hyphens."
  }
}

variable "environment" {
  description = "Environment name. Used for naming and tagging."
  type        = string

  validation {
    condition     = contains(["prod", "nonprod", "dev", "test", "sandbox"], var.environment)
    error_message = "Environment must be one of: prod, nonprod, dev, test, sandbox."
  }
}

variable "primary_location" {
  description = "Primary Azure region for deployment."
  type        = string
  default     = "australiaeast"
}

variable "secondary_location" {
  description = "Secondary Azure region for DR resources."
  type        = string
  default     = "australiasoutheast"
}

#-------------------------------------------------------------------------------
# REQUIRED - Resource Group
#-------------------------------------------------------------------------------

variable "resource_group_name" {
  description = "Name of the resource group for Management resources. Must exist."
  type        = string
}

variable "create_resource_group" {
  description = "Create the resource group if it doesn't exist."
  type        = bool
  default     = true
}

#-------------------------------------------------------------------------------
# OPTIONAL - Module Enablement Flags
#-------------------------------------------------------------------------------

variable "deploy_m01_log_analytics" {
  description = "Deploy M01 - Log Analytics Workspace."
  type        = bool
  default     = true
}

variable "deploy_m02_automation" {
  description = "Deploy M02 - Automation Account (requires M01)."
  type        = bool
  default     = false  # Enable after M01 is tested
}

variable "deploy_m03_action_groups" {
  description = "Deploy M03 - Monitor Action Groups (requires M01)."
  type        = bool
  default     = false  # Enable after M01 is tested
}

variable "deploy_m04_alerts" {
  description = "Deploy M04 - Monitor Alerts (requires M01, M03)."
  type        = bool
  default     = false  # Enable after M03 is tested
}

variable "deploy_m05_diagnostic_settings" {
  description = "Deploy M05 - Diagnostic Settings module."
  type        = bool
  default     = false  # Enable after M01 is tested
}

variable "deploy_m06_update_management" {
  description = "Deploy M06 - Update Management (requires M01, M02)."
  type        = bool
  default     = false  # Enable after M02 is tested
}

variable "deploy_m07_dcr" {
  description = "Deploy M07 - Data Collection Rules (requires M01)."
  type        = bool
  default     = false  # Enable after M01 is tested
}

variable "deploy_m08_diagnostics_storage" {
  description = "Deploy M08 - Diagnostics Storage Account."
  type        = bool
  default     = false  # Enable after M01 is tested
}

#-------------------------------------------------------------------------------
# M01 - Log Analytics Configuration
#-------------------------------------------------------------------------------

variable "log_analytics_name" {
  description = "Name of the Log Analytics workspace. If null, auto-generated from project_name."
  type        = string
  default     = null
}

variable "log_analytics_sku" {
  description = "SKU for Log Analytics workspace."
  type        = string
  default     = "PerGB2018"
}

variable "log_analytics_retention_days" {
  description = "Interactive retention period in days."
  type        = number
  default     = 90
}

variable "log_analytics_total_retention_days" {
  description = "Total retention including archive (for 1.1 years, use 400)."
  type        = number
  default     = 400
}

variable "log_analytics_daily_quota_gb" {
  description = "Daily ingestion quota in GB. -1 for unlimited."
  type        = number
  default     = -1
}

variable "log_analytics_solutions" {
  description = "List of Log Analytics solutions to deploy."
  type = list(object({
    name      = string
    publisher = string
  }))
  default = [
    { name = "SecurityInsights", publisher = "Microsoft" },
    { name = "AzureActivity", publisher = "Microsoft" },
    { name = "VMInsights", publisher = "Microsoft" },
    { name = "Updates", publisher = "Microsoft" },
    { name = "ChangeTracking", publisher = "Microsoft" },
  ]
}

variable "log_analytics_archive_tables" {
  description = "Tables to configure with archive retention."
  type        = map(number)
  default = {
    "SecurityEvent"    = 400
    "Syslog"           = 400
    "AzureActivity"    = 400
    "SigninLogs"       = 400
    "AuditLogs"        = 400
    "Perf"             = 180
    "AzureMetrics"     = 180
  }
}

variable "enable_log_analytics_dr" {
  description = "Create secondary Log Analytics workspace in DR region."
  type        = bool
  default     = false
}

#-------------------------------------------------------------------------------
# OPTIONAL - Tags
#-------------------------------------------------------------------------------

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "owner" {
  description = "Owner email for tagging."
  type        = string
  default     = ""
}

variable "cost_center" {
  description = "Cost center code for tagging."
  type        = string
  default     = ""
}