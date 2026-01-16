# =============================================================================
# VARIABLES.TF - Input Variables
# =============================================================================
# Module: S02-sentinel
# Purpose: Microsoft Sentinel SIEM/SOAR deployment
# =============================================================================

# =============================================================================
# REQUIRED VARIABLES
# =============================================================================

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace to onboard Sentinel to."
  type        = string

  validation {
    condition     = can(regex("^/subscriptions/[a-f0-9-]+/resourceGroups/[^/]+/providers/Microsoft.OperationalInsights/workspaces/[^/]+$", var.log_analytics_workspace_id))
    error_message = "Must be a valid Log Analytics Workspace resource ID."
  }
}

variable "log_analytics_workspace_name" {
  description = "Name of the Log Analytics Workspace."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group containing the Log Analytics Workspace."
  type        = string
}

# =============================================================================
# DATA CONNECTORS CONFIGURATION
# =============================================================================

variable "data_connectors" {
  description = <<-EOT
    Map of data connectors to enable.
    
    IMPORTANT LICENSING NOTES:
    - azure_active_directory: Requires Azure AD Premium P1/P2 or Microsoft 365 E5
    - office_365: Requires Office 365 license
    - microsoft_365_defender: Requires Microsoft 365 E5 or Microsoft 365 E5 Security
    - azure_advanced_threat_protection: Requires Microsoft Defender for Identity license
    
    Without appropriate licenses, enabling these connectors will fail.
  EOT
  type = object({
    azure_active_directory       = optional(bool, false)
    azure_activity               = optional(bool, true)
    defender_for_cloud           = optional(bool, true)
    threat_intelligence          = optional(bool, true)
    microsoft_cloud_app_security = optional(bool, false)
    office_365                   = optional(bool, false)
    microsoft_365_defender       = optional(bool, false)
    azure_advanced_threat_protection = optional(bool, false)
  })
  default = {
    azure_active_directory       = false  # Requires license
    azure_activity               = true
    defender_for_cloud           = true
    threat_intelligence          = true
    microsoft_cloud_app_security = false  # Requires license
    office_365                   = false  # Requires license
    microsoft_365_defender       = false  # Requires license
    azure_advanced_threat_protection = false  # Requires license
  }
}

# =============================================================================
# ALERT RULES CONFIGURATION
# =============================================================================

variable "enable_default_alert_rules" {
  description = "Enable recommended Sentinel alert rules from templates."
  type        = bool
  default     = false
}

variable "alert_rule_templates" {
  description = <<-EOT
    List of alert rule template GUIDs to enable.
    Leave empty to skip alert rule creation.
    
    Example templates:
    - "5163A000-5160-5160-5160-5163A0000001" (example GUID)
  EOT
  type        = list(string)
  default     = []
}

# =============================================================================
# WATCHLIST CONFIGURATION
# =============================================================================

variable "watchlists" {
  description = <<-EOT
    Map of watchlists to create.
    
    Example:
    {
      high_value_assets = {
        display_name = "High Value Assets"
        description  = "List of critical business assets"
        item_search_key = "AssetName"
        source       = "Local"
      }
    }
  EOT
  type = map(object({
    display_name    = string
    description     = optional(string, "")
    item_search_key = string
    source          = optional(string, "Local")
    labels          = optional(list(string), [])
  }))
  default = {}
}

# =============================================================================
# AUTOMATION CONFIGURATION
# =============================================================================

variable "enable_ueba" {
  description = "Enable User and Entity Behavior Analytics (UEBA)."
  type        = bool
  default     = false
}

variable "ueba_data_sources" {
  description = "Data sources for UEBA. Possible values: AuditLogs, AzureActivity, SecurityEvent, SigninLogs."
  type        = list(string)
  default     = ["AuditLogs", "AzureActivity", "SigninLogs"]

  validation {
    condition     = alltrue([for source in var.ueba_data_sources : contains(["AuditLogs", "AzureActivity", "SecurityEvent", "SigninLogs"], source)])
    error_message = "UEBA data sources must be one of: AuditLogs, AzureActivity, SecurityEvent, SigninLogs."
  }
}

# =============================================================================
# OPTIONAL VARIABLES
# =============================================================================

variable "customer_managed_key_enabled" {
  description = "Enable customer managed key for Sentinel."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources that support tagging."
  type        = map(string)
  default     = {}
}
