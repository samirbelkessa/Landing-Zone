# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Variables - Orchestrator LZA Governance                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════════════════════════════════════════════════════════════════════════════
# REQUIRED VARIABLES - Management Groups (F01)
# ══════════════════════════════════════════════════════════════════════════════

variable "root_parent_id" {
  description = "The ID of the Tenant Root Group or parent management group. Use tenant ID for tenant root."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.root_parent_id)) || can(regex("^/providers/Microsoft.Management/managementGroups/", var.root_parent_id))
    error_message = "root_parent_id must be a valid GUID (tenant ID) or a management group resource ID."
  }
}

variable "root_name" {
  description = "Display name for the root intermediate management group (e.g., 'Contoso' or organization name)."
  type        = string

  validation {
    condition     = length(var.root_name) >= 2 && length(var.root_name) <= 90
    error_message = "root_name must be between 2 and 90 characters."
  }
}

variable "root_id" {
  description = "ID/Name for the root intermediate management group. Used in resource naming."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.root_id)) && length(var.root_id) >= 2 && length(var.root_id) <= 90
    error_message = "root_id must contain only alphanumeric characters, hyphens, and underscores, and be between 2-90 characters."
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL VARIABLES - Management Groups Structure (F01)
# ══════════════════════════════════════════════════════════════════════════════

variable "deploy_platform_mg" {
  description = "Deploy the Platform management group and its children (Management, Connectivity, Identity)."
  type        = bool
  default     = true
}

variable "deploy_landing_zones_mg" {
  description = "Deploy the Landing Zones management group and its children."
  type        = bool
  default     = true
}

variable "deploy_decommissioned_mg" {
  description = "Deploy the Decommissioned management group."
  type        = bool
  default     = true
}

variable "deploy_sandbox_mg" {
  description = "Deploy the Sandbox management group under Landing Zones."
  type        = bool
  default     = true
}

variable "deploy_corp_landing_zones" {
  description = "Deploy Corp landing zone archetypes."
  type        = bool
  default     = true
}

variable "deploy_online_landing_zones" {
  description = "Deploy Online landing zone archetypes."
  type        = bool
  default     = true
}

variable "deploy_prod_nonprod_separation" {
  description = "Create separate Prod and NonProd management groups for each archetype."
  type        = bool
  default     = true
}

variable "custom_landing_zone_children" {
  description = "Map of custom child management groups to create under Landing Zones."
  type = map(object({
    display_name = string
  }))
  default = {}
}

variable "custom_platform_children" {
  description = "Map of custom child management groups to create under Platform."
  type = map(object({
    display_name = string
  }))
  default = {}
}

variable "subscription_ids_by_mg" {
  description = "Map of management group names to lists of subscription IDs to associate."
  type        = map(list(string))
  default     = {}
}

variable "mg_timeouts" {
  description = "Timeout configuration for management group operations."
  type = object({
    create = optional(string, "30m")
    read   = optional(string, "5m")
    update = optional(string, "30m")
    delete = optional(string, "30m")
  })
  default = {}
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL VARIABLES - Policy Definitions (G01)
# ══════════════════════════════════════════════════════════════════════════════

variable "deploy_caf_policies" {
  description = "Deploy the pre-configured CAF-aligned custom policy definitions."
  type        = bool
  default     = true
}

variable "custom_policy_definitions" {
  description = "Map of custom policy definitions to create alongside CAF policies."
  type = map(object({
    name        = string
    description = optional(string, "")
    mode        = optional(string, "All")
    metadata    = optional(any, {})
    parameters  = optional(any, {})
    policy_rule = any
  }))
  default = {}
}

variable "enable_network_policies" {
  description = "Enable network-related custom policies."
  type        = bool
  default     = true
}

variable "enable_security_policies" {
  description = "Enable security-related custom policies."
  type        = bool
  default     = true
}

variable "enable_monitoring_policies" {
  description = "Enable monitoring-related custom policies."
  type        = bool
  default     = true
}

variable "enable_backup_policies" {
  description = "Enable backup-related custom policies."
  type        = bool
  default     = true
}

variable "enable_cost_policies" {
  description = "Enable cost management custom policies."
  type        = bool
  default     = true
}

variable "enable_lifecycle_policies" {
  description = "Enable lifecycle management policies."
  type        = bool
  default     = true
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL VARIABLES - Policy Set Definitions (G02)
# ══════════════════════════════════════════════════════════════════════════════

variable "deploy_caf_initiatives" {
  description = "Deploy the pre-configured CAF-aligned policy initiatives."
  type        = bool
  default     = true
}

variable "deploy_security_initiative" {
  description = "Deploy the Security baseline initiative."
  type        = bool
  default     = true
}

variable "deploy_network_initiative" {
  description = "Deploy the Network baseline initiative."
  type        = bool
  default     = true
}

variable "deploy_monitoring_initiative" {
  description = "Deploy the Monitoring baseline initiative."
  type        = bool
  default     = true
}

variable "deploy_governance_initiative" {
  description = "Deploy the Governance baseline initiative."
  type        = bool
  default     = true
}

variable "deploy_backup_initiative" {
  description = "Deploy the Backup baseline initiative."
  type        = bool
  default     = true
}

variable "deploy_cost_initiative" {
  description = "Deploy the Cost management initiative."
  type        = bool
  default     = true
}

variable "deploy_identity_initiative" {
  description = "Deploy the Identity baseline initiative."
  type        = bool
  default     = true
}

variable "deploy_archetype_initiatives" {
  description = "Deploy Landing Zone archetype-specific initiatives."
  type        = bool
  default     = true
}

variable "archetypes_to_deploy" {
  description = "List of archetypes for which to deploy specific initiatives."
  type        = list(string)
  default     = ["online-prod", "online-nonprod", "corp-prod", "corp-nonprod", "sandbox", "decommissioned"]
}

variable "include_azure_security_benchmark" {
  description = "Include Azure Security Benchmark initiative."
  type        = bool
  default     = true
}

variable "include_vm_insights" {
  description = "Include Enable Azure Monitor for VMs initiative."
  type        = bool
  default     = true
}

variable "include_nist_initiative" {
  description = "Include NIST SP 800-53 Rev. 5 initiative."
  type        = bool
  default     = false
}

variable "include_iso27001_initiative" {
  description = "Include ISO 27001:2013 initiative."
  type        = bool
  default     = false
}

variable "custom_policy_set_definitions" {
  description = "Map of custom policy set definitions (initiatives) to create."
  type = map(object({
    display_name = string
    description  = optional(string, "")
    metadata     = optional(string, null)
    parameters   = optional(string, null)
    policy_definition_references = list(object({
      policy_definition_id = string
      parameter_values     = optional(string, null)
      reference_id         = optional(string, null)
    }))
  }))
  default = {}
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL VARIABLES - Policy Assignments (G03)
# ══════════════════════════════════════════════════════════════════════════════

variable "deploy_caf_assignments" {
  description = "Deploy the pre-configured CAF Landing Zone policy assignments."
  type        = bool
  default     = true
}

variable "create_role_assignments" {
  description = "Automatically create role assignments for policy assignments with managed identities."
  type        = bool
  default     = true
}

variable "role_definition_ids" {
  description = "Map of role definition IDs to assign to policy managed identities."
  type        = map(list(string))
  default     = {}
}

variable "default_role_definition_id" {
  description = "Default role definition ID to assign to managed identities. Defaults to Contributor."
  type        = string
  default     = "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
}

variable "management_group_assignments" {
  description = "Map of additional manual policy assignments at management group scope."
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
}

variable "subscription_assignments" {
  description = "Map of policy assignments at subscription scope."
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
}

variable "resource_group_assignments" {
  description = "Map of policy assignments at resource group scope."
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
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL VARIABLES - Policy Exemptions (G04)
# ══════════════════════════════════════════════════════════════════════════════

variable "deploy_exemptions" {
  description = "Enable deployment of policy exemptions module."
  type        = bool
  default     = true
}

variable "management_group_exemptions" {
  description = "Map of policy exemptions at management group scope."
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
}

variable "subscription_exemptions" {
  description = "Map of policy exemptions at subscription scope."
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
}

variable "resource_group_exemptions" {
  description = "Map of policy exemptions at resource group scope."
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
}

variable "resource_exemptions" {
  description = "Map of policy exemptions at individual resource scope."
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
}

variable "enable_brownfield_exemptions" {
  description = "Enable pre-configured exemptions for brownfield migration."
  type        = bool
  default     = false
}

variable "brownfield_migration_end_date" {
  description = "End date for brownfield migration exemptions in RFC3339 format."
  type        = string
  default     = null
}

variable "brownfield_subscriptions" {
  description = "Map of subscriptions requiring brownfield exemptions during migration."
  type = map(object({
    subscription_id       = string
    policy_assignment_ids = list(string)
    reason                = optional(string, "Brownfield migration - legacy configuration pending remediation")
  }))
  default = {}
}

variable "brownfield_resource_groups" {
  description = "Map of resource groups requiring brownfield exemptions during migration."
  type = map(object({
    resource_group_id     = string
    policy_assignment_ids = list(string)
    reason                = optional(string, "Brownfield migration - legacy configuration pending remediation")
  }))
  default = {}
}

variable "enable_sandbox_exemptions" {
  description = "Enable relaxed exemptions for Sandbox landing zones."
  type        = bool
  default     = false
}

variable "sandbox_exempted_policy_assignments" {
  description = "List of policy assignment IDs to exempt in Sandbox environments."
  type        = list(string)
  default     = []
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
}

# ══════════════════════════════════════════════════════════════════════════════
# COMMON VARIABLES - Shared across modules
# ══════════════════════════════════════════════════════════════════════════════

variable "default_location" {
  description = "Default Azure region for resources and managed identities."
  type        = string
  default     = "australiaeast"
}

variable "allowed_regions" {
  description = "List of allowed Azure regions for location policies."
  type        = list(string)
  default     = ["australiaeast", "australiasoutheast"]
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the central Log Analytics workspace."
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "Minimum log retention days for Log Analytics workspace policy."
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

variable "denied_resource_types" {
  description = "List of resource types to deny (e.g., classic resources)."
  type        = list(string)
  default = [
    "Microsoft.ClassicCompute/virtualMachines",
    "Microsoft.ClassicNetwork/virtualNetworks",
    "Microsoft.ClassicStorage/storageAccounts"
  ]
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

variable "tags" {
  description = "Tags to be applied to all resources created by this module."
  type        = map(string)
  default     = {}
}
