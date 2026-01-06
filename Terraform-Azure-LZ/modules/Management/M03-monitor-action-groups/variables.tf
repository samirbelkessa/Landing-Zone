# =============================================================================
# Variables - Module monitor-action-groups (M03)
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# REQUIRED VARIABLES - Naming (F02)
# ─────────────────────────────────────────────────────────────────────────────

variable "workload" {
  description = "Workload name for F02 naming convention (e.g., 'platform', 'monitoring')."
  type        = string

  validation {
    condition     = length(var.workload) >= 2 && length(var.workload) <= 30
    error_message = "Workload must be between 2 and 30 characters."
  }
}

variable "environment" {
  description = "Environment name: prod, nonprod, dev, test, sandbox."
  type        = string

  validation {
    condition     = contains(["prod", "nonprod", "dev", "test", "sandbox"], lower(var.environment))
    error_message = "Environment must be one of: prod, nonprod, dev, test, sandbox."
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# REQUIRED VARIABLES - Resource Placement
# ─────────────────────────────────────────────────────────────────────────────

variable "resource_group_name" {
  description = "Name of the Resource Group where Action Groups will be created."
  type        = string

  validation {
    condition     = length(var.resource_group_name) >= 1 && length(var.resource_group_name) <= 90
    error_message = "Resource group name must be between 1 and 90 characters."
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# REQUIRED VARIABLES - Tags (F03)
# ─────────────────────────────────────────────────────────────────────────────

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

# ─────────────────────────────────────────────────────────────────────────────
# OPTIONAL VARIABLES - Naming (F02)
# ─────────────────────────────────────────────────────────────────────────────

variable "region" {
  description = "Azure region abbreviation for F02 naming (e.g., 'aue' for Australia East)."
  type        = string
  default     = "aue"

  validation {
    condition     = length(var.region) >= 2 && length(var.region) <= 6
    error_message = "Region abbreviation must be between 2 and 6 characters."
  }
}

variable "instance" {
  description = "Instance number for F02 naming (e.g., '001')."
  type        = string
  default     = "001"

  validation {
    condition     = can(regex("^[0-9]{3}$", var.instance))
    error_message = "Instance must be a 3-digit number (e.g., '001')."
  }
}

variable "custom_name" {
  description = "Custom name override (bypasses F02 naming). Use sparingly for legacy resources."
  type        = string
  default     = null
}

# ─────────────────────────────────────────────────────────────────────────────
# OPTIONAL VARIABLES - Tags (F03)
# ─────────────────────────────────────────────────────────────────────────────

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

# ─────────────────────────────────────────────────────────────────────────────
# OPTIONAL VARIABLES - Action Groups Configuration
# ─────────────────────────────────────────────────────────────────────────────

variable "action_groups" {
  description = <<-EOT
    Map of Action Groups to create. Each action group supports multiple receiver types.
    
    Key: Unique identifier for the action group (used for naming suffix).
    Values:
      - short_name: Short name for Action Group (max 12 chars, used in SMS/alerts)
      - enabled: Whether the Action Group is enabled (default: true)
      - email_receivers: List of email receivers
      - sms_receivers: List of SMS receivers
      - webhook_receivers: List of webhook receivers
      - azure_function_receivers: List of Azure Function receivers
      - logic_app_receivers: List of Logic App receivers
      - automation_runbook_receivers: List of Automation Runbook receivers
      - voice_receivers: List of voice call receivers
      - arm_role_receivers: List of ARM Role receivers
      - event_hub_receivers: List of Event Hub receivers
      - itsm_receivers: List of ITSM receivers
  EOT
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

  validation {
    condition = alltrue([
      for k, v in var.action_groups : length(v.short_name) <= 12
    ])
    error_message = "Action Group short_name must be 12 characters or less."
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# OPTIONAL VARIABLES - Default Action Groups
# ─────────────────────────────────────────────────────────────────────────────

variable "create_default_action_groups" {
  description = "Create default action groups for common scenarios (Critical, Warning, Info)."
  type        = bool
  default     = false
}

variable "default_email_receivers" {
  description = "Default email addresses for built-in action groups. Used when create_default_action_groups is true."
  type = list(object({
    name          = string
    email_address = string
  }))
  default = []
}

variable "default_webhook_url" {
  description = "Default webhook URL for built-in action groups (e.g., Teams, Slack, ServiceNow)."
  type        = string
  default     = null
}
