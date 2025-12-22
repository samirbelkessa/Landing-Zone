################################################################################
# variables.tf - M01 Log Analytics Workspace Module
# Input Variables with F02 Naming and F03 Tags Integration
################################################################################

#-------------------------------------------------------------------------------
# REQUIRED VARIABLES - Naming (F02)
#-------------------------------------------------------------------------------

variable "workload" {
  description = "Workload name for resource naming via F02 module (e.g., 'platform', 'management')."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.workload)) && length(var.workload) >= 2 && length(var.workload) <= 30
    error_message = "Workload must be 2-30 characters, lowercase alphanumeric with optional hyphens."
  }
}

variable "environment" {
  description = "Environment for naming and tagging. Valid: prod, nonprod, dev, test, uat, stg, sandbox."
  type        = string

  validation {
    condition     = contains(["prod", "nonprod", "dev", "test", "uat", "stg", "sandbox"], var.environment)
    error_message = "Environment must be one of: prod, nonprod, dev, test, uat, stg, sandbox."
  }
}

variable "region" {
  description = "Azure region abbreviation for naming (e.g., 'aue' for Australia East)."
  type        = string
  default     = "aue"

  validation {
    condition     = can(regex("^[a-z]{2,6}$", var.region))
    error_message = "Region must be 2-6 lowercase letters."
  }
}

variable "instance" {
  description = "Instance number for multiple resources (e.g., '001')."
  type        = string
  default     = "001"
}

#-------------------------------------------------------------------------------
# REQUIRED VARIABLES - Resource Placement
#-------------------------------------------------------------------------------

variable "resource_group_name" {
  description = "Name of the resource group where the workspace will be created."
  type        = string
}

variable "location" {
  description = "Azure region for the workspace (e.g., 'australiaeast')."
  type        = string

  validation {
    condition     = contains(["australiaeast", "australiasoutheast", "westeurope", "northeurope", "eastus", "westus2"], var.location)
    error_message = "Location must be a valid Azure region."
  }
}

#-------------------------------------------------------------------------------
# REQUIRED VARIABLES - Tags (F03)
#-------------------------------------------------------------------------------

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
    condition     = length(var.cost_center) >= 3 && length(var.cost_center) <= 20
    error_message = "Cost center must be between 3 and 20 characters."
  }
}

variable "application" {
  description = "Application name for tagging (required for F03 tags)."
  type        = string

  validation {
    condition     = length(var.application) >= 2 && length(var.application) <= 50
    error_message = "Application name must be between 2 and 50 characters."
  }
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Tags (F03)
#-------------------------------------------------------------------------------

variable "criticality" {
  description = "Business criticality level for F03 tags."
  type        = string
  default     = "Critical"

  validation {
    condition     = contains(["Critical", "High", "Medium", "Low"], var.criticality)
    error_message = "Criticality must be one of: Critical, High, Medium, Low."
  }
}

variable "data_classification" {
  description = "Data classification for F03 tags."
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

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Custom Name Override
#-------------------------------------------------------------------------------

variable "custom_name" {
  description = "Custom name for workspace (bypasses F02 naming). Use sparingly for legacy resources."
  type        = string
  default     = null

  validation {
    condition     = var.custom_name == null || can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{2,61}[a-zA-Z0-9]$", var.custom_name))
    error_message = "Workspace name must be 4-63 characters, alphanumeric and hyphens only."
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
  description = "Total retention period including archive (90-2556 days / ~7 years)."
  type        = number
  default     = 400

  validation {
    condition     = var.total_retention_in_days >= 90 && var.total_retention_in_days <= 2556
    error_message = "Total retention must be between 90 and 2556 days (~7 years)."
  }
}

variable "enable_table_level_archive" {
  description = "Enable archive configuration at table level for specific tables."
  type        = bool
  default     = true
}

variable "archive_tables" {
  description = "Map of tables to configure with specific archive retention."
  type        = map(number)
  default = {
    "SecurityEvent" = 400
    "Syslog"        = 400
    "AzureActivity" = 400
    "SigninLogs"    = 400
    "AuditLogs"     = 400
    "Perf"          = 180
    "AzureMetrics"  = 180
  }
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - SKU and Capacity
#-------------------------------------------------------------------------------

variable "sku" {
  description = "SKU of the workspace: PerGB2018 or CapacityReservation."
  type        = string
  default     = "PerGB2018"

  validation {
    condition     = contains(["PerGB2018", "CapacityReservation"], var.sku)
    error_message = "SKU must be either 'PerGB2018' or 'CapacityReservation'."
  }
}

variable "reservation_capacity_in_gb_per_day" {
  description = "Capacity reservation in GB/day. Only used when SKU is CapacityReservation."
  type        = number
  default     = null

  validation {
    condition     = var.reservation_capacity_in_gb_per_day == null || contains([100, 200, 300, 400, 500, 1000, 2000, 5000], var.reservation_capacity_in_gb_per_day)
    error_message = "Capacity reservation must be one of: 100, 200, 300, 400, 500, 1000, 2000, 5000 GB/day."
  }
}

variable "daily_quota_gb" {
  description = "Daily ingestion quota in GB. -1 for unlimited."
  type        = number
  default     = -1

  validation {
    condition     = var.daily_quota_gb == -1 || var.daily_quota_gb >= 1
    error_message = "Daily quota must be -1 (unlimited) or >= 1 GB."
  }
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Network Access
#-------------------------------------------------------------------------------

variable "internet_ingestion_enabled" {
  description = "Allow data ingestion from public internet."
  type        = bool
  default     = true
}

variable "internet_query_enabled" {
  description = "Allow queries from public internet."
  type        = bool
  default     = true
}

variable "local_authentication_disabled" {
  description = "Disable local authentication (shared keys). When true, only AAD auth is allowed."
  type        = bool
  default     = false
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
  description = "List of solutions to deploy."
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
    { name = "ServiceMap", publisher = "Microsoft" },
    { name = "AgentHealthAssessment", publisher = "Microsoft" },
  ]
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Cross-Region DR
#-------------------------------------------------------------------------------

variable "enable_cross_region_workspace" {
  description = "Create a secondary workspace in DR region."
  type        = bool
  default     = false
}

variable "secondary_location" {
  description = "Secondary region for DR workspace."
  type        = string
  default     = "australiasoutheast"
}

variable "secondary_retention_in_days" {
  description = "Retention for secondary workspace (can be lower for cost optimization)."
  type        = number
  default     = 30
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Diagnostic Settings
#-------------------------------------------------------------------------------

variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings for the workspace itself."
  type        = bool
  default     = true
}

variable "diagnostic_storage_account_id" {
  description = "Storage account ID for diagnostic logs archival."
  type        = string
  default     = null
}

variable "diagnostic_categories" {
  description = "Categories of logs to capture in diagnostic settings."
  type        = list(string)
  default     = ["Audit", "SummaryLogs"]
}
