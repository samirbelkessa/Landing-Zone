# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Variables - Policy Set Definitions (Initiatives)                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════════════════════════════════════════════════════════════════════════════
# REQUIRED VARIABLES
# ══════════════════════════════════════════════════════════════════════════════

variable "management_group_id" {
  description = "The ID of the management group where policy sets will be defined. Policy sets defined at a management group can be assigned to that MG and its descendants."
  type        = string

  validation {
    condition     = can(regex("^/providers/Microsoft.Management/managementGroups/", var.management_group_id))
    error_message = "The management_group_id must be a valid Management Group resource ID starting with '/providers/Microsoft.Management/managementGroups/'."
  }
}

variable "policy_definition_ids" {
  description = "Map of policy definition names to their resource IDs. Output from module G01 (policy-definitions)."
  type        = map(string)
}

variable "builtin_policy_ids" {
  description = "Map of built-in policy IDs from module G01. If not provided, default Azure built-in policy IDs will be used."
  type        = map(string)
  default     = {}
}

variable "builtin_initiative_ids" {
  description = "Map of built-in initiative IDs from module G01. If not provided, default Azure built-in initiative IDs will be used."
  type        = map(string)
  default     = {}
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL VARIABLES - CAF Initiatives
# ══════════════════════════════════════════════════════════════════════════════

variable "deploy_caf_initiatives" {
  description = "Deploy the pre-configured CAF-aligned policy initiatives for the Australia Landing Zone project."
  type        = bool
  default     = true
}

variable "deploy_security_initiative" {
  description = "Deploy the Security baseline initiative (TLS, HTTPS, encryption, Defender)."
  type        = bool
  default     = true
}

variable "deploy_network_initiative" {
  description = "Deploy the Network baseline initiative (hub validation, NSG, routing, private endpoints)."
  type        = bool
  default     = true
}

variable "deploy_monitoring_initiative" {
  description = "Deploy the Monitoring baseline initiative (diagnostics, Log Analytics, Azure Monitor Agent)."
  type        = bool
  default     = true
}

variable "deploy_governance_initiative" {
  description = "Deploy the Governance baseline initiative (tags, allowed locations, naming)."
  type        = bool
  default     = true
}

variable "deploy_backup_initiative" {
  description = "Deploy the Backup baseline initiative (GRS/LRS policies, cross-region restore)."
  type        = bool
  default     = true
}

variable "deploy_cost_initiative" {
  description = "Deploy the Cost management initiative (budgets, SKU restrictions, expensive resources)."
  type        = bool
  default     = true
}

variable "deploy_identity_initiative" {
  description = "Deploy the Identity baseline initiative (managed identity, Entra DS)."
  type        = bool
  default     = true
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL VARIABLES - Archetype-Specific Initiatives
# ══════════════════════════════════════════════════════════════════════════════

variable "deploy_archetype_initiatives" {
  description = "Deploy Landing Zone archetype-specific initiatives (Online-Prod, Online-NonProd, Corp-Prod, Corp-NonProd, Sandbox)."
  type        = bool
  default     = true
}

variable "archetypes_to_deploy" {
  description = "List of archetypes for which to deploy specific initiatives. Valid values: online-prod, online-nonprod, corp-prod, corp-nonprod, sandbox, decommissioned."
  type        = list(string)
  default     = ["online-prod", "online-nonprod", "corp-prod", "corp-nonprod", "sandbox", "decommissioned"]

  validation {
    condition = alltrue([
      for archetype in var.archetypes_to_deploy : contains(
        ["online-prod", "online-nonprod", "corp-prod", "corp-nonprod", "sandbox", "decommissioned"],
        lower(archetype)
      )
    ])
    error_message = "Valid archetypes are: online-prod, online-nonprod, corp-prod, corp-nonprod, sandbox, decommissioned."
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL VARIABLES - Custom Initiatives
# ══════════════════════════════════════════════════════════════════════════════

variable "custom_policy_set_definitions" {
  description = <<-EOT
    Map of custom policy set definitions (initiatives) to create.
    Each initiative groups multiple policies together for unified assignment.
  EOT
  type = map(object({
    display_name        = string
    description         = optional(string, "")
    metadata            = optional(string, null)
    parameters          = optional(string, null)
    policy_definition_references = list(object({
      policy_definition_id = string
      parameter_values     = optional(string, null)
      reference_id         = optional(string, null)
    }))
  }))
  default = {}
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL VARIABLES - Built-in Initiatives
# ══════════════════════════════════════════════════════════════════════════════

variable "include_azure_security_benchmark" {
  description = "Include Azure Security Benchmark initiative in the Platform initiative group."
  type        = bool
  default     = true
}

variable "include_vm_insights" {
  description = "Include Enable Azure Monitor for VMs initiative in the Monitoring initiative."
  type        = bool
  default     = true
}

variable "include_nist_initiative" {
  description = "Include NIST SP 800-53 Rev. 5 initiative for compliance requirements."
  type        = bool
  default     = false
}

variable "include_iso27001_initiative" {
  description = "Include ISO 27001:2013 initiative for compliance requirements."
  type        = bool
  default     = false
}

variable "include_cis_initiative" {
  description = "Include CIS Microsoft Azure Foundations Benchmark initiative."
  type        = bool
  default     = false
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL VARIABLES - Parameters
# ══════════════════════════════════════════════════════════════════════════════

variable "allowed_regions" {
  description = "List of allowed Azure regions for location-related policies."
  type        = list(string)
  default     = ["australiaeast", "australiasoutheast"]
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the central Log Analytics workspace for diagnostic settings policies."
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "Minimum log retention days for Log Analytics workspace policy (30-730)."
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
  description = "List of allowed VM SKUs for Sandbox environments."
  type        = list(string)
  default     = ["Standard_B1s", "Standard_B1ms", "Standard_B2s", "Standard_B2ms", "Standard_D2s_v3", "Standard_D2s_v4", "Standard_D2s_v5"]
}

variable "expensive_resource_types" {
  description = "List of expensive resource types to deny in Sandbox environments."
  type        = list(string)
  default = [
    "Microsoft.Network/expressRouteCircuits",
    "Microsoft.Network/expressRouteGateways",
    "Microsoft.Sql/managedInstances",
    "Microsoft.Cache/redisEnterprise"
  ]
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL VARIABLES - Tags
# ══════════════════════════════════════════════════════════════════════════════

variable "tags" {
  description = "Tags to be applied to all resources created by this module. Expected: Environment, Owner, CostCenter, Application."
  type        = map(string)
  default     = {}
}
