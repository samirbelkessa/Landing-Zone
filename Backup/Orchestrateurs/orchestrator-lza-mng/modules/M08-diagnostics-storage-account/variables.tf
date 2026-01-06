################################################################################
# variables.tf - M08 Diagnostics Storage Account Module
# Input Variables with F02 Naming and F03 Tags Integration
################################################################################

#-------------------------------------------------------------------------------
# REQUIRED VARIABLES - Naming (F02)
#-------------------------------------------------------------------------------

variable "workload" {
  description = "Workload name for resource naming via F02 module (e.g., 'diag', 'platform')."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.workload)) && length(var.workload) >= 2 && length(var.workload) <= 15
    error_message = "Workload must be 2-15 characters, lowercase alphanumeric with optional hyphens."
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

  validation {
    condition     = can(regex("^[0-9]{3}$", var.instance))
    error_message = "Instance must be a 3-digit number (e.g., '001')."
  }
}

#-------------------------------------------------------------------------------
# REQUIRED VARIABLES - Resource Placement
#-------------------------------------------------------------------------------

variable "resource_group_name" {
  description = "Name of the resource group where the Storage Account will be created."
  type        = string
}

variable "location" {
  description = "Azure region for the Storage Account (e.g., 'australiaeast')."
  type        = string
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
  default     = "High"

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
  description = "Custom name for Storage Account (bypasses F02 naming). Storage account names must be 3-24 characters, lowercase alphanumeric only."
  type        = string
  default     = null

  validation {
    condition     = var.custom_name == null || can(regex("^[a-z0-9]{3,24}$", var.custom_name))
    error_message = "Storage Account name must be 3-24 characters, lowercase alphanumeric only (no hyphens or special characters)."
  }
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Storage Account Configuration
#-------------------------------------------------------------------------------

variable "account_tier" {
  description = "Storage Account tier. Standard is sufficient for diagnostics."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "Account tier must be Standard or Premium."
  }
}

variable "account_kind" {
  description = "Storage Account kind. StorageV2 recommended for diagnostics."
  type        = string
  default     = "StorageV2"

  validation {
    condition     = contains(["StorageV2", "BlobStorage", "Storage"], var.account_kind)
    error_message = "Account kind must be StorageV2, BlobStorage, or Storage."
  }
}

variable "access_tier" {
  description = "Default access tier for blobs. Hot recommended for active diagnostics."
  type        = string
  default     = "Hot"

  validation {
    condition     = contains(["Hot", "Cool"], var.access_tier)
    error_message = "Access tier must be Hot or Cool."
  }
}

variable "replication_type" {
  description = "Replication type. If null, automatically set based on environment (GRS for prod, LRS for non-prod)."
  type        = string
  default     = null

  validation {
    condition     = var.replication_type == null || contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.replication_type)
    error_message = "Replication type must be LRS, GRS, RAGRS, ZRS, GZRS, or RAGZRS."
  }
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Security Configuration
#-------------------------------------------------------------------------------

variable "min_tls_version" {
  description = "Minimum TLS version for the Storage Account."
  type        = string
  default     = "TLS1_2"

  validation {
    condition     = contains(["TLS1_0", "TLS1_1", "TLS1_2"], var.min_tls_version)
    error_message = "Min TLS version must be TLS1_0, TLS1_1, or TLS1_2."
  }
}

variable "https_traffic_only_enabled" {
  description = "Force HTTPS for all connections."
  type        = bool
  default     = true
}

variable "allow_nested_items_to_be_public" {
  description = "Allow public access to blobs within containers. Disabled for security."
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Enable public network access. Can be disabled when using Private Endpoints."
  type        = bool
  default     = true
}

variable "shared_access_key_enabled" {
  description = "Allow access using storage account keys. Disable for enhanced security (use Entra ID auth instead)."
  type        = bool
  default     = true
}

variable "default_to_oauth_authentication" {
  description = "Use Entra ID (OAuth) by default in the Azure Portal."
  type        = bool
  default     = true
}

variable "infrastructure_encryption_enabled" {
  description = "Enable double encryption at infrastructure level."
  type        = bool
  default     = false
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Network Rules
#-------------------------------------------------------------------------------

variable "network_rules" {
  description = "Network rules for the Storage Account. Set to null for no restrictions (default)."
  type = object({
    default_action             = optional(string, "Deny")
    bypass                     = optional(list(string), ["AzureServices", "Logging", "Metrics"])
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  default = null
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Containers Configuration
#-------------------------------------------------------------------------------

variable "create_default_containers" {
  description = "Create default diagnostic containers (bootdiagnostics, insights-logs, insights-metrics)."
  type        = bool
  default     = true
}

variable "additional_containers" {
  description = "Map of additional containers to create."
  type = map(object({
    container_access_type = optional(string, "private")
    metadata              = optional(map(string), {})
  }))
  default = {}
}

variable "default_container_access_type" {
  description = "Default access type for containers. Private is strongly recommended."
  type        = string
  default     = "private"

  validation {
    condition     = contains(["private", "blob", "container"], var.default_container_access_type)
    error_message = "Container access type must be private, blob, or container."
  }
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Lifecycle Management
#-------------------------------------------------------------------------------

variable "enable_lifecycle_management" {
  description = "Enable blob lifecycle management policies for automatic tiering and deletion."
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = "Custom lifecycle rules. If empty, default rules for diagnostic data will be used."
  type = map(object({
    enabled                            = optional(bool, true)
    prefix_match                       = optional(list(string), [])
    blob_types                         = optional(list(string), ["blockBlob"])
    tier_to_cool_after_days            = optional(number, 30)
    tier_to_archive_after_days         = optional(number, 90)
    delete_after_days                  = optional(number, 400)
    delete_snapshot_after_days         = optional(number, 90)
    tier_to_cold_after_days            = optional(number, null)
    auto_tier_to_hot_from_cool_enabled = optional(bool, false)
  }))
  default = {}
}

variable "default_lifecycle_tier_to_cool_days" {
  description = "Default days before tiering blobs from Hot to Cool tier."
  type        = number
  default     = 30

  validation {
    condition     = var.default_lifecycle_tier_to_cool_days >= 1 && var.default_lifecycle_tier_to_cool_days <= 365
    error_message = "Days must be between 1 and 365."
  }
}

variable "default_lifecycle_tier_to_archive_days" {
  description = "Default days before tiering blobs from Cool to Archive tier."
  type        = number
  default     = 90

  validation {
    condition     = var.default_lifecycle_tier_to_archive_days >= 1 && var.default_lifecycle_tier_to_archive_days <= 730
    error_message = "Days must be between 1 and 730."
  }
}

variable "default_lifecycle_delete_days" {
  description = "Default days before deleting blobs. 400 days = ~1.1 years (per client requirements)."
  type        = number
  default     = 400

  validation {
    condition     = var.default_lifecycle_delete_days >= 1 && var.default_lifecycle_delete_days <= 2555
    error_message = "Days must be between 1 and 2555 (~7 years)."
  }
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Blob Properties
#-------------------------------------------------------------------------------

variable "blob_soft_delete_retention_days" {
  description = "Days to retain deleted blobs. Set to 0 to disable."
  type        = number
  default     = 7

  validation {
    condition     = var.blob_soft_delete_retention_days >= 0 && var.blob_soft_delete_retention_days <= 365
    error_message = "Retention days must be between 0 and 365."
  }
}

variable "container_soft_delete_retention_days" {
  description = "Days to retain deleted containers. Set to 0 to disable."
  type        = number
  default     = 7

  validation {
    condition     = var.container_soft_delete_retention_days >= 0 && var.container_soft_delete_retention_days <= 365
    error_message = "Retention days must be between 0 and 365."
  }
}

variable "enable_versioning" {
  description = "Enable blob versioning. Recommended for production diagnostics storage."
  type        = bool
  default     = false
}

variable "enable_change_feed" {
  description = "Enable blob change feed for tracking changes."
  type        = bool
  default     = false
}

variable "change_feed_retention_in_days" {
  description = "Days to retain change feed data."
  type        = number
  default     = 7

  validation {
    condition     = var.change_feed_retention_in_days >= 1 && var.change_feed_retention_in_days <= 146000
    error_message = "Retention days must be between 1 and 146000."
  }
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Diagnostic Settings (Self-diagnostics)
#-------------------------------------------------------------------------------

variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings on the Storage Account itself."
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for diagnostics. Required if enable_diagnostic_settings is true."
  type        = string
  default     = null
}

variable "diagnostic_log_categories" {
  description = "Log categories to enable for Storage Account diagnostics."
  type        = list(string)
  default     = ["StorageRead", "StorageWrite", "StorageDelete"]
}

variable "diagnostic_metric_categories" {
  description = "Metric categories to enable for Storage Account diagnostics."
  type        = list(string)
  default     = ["Transaction", "Capacity"]
}

variable "diagnostic_logs_retention_days" {
  description = "Retention days for diagnostic logs (0 = unlimited)."
  type        = number
  default     = 90

  validation {
    condition     = var.diagnostic_logs_retention_days >= 0 && var.diagnostic_logs_retention_days <= 365
    error_message = "Retention days must be between 0 and 365."
  }
}
