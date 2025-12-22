################################################################################
# variables.tf - M02 Automation Account Module
# Input Variables
################################################################################

#-------------------------------------------------------------------------------
# REQUIRED VARIABLES - Naming (F02)
#-------------------------------------------------------------------------------

variable "workload" {
  description = "Workload name for resource naming via F02 module (e.g., 'platform', 'automation')."
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
  description = "Name of the resource group where the Automation Account will be created."
  type        = string
}

variable "location" {
  description = "Azure region for the Automation Account. Should match Log Analytics for linking."
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
  description = "Custom name for Automation Account (bypasses F02 naming). Use sparingly for legacy resources."
  type        = string
  default     = null
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Log Analytics Integration
#-------------------------------------------------------------------------------

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace to link for Update Management and Change Tracking."
  type        = string
  default     = null

  validation {
    condition     = var.log_analytics_workspace_id == null || can(regex("^/subscriptions/[a-f0-9-]+/resourceGroups/[^/]+/providers/Microsoft.OperationalInsights/workspaces/[^/]+$", var.log_analytics_workspace_id))
    error_message = "Log Analytics workspace ID must be a valid Azure resource ID."
  }
}

variable "create_la_linked_service" {
  description = "Create the linked service between Automation Account and Log Analytics workspace."
  type        = bool
  default     = true
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - SKU and Identity
#-------------------------------------------------------------------------------

variable "sku_name" {
  description = "SKU of the Automation Account. Only 'Basic' is currently supported by Azure."
  type        = string
  default     = "Basic"

  validation {
    condition     = var.sku_name == "Basic"
    error_message = "Only 'Basic' SKU is currently supported for Automation Accounts."
  }
}

variable "public_network_access_enabled" {
  description = "Allow public network access to the Automation Account. Set to false for private-only."
  type        = bool
  default     = true
}

variable "local_authentication_enabled" {
  description = "Enable local authentication (shared keys). Disable for zero-trust environments."
  type        = bool
  default     = true
}

variable "identity_type" {
  description = "Type of managed identity: 'SystemAssigned', 'UserAssigned', or 'SystemAssigned, UserAssigned'."
  type        = string
  default     = "SystemAssigned"

  validation {
    condition     = contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type)
    error_message = "Identity type must be 'SystemAssigned', 'UserAssigned', or 'SystemAssigned, UserAssigned'."
  }
}

variable "identity_ids" {
  description = "List of User Assigned Managed Identity IDs. Required if identity_type includes 'UserAssigned'."
  type        = list(string)
  default     = []
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Runbooks
#-------------------------------------------------------------------------------

variable "runbooks" {
  description = "Map of PowerShell or Python runbooks to create."
  type = map(object({
    runbook_type = string
    description  = optional(string)
    content      = optional(string)
    uri          = optional(string)
    version      = optional(string)
    hash_value   = optional(string)
    tags         = optional(map(string))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.runbooks : contains(["PowerShell", "PowerShell72", "Python3", "Graph", "PowerShellWorkflow"], v.runbook_type)
    ])
    error_message = "Runbook type must be PowerShell, PowerShell72, Python3, Graph, or PowerShellWorkflow."
  }
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Schedules
#-------------------------------------------------------------------------------

variable "schedules" {
  description = "Map of schedules for runbook automation."
  type = map(object({
    description = optional(string)
    start_time  = string
    frequency   = string
    interval    = optional(number, 1)
    timezone    = optional(string, "UTC")
    week_days   = optional(list(string))
    month_days  = optional(list(number))
    expiry_time = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.schedules : contains(["OneTime", "Day", "Hour", "Week", "Month"], v.frequency)
    ])
    error_message = "Schedule frequency must be OneTime, Day, Hour, Week, or Month."
  }
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Credentials
#-------------------------------------------------------------------------------

variable "credentials" {
  description = "Map of credentials to store securely in the Automation Account."
  type = map(object({
    username    = string
    password    = string
    description = optional(string)
  }))
  default   = {}
  sensitive = true
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Variables
#-------------------------------------------------------------------------------

variable "variables_string" {
  description = "Map of string variables to store in the Automation Account."
  type = map(object({
    value       = string
    encrypted   = optional(bool, false)
    description = optional(string)
  }))
  default = {}
}

variable "variables_int" {
  description = "Map of integer variables to store in the Automation Account."
  type = map(object({
    value       = number
    encrypted   = optional(bool, false)
    description = optional(string)
  }))
  default = {}
}

variable "variables_bool" {
  description = "Map of boolean variables to store in the Automation Account."
  type = map(object({
    value       = bool
    encrypted   = optional(bool, false)
    description = optional(string)
  }))
  default = {}
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Modules
#-------------------------------------------------------------------------------

variable "powershell_modules" {
  description = "Map of PowerShell modules to import from PowerShell Gallery."
  type = map(object({
    uri     = string
    version = optional(string)
  }))
  default = {}
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - DSC Configuration
#-------------------------------------------------------------------------------

variable "dsc_configurations" {
  description = "Map of DSC configurations to import."
  type = map(object({
    content_embedded = string
    description      = optional(string)
  }))
  default = {}
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Webhooks
#-------------------------------------------------------------------------------

variable "webhooks" {
  description = "Map of webhooks for runbook triggering."
  type = map(object({
    runbook_name        = string
    expiry_time         = string
    enabled             = optional(bool, true)
    parameters          = optional(map(string))
    run_on_worker_group = optional(string)
  }))
  default   = {}
  sensitive = true
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Diagnostic Settings
#-------------------------------------------------------------------------------

variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings for the Automation Account."
  type        = bool
  default     = true
}

variable "diagnostic_storage_account_id" {
  description = "Storage account ID for diagnostic logs archival."
  type        = string
  default     = null
}

variable "diagnostic_log_categories" {
  description = "Log categories to enable for diagnostics."
  type        = list(string)
  default     = ["JobLogs", "JobStreams", "DscNodeStatus", "AuditEvent"]
}

variable "diagnostic_metric_categories" {
  description = "Metric categories to enable for diagnostics."
  type        = list(string)
  default     = ["AllMetrics"]
}
