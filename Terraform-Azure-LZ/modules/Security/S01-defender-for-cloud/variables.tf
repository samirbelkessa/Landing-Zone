# =============================================================================
# VARIABLES.TF - Input Variables
# =============================================================================
# Module: S01-defender-for-cloud
# Purpose: Microsoft Defender for Cloud deployment
# =============================================================================

# =============================================================================
# REQUIRED VARIABLES
# =============================================================================

variable "security_contact_email" {
  description = "Email address for security alerts notifications."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.security_contact_email))
    error_message = "Must be a valid email address."
  }
}

variable "security_contact_phone" {
  description = "Phone number for security alerts notifications."
  type        = string
  default     = null
}

# =============================================================================
# LOG ANALYTICS CONFIGURATION
# =============================================================================

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace for Defender data export."
  type        = string

  validation {
    condition     = can(regex("^/subscriptions/[a-f0-9-]+/resourceGroups/[^/]+/providers/Microsoft.OperationalInsights/workspaces/[^/]+$", var.log_analytics_workspace_id))
    error_message = "Must be a valid Log Analytics Workspace resource ID."
  }
}

# =============================================================================
# DEFENDER PLANS CONFIGURATION
# =============================================================================

variable "defender_plans" {
  description = <<-EOT
    Map of Defender plans to enable with their configuration.
    
    Supported plans:
    - VirtualMachines: Server protection (P1 = basic, P2 = with EDR)
    - StorageAccounts: Storage threat protection
    - SqlServers: SQL Server protection
    - SqlServerVirtualMachines: SQL on VMs
    - AppServices: App Service protection
    - KeyVaults: Key Vault protection
    - Arm: Azure Resource Manager protection
    - Dns: DNS protection
    - Containers: Container protection
    - OpenSourceRelationalDatabases: OSS databases protection
    - CosmosDbs: Cosmos DB protection
    - CloudPosture: CSPM features
  EOT
  type = map(object({
    enabled = bool
    subplan = optional(string, null)
  }))
  default = {
    VirtualMachines = {
      enabled = true
      subplan = "P2" # P1 = basic, P2 = with EDR (MDE integration)
    }
    StorageAccounts = {
      enabled = true
      subplan = "DefenderForStorageV2"
    }
    SqlServers = {
      enabled = true
      subplan = null
    }
    SqlServerVirtualMachines = {
      enabled = true
      subplan = null
    }
    AppServices = {
      enabled = true
      subplan = null
    }
    KeyVaults = {
      enabled = true
      subplan = null
    }
    Arm = {
      enabled = true
      subplan = "PerApiCall"
    }
    Dns = {
      enabled = true
      subplan = null
    }
    Containers = {
      enabled = true
      subplan = null
    }
    OpenSourceRelationalDatabases = {
      enabled = false
      subplan = null
    }
    CosmosDbs = {
      enabled = false
      subplan = null
    }
    CloudPosture = {
      enabled = true
      subplan = null
    }
  }
}

# =============================================================================
# AUTO-PROVISIONING CONFIGURATION
# =============================================================================

variable "enable_auto_provisioning" {
  description = "Enable auto-provisioning of the Log Analytics agent on VMs."
  type        = bool
  default     = true
}

variable "auto_provisioning_identity_type" {
  description = "Identity type for auto-provisioning. Possible values: SystemAssigned, UserAssigned."
  type        = string
  default     = "SystemAssigned"

  validation {
    condition     = contains(["SystemAssigned", "UserAssigned"], var.auto_provisioning_identity_type)
    error_message = "Must be SystemAssigned or UserAssigned."
  }
}

# =============================================================================
# SECURITY ALERTS CONFIGURATION
# =============================================================================

variable "alert_notifications_state" {
  description = "Enable email notifications for security alerts."
  type        = string
  default     = "On"

  validation {
    condition     = contains(["On", "Off"], var.alert_notifications_state)
    error_message = "Must be On or Off."
  }
}

variable "alert_notifications_min_severity" {
  description = "Minimum severity level for alert notifications."
  type        = string
  default     = "Medium"

  validation {
    condition     = contains(["Low", "Medium", "High"], var.alert_notifications_min_severity)
    error_message = "Must be Low, Medium, or High."
  }
}

variable "alerts_to_admins_state" {
  description = "Send security alerts to subscription admins."
  type        = string
  default     = "On"

  validation {
    condition     = contains(["On", "Off"], var.alerts_to_admins_state)
    error_message = "Must be On or Off."
  }
}

# =============================================================================
# OPTIONAL VARIABLES
# =============================================================================

variable "tags" {
  description = "Tags to apply to resources that support tagging."
  type        = map(string)
  default     = {}
}
