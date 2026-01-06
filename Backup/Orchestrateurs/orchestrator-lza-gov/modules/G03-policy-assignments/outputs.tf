# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Outputs - Policy Assignments (G03)                                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════════════════════════════════════════════════════════════════════════════
# Management Group Assignment Outputs
# ══════════════════════════════════════════════════════════════════════════════

output "mg_assignment_ids" {
  description = "Map of management group policy assignment names to their resource IDs."
  value = {
    for k, v in azurerm_management_group_policy_assignment.assignments : k => v.id
  }
}

output "mg_assignments" {
  description = "Full map of management group policy assignments with all attributes."
  value = {
    for k, v in azurerm_management_group_policy_assignment.assignments : k => {
      id                   = v.id
      name                 = v.name
      display_name         = v.display_name
      description          = v.description
      management_group_id  = v.management_group_id
      policy_definition_id = v.policy_definition_id
      enforce              = v.enforce
      identity = try({
        type         = v.identity[0].type
        principal_id = v.identity[0].principal_id
        tenant_id    = v.identity[0].tenant_id
      }, null)
    }
  }
}

output "mg_assignment_identities" {
  description = "Map of management group assignment names to their managed identity principal IDs (for assignments with identities)."
  value = {
    for k, v in azurerm_management_group_policy_assignment.assignments : k => v.identity[0].principal_id
    if length(v.identity) > 0
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Subscription Assignment Outputs
# ══════════════════════════════════════════════════════════════════════════════

output "sub_assignment_ids" {
  description = "Map of subscription policy assignment names to their resource IDs."
  value = {
    for k, v in azurerm_subscription_policy_assignment.assignments : k => v.id
  }
}

output "sub_assignments" {
  description = "Full map of subscription policy assignments with all attributes."
  value = {
    for k, v in azurerm_subscription_policy_assignment.assignments : k => {
      id                   = v.id
      name                 = v.name
      display_name         = v.display_name
      description          = v.description
      subscription_id      = v.subscription_id
      policy_definition_id = v.policy_definition_id
      enforce              = v.enforce
      identity = try({
        type         = v.identity[0].type
        principal_id = v.identity[0].principal_id
        tenant_id    = v.identity[0].tenant_id
      }, null)
    }
  }
}

output "sub_assignment_identities" {
  description = "Map of subscription assignment names to their managed identity principal IDs."
  value = {
    for k, v in azurerm_subscription_policy_assignment.assignments : k => v.identity[0].principal_id
    if length(v.identity) > 0
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Resource Group Assignment Outputs
# ══════════════════════════════════════════════════════════════════════════════

output "rg_assignment_ids" {
  description = "Map of resource group policy assignment names to their resource IDs."
  value = {
    for k, v in azurerm_resource_group_policy_assignment.assignments : k => v.id
  }
}

output "rg_assignments" {
  description = "Full map of resource group policy assignments with all attributes."
  value = {
    for k, v in azurerm_resource_group_policy_assignment.assignments : k => {
      id                   = v.id
      name                 = v.name
      display_name         = v.display_name
      description          = v.description
      resource_group_id    = v.resource_group_id
      policy_definition_id = v.policy_definition_id
      enforce              = v.enforce
      identity = try({
        type         = v.identity[0].type
        principal_id = v.identity[0].principal_id
        tenant_id    = v.identity[0].tenant_id
      }, null)
    }
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Role Assignment Outputs
# ══════════════════════════════════════════════════════════════════════════════

output "role_assignment_ids" {
  description = "Map of role assignment IDs created for policy managed identities."
  value = merge(
    { for k, v in azurerm_role_assignment.mg_policy_identity : "mg-${k}" => v.id },
    { for k, v in azurerm_role_assignment.sub_policy_identity : "sub-${k}" => v.id },
    { for k, v in azurerm_role_assignment.rg_policy_identity : "rg-${k}" => v.id }
  )
}

# ══════════════════════════════════════════════════════════════════════════════
# Combined Outputs
# ══════════════════════════════════════════════════════════════════════════════

output "all_assignment_ids" {
  description = "Map of all policy assignment names to their resource IDs (all scopes combined)."
  value = merge(
    { for k, v in azurerm_management_group_policy_assignment.assignments : "mg-${k}" => v.id },
    { for k, v in azurerm_subscription_policy_assignment.assignments : "sub-${k}" => v.id },
    { for k, v in azurerm_resource_group_policy_assignment.assignments : "rg-${k}" => v.id }
  )
}

output "all_assignment_principal_ids" {
  description = "Map of all policy assignments with managed identities to their principal IDs."
  value = merge(
    {
      for k, v in azurerm_management_group_policy_assignment.assignments : "mg-${k}" => v.identity[0].principal_id
      if length(v.identity) > 0
    },
    {
      for k, v in azurerm_subscription_policy_assignment.assignments : "sub-${k}" => v.identity[0].principal_id
      if length(v.identity) > 0
    },
    {
      for k, v in azurerm_resource_group_policy_assignment.assignments : "rg-${k}" => v.identity[0].principal_id
      if length(v.identity) > 0
    }
  )
}

# ══════════════════════════════════════════════════════════════════════════════
# CAF Assignment Outputs
# ══════════════════════════════════════════════════════════════════════════════

output "caf_assignment_ids" {
  description = "Map of CAF policy assignment names to their resource IDs (only CAF automatic assignments)."
  value = {
    for k, v in azurerm_management_group_policy_assignment.assignments : k => v.id
    if contains(keys(local.valid_caf_mg_assignments), k)
  }
}

output "caf_assignments_by_scope" {
  description = "CAF assignments organized by management group scope."
  value = {
    root = {
      for k, v in azurerm_management_group_policy_assignment.assignments : k => v.id
      if startswith(k, "root-")
    }
    platform = {
      for k, v in azurerm_management_group_policy_assignment.assignments : k => v.id
      if startswith(k, "connectivity-") || startswith(k, "identity-") || startswith(k, "management-") || startswith(k, "platform-")
    }
    landing_zones = {
      for k, v in azurerm_management_group_policy_assignment.assignments : k => v.id
      if startswith(k, "lz-") || startswith(k, "online-") || startswith(k, "corp-") || startswith(k, "sandbox-")
    }
    decommissioned = {
      for k, v in azurerm_management_group_policy_assignment.assignments : k => v.id
      if startswith(k, "decommissioned-")
    }
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Summary Output
# ══════════════════════════════════════════════════════════════════════════════

output "summary" {
  description = "Summary of deployed policy assignments."
  value = {
    total_assignments = (
      length(azurerm_management_group_policy_assignment.assignments) +
      length(azurerm_subscription_policy_assignment.assignments) +
      length(azurerm_resource_group_policy_assignment.assignments)
    )
    by_scope = {
      management_groups = length(azurerm_management_group_policy_assignment.assignments)
      subscriptions     = length(azurerm_subscription_policy_assignment.assignments)
      resource_groups   = length(azurerm_resource_group_policy_assignment.assignments)
    }
    caf_assignments = {
      enabled = var.deploy_caf_assignments
      count   = length(local.valid_caf_mg_assignments)
    }
    assignments_with_identity = (
      length(local.mg_assignments_with_identity) +
      length(local.sub_assignments_with_identity) +
      length(local.rg_assignments_with_identity)
    )
    role_assignments_created = (
      length(azurerm_role_assignment.mg_policy_identity) +
      length(azurerm_role_assignment.sub_policy_identity) +
      length(azurerm_role_assignment.rg_policy_identity)
    )
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Remediation Task Helper Output
# ══════════════════════════════════════════════════════════════════════════════

output "remediation_commands" {
  description = "Azure CLI commands to trigger remediation for DeployIfNotExists policies."
  value = {
    for k, v in azurerm_management_group_policy_assignment.assignments : k => 
    "az policy remediation create --name 'remediate-${k}' --policy-assignment '${v.id}' --management-group '${split("/", v.management_group_id)[length(split("/", v.management_group_id)) - 1]}'"
    if length(v.identity) > 0
  }
}
