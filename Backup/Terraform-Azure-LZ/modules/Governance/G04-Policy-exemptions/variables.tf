# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Variables - Policy Exemptions (G04)                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════════════════════════════════════════════════════════════════════════════
# REQUIRED VARIABLES
# ══════════════════════════════════════════════════════════════════════════════

variable "management_group_exemptions" {
  description = <<-EOT
    Map of policy exemptions at management group scope.
    
    Key: Unique identifier for the exemption
    Values:
      - management_group_id: Full resource ID of the management group
      - policy_assignment_id: Resource ID of the policy assignment to exempt from
      - exemption_category: Category of exemption (Waiver or Mitigated)
      - display_name: Human-readable name for the exemption
      - description: Detailed description explaining why the exemption is needed
      - expires_on: Optional expiration date (RFC3339 format) - recommended for Waiver
      - policy_definition_reference_ids: Optional list of policy reference IDs within an initiative
      - metadata: Optional metadata as JSON string
  EOT
  type = map(object({
    management_group_id              = string
    policy_assignment_id             = string
    exemption_category               = string
    display_name                     = string
    description                      = optional(string, "")
    expires_on                       = optional(string, null)
    policy_definition_reference_ids  = optional(list(string), [])
    metadata                         = optional(string, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.management_group_exemptions :
      contains(["Waiver", "Mitigated"], v.exemption_category)
    ])
    error_message = "exemption_category must be either 'Waiver' or 'Mitigated'."
  }

  validation {
    condition = alltrue([
      for k, v in var.management_group_exemptions :
      v.expires_on == null || can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$", v.expires_on))
    ])
    error_message = "expires_on must be in RFC3339 format (e.g., 2025-12-31T23:59:59Z)."
  }
}

variable "subscription_exemptions" {
  description = <<-EOT
    Map of policy exemptions at subscription scope.
    Same structure as management_group_exemptions but with subscription_id instead of management_group_id.
  EOT
  type = map(object({
    subscription_id                  = string
    policy_assignment_id             = string
    exemption_category               = string
    display_name                     = string
    description                      = optional(string, "")
    expires_on                       = optional(string, null)
    policy_definition_reference_ids  = optional(list(string), [])
    metadata                         = optional(string, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.subscription_exemptions :
      contains(["Waiver", "Mitigated"], v.exemption_category)
    ])
    error_message = "exemption_category must be either 'Waiver' or 'Mitigated'."
  }
}

variable "resource_group_exemptions" {
  description = <<-EOT
    Map of policy exemptions at resource group scope.
    Same structure as management_group_exemptions but with resource_group_id instead of management_group_id.
  EOT
  type = map(object({
    resource_group_id                = string
    policy_assignment_id             = string
    exemption_category               = string
    display_name                     = string
    description                      = optional(string, "")
    expires_on                       = optional(string, null)
    policy_definition_reference_ids  = optional(list(string), [])
    metadata                         = optional(string, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.resource_group_exemptions :
      contains(["Waiver", "Mitigated"], v.exemption_category)
    ])
    error_message = "exemption_category must be either 'Waiver' or 'Mitigated'."
  }
}

variable "resource_exemptions" {
  description = <<-EOT
    Map of policy exemptions at individual resource scope.
    Same structure as management_group_exemptions but with resource_id instead of management_group_id.
  EOT
  type = map(object({
    resource_id                      = string
    policy_assignment_id             = string
    exemption_category               = string
    display_name                     = string
    description                      = optional(string, "")
    expires_on                       = optional(string, null)
    policy_definition_reference_ids  = optional(list(string), [])
    metadata                         = optional(string, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.resource_exemptions :
      contains(["Waiver", "Mitigated"], v.exemption_category)
    ])
    error_message = "exemption_category must be either 'Waiver' or 'Mitigated'."
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL VARIABLES - Brownfield Migration Support
# ══════════════════════════════════════════════════════════════════════════════

variable "enable_brownfield_exemptions" {
  description = "Enable pre-configured exemptions for brownfield migration from Fortinet NGFW."
  type        = bool
  default     = false
}

variable "brownfield_migration_end_date" {
  description = "End date for brownfield migration exemptions in RFC3339 format. All migration exemptions will expire on this date."
  type        = string
  default     = null

  validation {
    condition     = var.brownfield_migration_end_date == null || can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$", var.brownfield_migration_end_date))
    error_message = "brownfield_migration_end_date must be in RFC3339 format (e.g., 2025-12-31T23:59:59Z)."
  }
}

variable "brownfield_subscriptions" {
  description = <<-EOT
    Map of subscriptions requiring brownfield exemptions during migration.
    Key: Subscription identifier (friendly name)
    Value: Object with subscription_id and list of policy_assignment_ids to exempt
  EOT
  type = map(object({
    subscription_id       = string
    policy_assignment_ids = list(string)
    reason                = optional(string, "Brownfield migration - legacy configuration pending remediation")
  }))
  default = {}
}

variable "brownfield_resource_groups" {
  description = <<-EOT
    Map of resource groups requiring brownfield exemptions during migration.
    Key: Resource group identifier (friendly name)
    Value: Object with resource_group_id and list of policy_assignment_ids to exempt
  EOT
  type = map(object({
    resource_group_id     = string
    policy_assignment_ids = list(string)
    reason                = optional(string, "Brownfield migration - legacy configuration pending remediation")
  }))
  default = {}
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL VARIABLES - Sandbox Exemptions
# ══════════════════════════════════════════════════════════════════════════════

variable "enable_sandbox_exemptions" {
  description = "Enable relaxed exemptions for Sandbox landing zones."
  type        = bool
  default     = false
}

variable "sandbox_management_group_id" {
  description = "Management Group ID for Sandbox. Required if enable_sandbox_exemptions is true."
  type        = string
  default     = ""
}

variable "sandbox_exempted_policy_assignments" {
  description = "List of policy assignment IDs to exempt in Sandbox environments."
  type        = list(string)
  default     = []
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL VARIABLES - Defaults and Tags
# ══════════════════════════════════════════════════════════════════════════════

variable "default_exemption_category" {
  description = "Default exemption category when not specified. Waiver = administrative exception, Mitigated = alternative compliance."
  type        = string
  default     = "Waiver"

  validation {
    condition     = contains(["Waiver", "Mitigated"], var.default_exemption_category)
    error_message = "default_exemption_category must be either 'Waiver' or 'Mitigated'."
  }
}

variable "require_expiration_for_waivers" {
  description = "When true, all Waiver exemptions must have an expiration date set."
  type        = bool
  default     = true
}

variable "max_waiver_duration_days" {
  description = "Maximum duration in days for Waiver exemptions. Set to 0 to disable limit."
  type        = number
  default     = 365

  validation {
    condition     = var.max_waiver_duration_days >= 0
    error_message = "max_waiver_duration_days must be 0 or greater."
  }
}

variable "tags" {
  description = "Tags to be applied to resources created by this module."
  type        = map(string)
  default     = {}
}
