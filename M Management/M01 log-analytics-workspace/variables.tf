################################################################################
# Variables - Log Analytics Workspace (M01)
################################################################################

#-------------------------------------------------------------------------------
# REQUIRED VARIABLES
#-------------------------------------------------------------------------------

variable "name" {
  description = "Name of the Log Analytics workspace. Must be globally unique."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{2,61}[a-zA-Z0-9]$", var.name))
    error_message = "Workspace name must be 4-63 characters, alphanumeric and hyphens only, cannot start/end with hyphen."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group where the workspace will be created."
  type        = string
}

variable "location" {
  description = "Azure region for the workspace. Primary region for Australia Landing Zone."
  type        = string

  validation {
    condition     = contains(["australiaeast", "australiasoutheast", "westeurope", "northeurope", "eastus", "westus2"], var.location)
    error_message = "Location must be a valid Azure region."
  }
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Retention Configuration
#-------------------------------------------------------------------------------

variable "retention_in_days" {
  description = "Interactive retention period in days (30-730). Data within this period is immediately queryable."
  type        = number
  default     = 90

  validation {
    condition     = var.retention_in_days >= 30 && var.retention_in_days <= 730
    error_message = "Retention must be between 30 and 730 days."
  }
}

variable "total_retention_in_days" {
  description = "Total retention period including archive (90-2556 days / ~7 years). Archive data requires restore to query."
  type        = number
  default     = 400 # ~1.1 years

  validation {
    condition     = var.total_retention_in_days >= 90 && var.total_retention_in_days <= 2556
    error_message = "Total retention must be between 90 and 2556 days (~7 years)."
  }
}

variable "enable_table_level_archive" {
  description = "Enable archive configuration at table level for specific tables (SecurityEvent, Syslog, etc.)."
  type        = bool
  default     = true
}

variable "archive_tables" {
  description = "Map of tables to configure with specific archive retention. Key is table name, value is total retention days."
  type        = map(number)
  default = {
    "SecurityEvent"     = 400
    "Syslog"            = 400
    "AzureActivity"     = 400
    "AzureDiagnostics"  = 400
    "Heartbeat"         = 400
    "Perf"              = 180
    "Event"             = 400
    "AzureMetrics"      = 180
    "SigninLogs"        = 400
    "AuditLogs"         = 400
  }
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - SKU and Capacity
#-------------------------------------------------------------------------------

variable "sku" {
  description = "SKU of the Log Analytics workspace. PerGB2018 is recommended for most scenarios."
  type        = string
  default     = "PerGB2018"

  validation {
    condition     = contains(["Free", "PerNode", "Premium", "Standard", "Standalone", "Unlimited", "CapacityReservation", "PerGB2018"], var.sku)
    error_message = "SKU must be one of: Free, PerNode, Premium, Standard, Standalone, Unlimited, CapacityReservation, PerGB2018."
  }
}

variable "reservation_capacity_in_gb_per_day" {
  description = "Capacity reservation in GB/day (100, 200, 300, 400, 500, 1000, 2000, 5000). Required when SKU is CapacityReservation."
  type        = number
  default     = null

  validation {
    condition     = var.reservation_capacity_in_gb_per_day == null || contains([100, 200, 300, 400, 500, 1000, 2000, 5000], var.reservation_capacity_in_gb_per_day)
    error_message = "Capacity reservation must be one of: 100, 200, 300, 400, 500, 1000, 2000, 5000 GB/day."
  }
}

variable "daily_quota_gb" {
  description = "Daily ingestion quota in GB. Set to -1 for no limit. Useful for cost control."
  type        = number
  default     = -1

  validation {
    condition     = var.daily_quota_gb == -1 || var.daily_quota_gb >= 0.023
    error_message = "Daily quota must be -1 (no limit) or >= 0.023 GB."
  }
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Network and Access
#-------------------------------------------------------------------------------

variable "internet_ingestion_enabled" {
  description = "Allow data ingestion over public internet. Set to false for private-only access."
  type        = bool
  default     = true
}

variable "internet_query_enabled" {
  description = "Allow queries over public internet. Set to false for private-only access."
  type        = bool
  default     = true
}

variable "local_authentication_disabled" {
  description = "Disable local authentication (shared keys). Recommended for zero-trust environments."
  type        = bool
  default     = false
}

variable "allow_resource_only_permissions" {
  description = "Allow resource-context access without workspace-level permissions."
  type        = bool
  default     = true
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Solutions
#-------------------------------------------------------------------------------

variable "deploy_solutions" {
  description = "Deploy Log Analytics solutions."
  type        = bool
  default     = true
}

variable "solutions" {
  description = "List of solutions to deploy. Each solution has name and publisher."
  type = list(object({
    name      = string
    publisher = string
  }))
  default = [
    { name = "SecurityInsights", publisher = "Microsoft" },      # Required for Sentinel
    { name = "AzureActivity", publisher = "Microsoft" },         # Azure Activity logs
    { name = "ChangeTracking", publisher = "Microsoft" },        # Change tracking
    { name = "Updates", publisher = "Microsoft" },               # Update management
    { name = "VMInsights", publisher = "Microsoft" },            # VM insights
    { name = "ServiceMap", publisher = "Microsoft" },            # Service dependency mapping
    { name = "AgentHealthAssessment", publisher = "Microsoft" }, # Agent health
  ]
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Linked Services
#-------------------------------------------------------------------------------

variable "link_automation_account" {
  description = "Link an Automation Account for Update Management, Change Tracking, etc."
  type        = bool
  default     = false
}

variable "automation_account_id" {
  description = "Resource ID of the Automation Account to link. Required if link_automation_account is true."
  type        = string
  default     = null

  validation {
    condition     = var.automation_account_id == null || can(regex("^/subscriptions/[a-f0-9-]+/resourceGroups/[^/]+/providers/Microsoft.Automation/automationAccounts/[^/]+$", var.automation_account_id))
    error_message = "Automation account ID must be a valid Azure resource ID."
  }
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Diagnostic Settings
#-------------------------------------------------------------------------------

variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings for the workspace itself (audit logs)."
  type        = bool
  default     = true
}

variable "diagnostic_storage_account_id" {
  description = "Storage account ID for diagnostic logs archival. If null, only workspace logging is used."
  type        = string
  default     = null
}

variable "diagnostic_categories" {
  description = "Categories of logs to capture in diagnostic settings."
  type        = list(string)
  default     = ["Audit", "SummaryLogs"]
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Cross-Region (DR)
#-------------------------------------------------------------------------------

variable "enable_cross_region_workspace" {
  description = "Create a secondary workspace in DR region for critical data replication."
  type        = bool
  default     = false
}

variable "secondary_location" {
  description = "Secondary region for DR workspace (e.g., australiasoutheast)."
  type        = string
  default     = "australiasoutheast"
}

variable "secondary_name_suffix" {
  description = "Suffix for secondary workspace name."
  type        = string
  default     = "-dr"
}

variable "secondary_retention_in_days" {
  description = "Retention for secondary workspace. Can be lower than primary for cost optimization."
  type        = number
  default     = 30
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Tags
#-------------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to all resources. Expected: Environment, Owner, CostCenter, Application."
  type        = map(string)
  default     = {}
}