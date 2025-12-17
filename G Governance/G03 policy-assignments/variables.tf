################################################################################
# Variables - Policy Assignments (G03)
# Assigns policies and initiatives to Management Groups with contextual parameters
################################################################################

# ══════════════════════════════════════════════════════════════════════════════
# REQUIRED VARIABLES
# ══════════════════════════════════════════════════════════════════════════════

variable "management_group_hierarchy" {
  description = "Map of management group names to their resource IDs from module F01. Keys should match CAF hierarchy: root, platform, management, connectivity, identity, landing_zones, corp_prod, corp_nonprod, online_prod, online_nonprod, sandbox, decommissioned."
  type        = map(string)

  validation {
    condition     = contains(keys(var.management_group_hierarchy), "root")
    error_message = "The management_group_hierarchy must contain at least a 'root' management group ID."
  }
}

variable "initiative_ids" {
  description = "Map of initiative (policy set) names to their resource IDs from module G02. Should include baseline initiatives (caf-security-baseline, caf-network-baseline, etc.) and archetype initiatives (caf-online-prod, caf-corp-prod, etc.)."
  type        = map(string)
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL - ASSIGNMENT CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

variable "deploy_root_assignments" {
  description = "Deploy policy assignments at the root management group level. These apply to all descendants."
  type        = bool
  default     = true
}

variable "deploy_platform_assignments" {
  description = "Deploy policy assignments at the Platform management group and its children (Management, Connectivity, Identity)."
  type        = bool
  default     = true
}

variable "deploy_landing_zone_assignments" {
  description = "Deploy policy assignments at the Landing Zones management group and archetype children."
  type        = bool
  default     = true
}

variable "deploy_decommissioned_assignments" {
  description = "Deploy deny-all policy assignments to the Decommissioned management group."
  type        = bool
  default     = true
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL - BUILTIN INITIATIVE ASSIGNMENTS
# ══════════════════════════════════════════════════════════════════════════════

variable "assign_azure_security_benchmark" {
  description = "Assign the Azure Security Benchmark built-in initiative to the Platform management group."
  type        = bool
  default     = true
}

variable "assign_vm_insights" {
  description = "Assign the VM Insights built-in initiative to the Platform management group."
  type        = bool
  default     = true
}

variable "assign_nist_sp_800_53" {
  description = "Assign the NIST SP 800-53 R5 built-in initiative (for compliance reporting only)."
  type        = bool
  default     = false
}

variable "assign_iso_27001" {
  description = "Assign the ISO 27001:2013 built-in initiative (for compliance reporting only)."
  type        = bool
  default     = false
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL - POLICY PARAMETERS (Australia Project Specific)
# ══════════════════════════════════════════════════════════════════════════════

variable "allowed_locations" {
  description = "List of allowed Azure regions for the Allowed Locations policy."
  type        = list(string)
  default     = ["australiaeast", "australiasoutheast"]

  validation {
    condition     = length(var.allowed_locations) > 0
    error_message = "At least one allowed location must be specified."
  }
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the central Log Analytics workspace for diagnostic settings and monitoring policies."
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "Minimum log retention days for Log Analytics workspace (90 days interactive as per project requirements)."
  type        = number
  default     = 90

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "Log retention must be between 30 and 730 days."
  }
}

variable "required_tags" {
  description = "List of tag names that are required on resource groups."
  type        = list(string)
  default     = ["Environment", "Owner", "CostCenter", "Application"]
}

variable "allowed_vm_skus_sandbox" {
  description = "List of allowed VM SKUs for Sandbox environments (cost control)."
  type        = list(string)
  default = [
    "Standard_B1s",
    "Standard_B1ms",
    "Standard_B2s",
    "Standard_B2ms",
    "Standard_D2s_v3",
    "Standard_D2s_v4",
    "Standard_D2s_v5"
  ]
}

variable "backup_geo_redundancy_regions" {
  description = "Map of primary region to DR region for backup cross-region restore requirements."
  type        = map(string)
  default = {
    "australiaeast" = "australiasoutheast"
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL - MANAGED IDENTITY FOR DEPLOYIFNOTEXISTS
# ══════════════════════════════════════════════════════════════════════════════

variable "create_remediation_identity" {
  description = "Create a User Assigned Managed Identity for policy remediation tasks (DeployIfNotExists, Modify effects)."
  type        = bool
  default     = true
}

variable "remediation_identity_name" {
  description = "Name of the managed identity for policy remediation. If not specified, uses 'policy-remediation-identity'."
  type        = string
  default     = "policy-remediation-identity"
}

variable "remediation_identity_resource_group" {
  description = "Resource group name where the remediation managed identity will be created. Required if create_remediation_identity is true."
  type        = string
  default     = ""
}

variable "remediation_identity_location" {
  description = "Location for the remediation managed identity."
  type        = string
  default     = "australiaeast"
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL - CUSTOM ASSIGNMENTS
# ══════════════════════════════════════════════════════════════════════════════

variable "custom_policy_assignments" {
  description = <<-EOT
    Map of custom policy assignments to create beyond the CAF defaults.
    Each assignment requires:
    - policy_definition_id or policy_set_definition_id: The policy or initiative to assign
    - management_group_id: Where to assign (can reference var.management_group_hierarchy keys)
    - display_name: Human-readable name
    - description: Assignment description
    - enforcement_mode: "Default" or "DoNotEnforce"
    - parameters: Map of parameter values (optional)
    - non_compliance_message: Message shown for non-compliant resources (optional)
    - identity_type: "None", "SystemAssigned", or "UserAssigned" (optional, for remediation)
  EOT
  type = map(object({
    policy_definition_id     = optional(string)
    policy_set_definition_id = optional(string)
    management_group_id      = string
    display_name             = string
    description              = optional(string, "")
    enforcement_mode         = optional(string, "Default")
    parameters               = optional(map(any), {})
    non_compliance_message   = optional(string)
    identity_type            = optional(string, "None")
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.custom_policy_assignments :
      (v.policy_definition_id != null || v.policy_set_definition_id != null) &&
      !(v.policy_definition_id != null && v.policy_set_definition_id != null)
    ])
    error_message = "Each custom assignment must have either policy_definition_id OR policy_set_definition_id, but not both."
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL - ENFORCEMENT AND NON-COMPLIANCE
# ══════════════════════════════════════════════════════════════════════════════

variable "enforcement_mode_override" {
  description = "Override enforcement mode for all assignments. Use 'DoNotEnforce' for audit-only mode during migration. Null means use default per assignment."
  type        = string
  default     = null

  validation {
    condition     = var.enforcement_mode_override == null || contains(["Default", "DoNotEnforce"], var.enforcement_mode_override)
    error_message = "Enforcement mode must be 'Default', 'DoNotEnforce', or null."
  }
}

variable "non_compliance_message_prefix" {
  description = "Prefix for non-compliance messages. Organization name or project identifier."
  type        = string
  default     = "[CAF Landing Zone]"
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL - ASSIGNMENT METADATA
# ══════════════════════════════════════════════════════════════════════════════

variable "assignment_metadata" {
  description = "Additional metadata to include in all policy assignments."
  type        = map(string)
  default = {
    createdBy = "Terraform"
    framework = "CAF Landing Zone"
  }
}

variable "tags" {
  description = "Tags to apply to resources created by this module (managed identity if created)."
  type        = map(string)
  default     = {}
}
