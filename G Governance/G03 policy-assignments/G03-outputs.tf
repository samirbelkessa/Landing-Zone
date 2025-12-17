################################################################################
# Outputs - Policy Assignments (G03)
################################################################################

# ══════════════════════════════════════════════════════════════════════════════
# Policy Assignment IDs
# ══════════════════════════════════════════════════════════════════════════════

output "policy_assignment_ids" {
  description = "Map of policy assignment names to their resource IDs."
  value = {
    for k, v in azurerm_management_group_policy_assignment.policies : k => v.id
  }
}

output "initiative_assignment_ids" {
  description = "Map of initiative assignment names to their resource IDs."
  value = {
    for k, v in azurerm_management_group_policy_assignment.initiatives : k => v.id
  }
}

output "custom_assignment_ids" {
  description = "Map of custom policy assignment names to their resource IDs."
  value = {
    for k, v in azurerm_management_group_policy_assignment.custom : k => v.id
  }
}

output "all_assignment_ids" {
  description = "Map of all assignment names to their resource IDs."
  value = merge(
    { for k, v in azurerm_management_group_policy_assignment.policies : k => v.id },
    { for k, v in azurerm_management_group_policy_assignment.initiatives : k => v.id },
    { for k, v in azurerm_management_group_policy_assignment.custom : k => v.id }
  )
}

# ══════════════════════════════════════════════════════════════════════════════
# Assignments by Scope
# ══════════════════════════════════════════════════════════════════════════════

output "assignments_by_scope" {
  description = "Map of management group names to their assigned policies and initiatives."
  value = {
    root = {
      policies = [
        for k, v in azurerm_management_group_policy_assignment.policies : v.display_name
        if v.management_group_id == local.mg_root
      ]
      initiatives = [
        for k, v in azurerm_management_group_policy_assignment.initiatives : v.display_name
        if v.management_group_id == local.mg_root
      ]
    }
    platform = {
      policies = [
        for k, v in azurerm_management_group_policy_assignment.policies : v.display_name
        if v.management_group_id == local.mg_platform
      ]
      initiatives = [
        for k, v in azurerm_management_group_policy_assignment.initiatives : v.display_name
        if v.management_group_id == local.mg_platform
      ]
    }
    connectivity = {
      policies = [
        for k, v in azurerm_management_group_policy_assignment.policies : v.display_name
        if v.management_group_id == local.mg_connectivity
      ]
      initiatives = [
        for k, v in azurerm_management_group_policy_assignment.initiatives : v.display_name
        if v.management_group_id == local.mg_connectivity
      ]
    }
    landing_zones = {
      policies = [
        for k, v in azurerm_management_group_policy_assignment.policies : v.display_name
        if v.management_group_id == local.mg_landing_zones
      ]
      initiatives = [
        for k, v in azurerm_management_group_policy_assignment.initiatives : v.display_name
        if v.management_group_id == local.mg_landing_zones
      ]
    }
    online_prod = {
      policies = [
        for k, v in azurerm_management_group_policy_assignment.policies : v.display_name
        if v.management_group_id == local.mg_online_prod
      ]
      initiatives = [
        for k, v in azurerm_management_group_policy_assignment.initiatives : v.display_name
        if v.management_group_id == local.mg_online_prod
      ]
    }
    online_nonprod = {
      policies = [
        for k, v in azurerm_management_group_policy_assignment.policies : v.display_name
        if v.management_group_id == local.mg_online_nonprod
      ]
      initiatives = [
        for k, v in azurerm_management_group_policy_assignment.initiatives : v.display_name
        if v.management_group_id == local.mg_online_nonprod
      ]
    }
    corp_prod = {
      policies = [
        for k, v in azurerm_management_group_policy_assignment.policies : v.display_name
        if v.management_group_id == local.mg_corp_prod
      ]
      initiatives = [
        for k, v in azurerm_management_group_policy_assignment.initiatives : v.display_name
        if v.management_group_id == local.mg_corp_prod
      ]
    }
    corp_nonprod = {
      policies = [
        for k, v in azurerm_management_group_policy_assignment.policies : v.display_name
        if v.management_group_id == local.mg_corp_nonprod
      ]
      initiatives = [
        for k, v in azurerm_management_group_policy_assignment.initiatives : v.display_name
        if v.management_group_id == local.mg_corp_nonprod
      ]
    }
    sandbox = {
      policies = [
        for k, v in azurerm_management_group_policy_assignment.policies : v.display_name
        if v.management_group_id == local.mg_sandbox
      ]
      initiatives = [
        for k, v in azurerm_management_group_policy_assignment.initiatives : v.display_name
        if v.management_group_id == local.mg_sandbox
      ]
    }
    decommissioned = {
      policies = [
        for k, v in azurerm_management_group_policy_assignment.policies : v.display_name
        if v.management_group_id == local.mg_decommissioned
      ]
      initiatives = [
        for k, v in azurerm_management_group_policy_assignment.initiatives : v.display_name
        if v.management_group_id == local.mg_decommissioned
      ]
    }
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Assignments with Enforcement Details
# ══════════════════════════════════════════════════════════════════════════════

output "policy_assignments_detailed" {
  description = "Detailed information about all policy assignments."
  value = {
    for k, v in azurerm_management_group_policy_assignment.policies : k => {
      id                   = v.id
      name                 = v.name
      display_name         = v.display_name
      management_group_id  = v.management_group_id
      policy_definition_id = v.policy_definition_id
      enforcement_mode     = v.enforcement_mode
      has_identity         = try(v.identity[0].type, null) != null
      identity_type        = try(v.identity[0].type, "None")
      identity_principal_id = try(v.identity[0].principal_id, null)
    }
  }
}

output "initiative_assignments_detailed" {
  description = "Detailed information about all initiative assignments."
  value = {
    for k, v in azurerm_management_group_policy_assignment.initiatives : k => {
      id                   = v.id
      name                 = v.name
      display_name         = v.display_name
      management_group_id  = v.management_group_id
      policy_definition_id = v.policy_definition_id
      enforcement_mode     = v.enforcement_mode
      has_identity         = try(v.identity[0].type, null) != null
      identity_type        = try(v.identity[0].type, "None")
      identity_principal_id = try(v.identity[0].principal_id, null)
    }
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Managed Identity Outputs
# ══════════════════════════════════════════════════════════════════════════════

output "remediation_identity" {
  description = "User Assigned Managed Identity for policy remediation."
  value = var.create_remediation_identity && var.remediation_identity_resource_group != "" ? {
    id           = azurerm_user_assigned_identity.remediation[0].id
    client_id    = azurerm_user_assigned_identity.remediation[0].client_id
    principal_id = azurerm_user_assigned_identity.remediation[0].principal_id
    tenant_id    = azurerm_user_assigned_identity.remediation[0].tenant_id
    name         = azurerm_user_assigned_identity.remediation[0].name
  } : null
}

output "system_assigned_identities" {
  description = "Map of assignment names to their System Assigned Managed Identity principal IDs."
  value = merge(
    {
      for k, v in azurerm_management_group_policy_assignment.policies :
      k => v.identity[0].principal_id
      if try(v.identity[0].type, "") == "SystemAssigned"
    },
    {
      for k, v in azurerm_management_group_policy_assignment.initiatives :
      k => v.identity[0].principal_id
      if try(v.identity[0].type, "") == "SystemAssigned"
    }
  )
}

# ══════════════════════════════════════════════════════════════════════════════
# Role Assignment Outputs
# ══════════════════════════════════════════════════════════════════════════════

output "role_assignments" {
  description = "Map of role assignment IDs for policy remediation identities."
  value = {
    contributor = {
      for k, v in azurerm_role_assignment.policy_remediation_contributor : k => v.id
    }
    monitoring_contributor = {
      for k, v in azurerm_role_assignment.policy_remediation_monitoring_contributor : k => v.id
    }
    log_analytics_contributor = {
      for k, v in azurerm_role_assignment.policy_remediation_log_analytics_contributor : k => v.id
    }
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Assignments Requiring Remediation
# ══════════════════════════════════════════════════════════════════════════════

output "assignments_requiring_remediation" {
  description = "List of assignments that have DeployIfNotExists or Modify effects and require remediation."
  value = [
    for k, v in merge(
      azurerm_management_group_policy_assignment.policies,
      azurerm_management_group_policy_assignment.initiatives
    ) : {
      name         = v.name
      display_name = v.display_name
      id           = v.id
      identity_id  = try(v.identity[0].principal_id, null)
    }
    if try(v.identity[0].type, null) != null
  ]
}

# ══════════════════════════════════════════════════════════════════════════════
# Summary Output
# ══════════════════════════════════════════════════════════════════════════════

output "summary" {
  description = "Summary of all policy assignments."
  value = {
    total_policy_assignments     = length(azurerm_management_group_policy_assignment.policies)
    total_initiative_assignments = length(azurerm_management_group_policy_assignment.initiatives)
    total_custom_assignments     = length(azurerm_management_group_policy_assignment.custom)
    total_all_assignments        = (
      length(azurerm_management_group_policy_assignment.policies) +
      length(azurerm_management_group_policy_assignment.initiatives) +
      length(azurerm_management_group_policy_assignment.custom)
    )
    
    enforcement_mode_override = var.enforcement_mode_override
    
    assignments_with_identity = length([
      for v in merge(
        azurerm_management_group_policy_assignment.policies,
        azurerm_management_group_policy_assignment.initiatives
      ) : v if try(v.identity[0].type, null) != null
    ])
    
    scopes_with_assignments = distinct([
      for v in merge(
        azurerm_management_group_policy_assignment.policies,
        azurerm_management_group_policy_assignment.initiatives
      ) : v.management_group_id
    ])
    
    builtin_initiatives_assigned = {
      azure_security_benchmark = var.assign_azure_security_benchmark
      vm_insights              = var.assign_vm_insights
      nist_sp_800_53           = var.assign_nist_sp_800_53
      iso_27001                = var.assign_iso_27001
    }

    remediation_identity_created = var.create_remediation_identity && var.remediation_identity_resource_group != ""
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# For Integration with G04 (Policy Exemptions)
# ══════════════════════════════════════════════════════════════════════════════

output "assignments_for_exemptions" {
  description = "Structured output for creating policy exemptions in module G04."
  value = {
    for k, v in merge(
      azurerm_management_group_policy_assignment.policies,
      azurerm_management_group_policy_assignment.initiatives
    ) : k => {
      id                   = v.id
      name                 = v.name
      display_name         = v.display_name
      management_group_id  = v.management_group_id
      policy_definition_id = v.policy_definition_id
      enforcement_mode     = v.enforcement_mode
    }
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Archetype Assignment Status
# ══════════════════════════════════════════════════════════════════════════════

output "archetype_assignments_status" {
  description = "Status of archetype-specific policy assignments."
  value = {
    online_prod = {
      enabled = local.mg_online_prod != "" && var.deploy_landing_zone_assignments
      assignment_count = length([
        for k, v in merge(
          azurerm_management_group_policy_assignment.policies,
          azurerm_management_group_policy_assignment.initiatives
        ) : v if v.management_group_id == local.mg_online_prod
      ])
    }
    online_nonprod = {
      enabled = local.mg_online_nonprod != "" && var.deploy_landing_zone_assignments
      assignment_count = length([
        for k, v in merge(
          azurerm_management_group_policy_assignment.policies,
          azurerm_management_group_policy_assignment.initiatives
        ) : v if v.management_group_id == local.mg_online_nonprod
      ])
    }
    corp_prod = {
      enabled = local.mg_corp_prod != "" && var.deploy_landing_zone_assignments
      assignment_count = length([
        for k, v in merge(
          azurerm_management_group_policy_assignment.policies,
          azurerm_management_group_policy_assignment.initiatives
        ) : v if v.management_group_id == local.mg_corp_prod
      ])
    }
    corp_nonprod = {
      enabled = local.mg_corp_nonprod != "" && var.deploy_landing_zone_assignments
      assignment_count = length([
        for k, v in merge(
          azurerm_management_group_policy_assignment.policies,
          azurerm_management_group_policy_assignment.initiatives
        ) : v if v.management_group_id == local.mg_corp_nonprod
      ])
    }
    sandbox = {
      enabled = local.mg_sandbox != "" && var.deploy_landing_zone_assignments
      assignment_count = length([
        for k, v in merge(
          azurerm_management_group_policy_assignment.policies,
          azurerm_management_group_policy_assignment.initiatives
        ) : v if v.management_group_id == local.mg_sandbox
      ])
    }
    decommissioned = {
      enabled = local.mg_decommissioned != "" && var.deploy_decommissioned_assignments
      assignment_count = length([
        for k, v in merge(
          azurerm_management_group_policy_assignment.policies,
          azurerm_management_group_policy_assignment.initiatives
        ) : v if v.management_group_id == local.mg_decommissioned
      ])
    }
  }
}
