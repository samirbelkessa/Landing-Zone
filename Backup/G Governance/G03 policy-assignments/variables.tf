# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Variables - Policy Assignments (G03)                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════════════════════════════════════════════════════════════════════════════
# REQUIRED VARIABLES
# ══════════════════════════════════════════════════════════════════════════════

variable "management_group_assignments" {
  description = <<-EOT
    Map of policy assignments at management group scope.
    Each assignment can reference either a policy definition or policy set definition (initiative).
    
    Key: Unique identifier for the assignment
    Values:
      - management_group_id: Full resource ID of the management group
      - policy_definition_id: Resource ID of policy definition (mutually exclusive with policy_set_definition_id)
      - policy_set_definition_id: Resource ID of policy set definition/initiative (mutually exclusive with policy_definition_id)
      - display_name: Human-readable name for the assignment
      - description: Description of the assignment purpose
      - enforce: Whether to enforce the policy (true) or audit only (false)
      - parameters: JSON-encoded parameters for the policy
      - non_compliance_message: Message shown when resources are non-compliant
      - identity_type: Type of managed identity (None, SystemAssigned, UserAssigned)
      - identity_ids: List of User Assigned Managed Identity IDs (required if identity_type = UserAssigned)
      - location: Location for the managed identity (required if identity_type != None)
      - not_scopes: List of scopes to exclude from the assignment
      - metadata: Additional metadata as JSON string
  EOT
  type = map(object({
    management_group_id       = string
    policy_definition_id      = optional(string)
    policy_set_definition_id  = optional(string)
    display_name              = string
    description               = optional(string, "")
    enforce                   = optional(bool, true)
    parameters                = optional(string, null)
    non_compliance_message    = optional(string, null)
    identity_type             = optional(string, "None")
    identity_ids              = optional(list(string), [])
    location                  = optional(string, null)
    not_scopes                = optional(list(string), [])
    metadata                  = optional(string, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.management_group_assignments :
      (v.policy_definition_id != null && v.policy_set_definition_id == null) ||
      (v.policy_definition_id == null && v.policy_set_definition_id != null)
    ])
    error_message = "Each assignment must have either policy_definition_id OR policy_set_definition_id, not both or neither."
  }

  validation {
    condition = alltrue([
      for k, v in var.management_group_assignments :
      contains(["None", "SystemAssigned", "UserAssigned"], v.identity_type)
    ])
    error_message = "identity_type must be one of: None, SystemAssigned, UserAssigned."
  }

  validation {
    condition = alltrue([
      for k, v in var.management_group_assignments :
      v.identity_type != "UserAssigned" || length(v.identity_ids) > 0
    ])
    error_message = "identity_ids must be provided when identity_type is UserAssigned."
  }

  validation {
    condition = alltrue([
      for k, v in var.management_group_assignments :
      v.identity_type == "None" || v.location != null
    ])
    error_message = "location must be provided when identity_type is not None."
  }
}

variable "subscription_assignments" {
  description = <<-EOT
    Map of policy assignments at subscription scope.
    Same structure as management_group_assignments but with subscription_id instead of management_group_id.
  EOT
  type = map(object({
    subscription_id           = string
    policy_definition_id      = optional(string)
    policy_set_definition_id  = optional(string)
    display_name              = string
    description               = optional(string, "")
    enforce                   = optional(bool, true)
    parameters                = optional(string, null)
    non_compliance_message    = optional(string, null)
    identity_type             = optional(string, "None")
    identity_ids              = optional(list(string), [])
    location                  = optional(string, null)
    not_scopes                = optional(list(string), [])
    metadata                  = optional(string, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.subscription_assignments :
      (v.policy_definition_id != null && v.policy_set_definition_id == null) ||
      (v.policy_definition_id == null && v.policy_set_definition_id != null)
    ])
    error_message = "Each assignment must have either policy_definition_id OR policy_set_definition_id, not both or neither."
  }
}

variable "resource_group_assignments" {
  description = <<-EOT
    Map of policy assignments at resource group scope.
    Same structure as management_group_assignments but with resource_group_id instead of management_group_id.
  EOT
  type = map(object({
    resource_group_id         = string
    policy_definition_id      = optional(string)
    policy_set_definition_id  = optional(string)
    display_name              = string
    description               = optional(string, "")
    enforce                   = optional(bool, true)
    parameters                = optional(string, null)
    non_compliance_message    = optional(string, null)
    identity_type             = optional(string, "None")
    identity_ids              = optional(list(string), [])
    location                  = optional(string, null)
    not_scopes                = optional(list(string), [])
    metadata                  = optional(string, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.resource_group_assignments :
      (v.policy_definition_id != null && v.policy_set_definition_id == null) ||
      (v.policy_definition_id == null && v.policy_set_definition_id != null)
    ])
    error_message = "Each assignment must have either policy_definition_id OR policy_set_definition_id, not both or neither."
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL VARIABLES - CAF Landing Zone Assignments
# ══════════════════════════════════════════════════════════════════════════════

variable "deploy_caf_assignments" {
  description = "Deploy the pre-configured CAF Landing Zone policy assignments."
  type        = bool
  default     = false
}

variable "caf_management_groups" {
  description = <<-EOT
    Map of CAF management group IDs for automatic assignment deployment.
    Required when deploy_caf_assignments = true.
    
    Expected keys:
      - root: Root management group ID
      - platform: Platform management group ID
      - connectivity: Connectivity management group ID
      - identity: Identity management group ID
      - management: Management management group ID
      - landing_zones: Landing Zones parent management group ID
      - online_prod: Online Production landing zone MG ID
      - online_nonprod: Online Non-Production landing zone MG ID
      - corp_prod: Corporate Production landing zone MG ID
      - corp_nonprod: Corporate Non-Production landing zone MG ID
      - sandbox: Sandbox landing zone MG ID
      - decommissioned: Decommissioned management group ID
  EOT
  type        = map(string)
  default     = {}

  validation {
    condition = !var.deploy_caf_assignments || alltrue([
      for key in ["root", "platform", "landing_zones"] :
      contains(keys(var.caf_management_groups), key)
    ])
    error_message = "When deploy_caf_assignments is true, caf_management_groups must contain at least: root, platform, landing_zones."
  }
}

variable "caf_initiative_ids" {
  description = <<-EOT
    Map of CAF initiative IDs from module G02 for automatic assignment.
    Required when deploy_caf_assignments = true.
    
    Expected keys match initiative names from G02:
      - caf-security-baseline
      - caf-network-baseline
      - caf-monitoring-baseline
      - caf-governance-baseline
      - caf-backup-baseline
      - caf-cost-baseline
      - caf-identity-baseline
      - caf-online-prod
      - caf-online-nonprod
      - caf-corp-prod
      - caf-corp-nonprod
      - caf-sandbox
      - caf-decommissioned
  EOT
  type        = map(string)
  default     = {}
}

variable "caf_builtin_initiative_ids" {
  description = <<-EOT
    Map of built-in initiative IDs for CAF assignments.
    Expected keys:
      - azure_security_benchmark
      - vm_insights
      - nist_sp_800_53_r5 (optional)
      - iso_27001_2013 (optional)
  EOT
  type        = map(string)
  default     = {}
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL VARIABLES - Role Assignments for Managed Identities
# ══════════════════════════════════════════════════════════════════════════════

variable "create_role_assignments" {
  description = "Automatically create role assignments for policy assignments with managed identities (DeployIfNotExists, Modify)."
  type        = bool
  default     = true
}

variable "role_definition_ids" {
  description = <<-EOT
    Map of role definition IDs to assign to policy managed identities.
    Key: Policy assignment key
    Value: List of role definition IDs
    
    If not specified, the module will use default roles based on policy effect:
      - DeployIfNotExists: Contributor
      - Modify: Contributor
  EOT
  type        = map(list(string))
  default     = {}
}

variable "default_role_definition_id" {
  description = "Default role definition ID to assign to managed identities. Defaults to Contributor."
  type        = string
  default     = "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL VARIABLES - Parameters
# ══════════════════════════════════════════════════════════════════════════════

variable "default_location" {
  description = "Default location for managed identities when not specified in assignment."
  type        = string
  default     = "australiaeast"
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the central Log Analytics workspace for monitoring policies."
  type        = string
  default     = ""
}

variable "allowed_regions" {
  description = "List of allowed Azure regions for location policies."
  type        = list(string)
  default     = ["australiaeast", "australiasoutheast"]
}

variable "required_tags" {
  description = "List of required tag names for governance policies."
  type        = list(string)
  default     = ["Environment", "Owner", "CostCenter", "Application"]
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL VARIABLES - Tags
# ══════════════════════════════════════════════════════════════════════════════

variable "tags" {
  description = "Tags to be applied to resources created by this module."
  type        = map(string)
  default     = {}
}
