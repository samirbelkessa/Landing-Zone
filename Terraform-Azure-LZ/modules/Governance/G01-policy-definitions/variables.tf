variable "Brainboard_IP_Range_List" {
  type    = list(string)
  default = ["3.18.12.57", "3.19.117.9", "3.12.21.31", "3.140.65.244", "18.223.219.168", "3.139.254.14", "3.109.176.247", "13.235.196.228", "3.108.102.235", "35.154.77.165"]
}

variable "allowed_regions" {
  description = "List of allowed Azure regions for the Allowed Locations policy. Defaults to Australia East and Australia Southeast."
  type        = list(string)
  default     = ["australiaeast", "australiasoutheast"]

  validation {
    condition     = length(var.allowed_regions) > 0
    error_message = "variable value does not match the validator"
  }
}

variable "allowed_vm_skus_sandbox" {
  description = "List of allowed VM SKUs for Sandbox environments."
  type        = list(string)
  default     = ["Standard_B1s", "Standard_B1ms", "Standard_B2s", "Standard_B2ms", "Standard_D2s_v3", "Standard_D2s_v4", "Standard_D2s_v5"]
}

variable "custom_policy_definitions" {
  description = <<EOT
Map of custom policy definitions to create. Each policy definition includes:
- name: Display name of the policy
- description: Description of the policy's purpose
- mode: Policy mode ('All', 'Indexed', or Microsoft-specific modes)
- metadata: Optional metadata object (category, version, preview, deprecated)
- parameters: Optional parameters schema (HCL object or JSON string)
- policy_rule: The policy rule definition (HCL object or JSON string)
    
Example:
{
  "deny-public-ip" = {
    name        = "Deny Public IP Addresses"
    description = "Denies creation of public IP addresses"
    mode        = "Indexed"
    metadata    = { category = "Network", version = "1.0.0" }
    policy_rule = {
      if = {
        field  = "type"
        equals = "Microsoft.Network/publicIPAddresses"
      }
      then = {
        effect = "deny"
      }
    }
  }
}
EOT
  type = map(object({
    name        = string
    description = optional(string, "")
    mode        = optional(string, "All")
    metadata    = optional(any, {})
    parameters  = optional(any, {})
    policy_rule = any
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.custom_policy_definitions :
      contains(["All", "Indexed", "Microsoft.KeyVault.Data", "Microsoft.Kubernetes.Data", "Microsoft.Network.Data"], v.mode)
    ])
    error_message = "variable value does not match the validator"
  }
}

variable "denied_resource_types" {
  description = "List of resource types to deny (e.g., classic resources)."
  type        = list(string)
  default     = ["Microsoft.ClassicCompute/virtualMachines", "Microsoft.ClassicNetwork/virtualNetworks", "Microsoft.ClassicStorage/storageAccounts"]
}

variable "deploy_caf_policies" {
  description = "Deploy the pre-configured CAF-aligned custom policy definitions for the Australia Landing Zone project."
  type        = bool
  default     = true
}

variable "enable_backup_policies" {
  description = "Enable backup-related custom policies (GRS/LRS requirements)."
  type        = bool
  default     = true
}

variable "enable_cost_policies" {
  description = "Enable cost management custom policies (budgets, SKU restrictions)."
  type        = bool
  default     = true
}

variable "enable_lifecycle_policies" {
  description = "Enable lifecycle management policies (expiration, auto-delete)."
  type        = bool
  default     = true
}

variable "enable_monitoring_policies" {
  description = "Enable monitoring-related custom policies (diagnostics, Log Analytics)."
  type        = bool
  default     = true
}

variable "enable_network_policies" {
  description = "Enable network-related custom policies (hub validation, NSG requirements, routing)."
  type        = bool
  default     = true
}

variable "enable_security_policies" {
  description = "Enable security-related custom policies (private endpoints, encryption)."
  type        = bool
  default     = true
}

variable "expensive_resource_types" {
  description = "List of expensive resource types to deny in Sandbox environments."
  type        = list(string)
  default     = ["Microsoft.Network/expressRouteCircuits", "Microsoft.Network/expressRouteGateways", "Microsoft.Sql/managedInstances", "Microsoft.Cache/redisEnterprise"]
}

variable "law_total_retention_days" {
  description = "Total retention (interactive + archive) for LAW tables enforced by DeployIfNotExists policy."
  type        = number
  default     = 401

  validation {
    condition     = var.law_total_retention_days >= 30 && var.law_total_retention_days <= 2556
    error_message = "variable value does not match the validator"
  }
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the central Log Analytics workspace for diagnostic settings policies. Required if deploy_caf_policies is true."
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "Minimum log retention days for Log Analytics workspace policy."
  type        = number
  default     = 90

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "variable value does not match the validator"
  }
}

variable "management_group_id" {
  description = "The ID of the management group where policies will be defined. Policies defined at a management group can be assigned to that MG and its descendants."
  type        = string

  validation {
    condition     = can(regex("^/providers/Microsoft.Management/managementGroups/", var.management_group_id))
    error_message = "variable value does not match the validator"
  }
}

variable "required_tags" {
  description = "List of tag names that are required on resource groups."
  type        = list(string)
  default     = ["Environment", "Owner", "CostCenter", "Application"]
}

