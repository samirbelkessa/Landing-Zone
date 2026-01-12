# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Outputs - Policy Set Definitions (Initiatives)                                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════════════════════════════════════════════════════════════════════════════
# CAF Initiative Outputs
# ══════════════════════════════════════════════════════════════════════════════

output "caf_initiative_ids" {
  description = "Map of CAF initiative names to their resource IDs."
  value = {
    for k, v in azurerm_policy_set_definition.caf_initiatives : k => v.id
  }
}

output "caf_initiative_names" {
  description = "Map of CAF initiative keys to their display names."
  value = {
    for k, v in azurerm_policy_set_definition.caf_initiatives : k => v.display_name
  }
}

output "caf_initiatives" {
  description = "Full map of CAF initiatives with all attributes."
  value = {
    for k, v in azurerm_policy_set_definition.caf_initiatives : k => {
      id                  = v.id
      name                = v.name
      display_name        = v.display_name
      description         = v.description
      policy_type         = v.policy_type
      management_group_id = v.management_group_id
      metadata            = v.metadata
    }
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Built-in Initiatives for Direct Assignment (via G03)
# ══════════════════════════════════════════════════════════════════════════════

output "builtin_initiatives_for_assignment" {
  description = "Built-in initiative IDs that should be assigned directly via G03 (not nested in custom initiatives)."
  value = {
    azure_security_benchmark = var.include_azure_security_benchmark ? "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8" : null
    vm_insights              = var.include_vm_insights ? "/providers/Microsoft.Authorization/policySetDefinitions/924bfe3a-762f-40e7-86dd-5c8b95eb09e6" : null
    nist_sp_800_53_r5        = var.include_nist_initiative ? "/providers/Microsoft.Authorization/policySetDefinitions/179d1daa-458f-4e47-8086-2a68d0d6c38f" : null
    iso_27001_2013           = var.include_iso27001_initiative ? "/providers/Microsoft.Authorization/policySetDefinitions/89c6cddc-1c73-4ac1-b19c-54d1a15a42f2" : null
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Custom Initiative Outputs
# ══════════════════════════════════════════════════════════════════════════════

output "custom_initiative_ids" {
  description = "Map of custom initiative names to their resource IDs."
  value = {
    for k, v in azurerm_policy_set_definition.custom_initiatives : k => v.id
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# All Initiatives Combined
# ══════════════════════════════════════════════════════════════════════════════

output "all_initiative_ids" {
  description = "Map of all custom initiative names (CAF) to their resource IDs."
  value = merge(
    { for k, v in azurerm_policy_set_definition.caf_initiatives : k => v.id },
    { for k, v in azurerm_policy_set_definition.custom_initiatives : k => v.id }
  )
}

# ══════════════════════════════════════════════════════════════════════════════
# Archetype-Specific Initiative Outputs
# ══════════════════════════════════════════════════════════════════════════════

output "archetype_initiative_ids" {
  description = "Map of archetype-specific initiative names to their resource IDs. Use these for Landing Zone assignments."
  value = {
    for k, v in azurerm_policy_set_definition.caf_initiatives : k => v.id
    if startswith(k, "caf-online-") || startswith(k, "caf-corp-") || k == "caf-sandbox" || k == "caf-decommissioned"
  }
}

output "baseline_initiative_ids" {
  description = "Map of baseline initiative names to their resource IDs. Use these for Root/Platform assignments."
  value = {
    for k, v in azurerm_policy_set_definition.caf_initiatives : k => v.id
    if contains(["caf-security-baseline", "caf-network-baseline", "caf-monitoring-baseline", "caf-governance-baseline", "caf-backup-baseline", "caf-cost-baseline", "caf-identity-baseline"], k)
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Summary Output
# ══════════════════════════════════════════════════════════════════════════════

output "summary" {
  description = "Summary of deployed policy set definitions."
  value = {
    management_group_id       = var.management_group_id
    total_initiatives         = length(azurerm_policy_set_definition.caf_initiatives) + length(azurerm_policy_set_definition.custom_initiatives)
    caf_initiatives_count     = length(azurerm_policy_set_definition.caf_initiatives)
    custom_initiatives_count  = length(azurerm_policy_set_definition.custom_initiatives)
    builtin_initiatives_enabled = {
      azure_security_benchmark = var.include_azure_security_benchmark
      vm_insights              = var.include_vm_insights
      nist_sp_800_53           = var.include_nist_initiative
      iso_27001                = var.include_iso27001_initiative
    }
    deployed_archetypes = [
      for archetype in var.archetypes_to_deploy : archetype
      if var.deploy_archetype_initiatives
    ]
    baseline_initiatives = [
      for k, v in azurerm_policy_set_definition.caf_initiatives : v.display_name
      if contains(["caf-security-baseline", "caf-network-baseline", "caf-monitoring-baseline", "caf-governance-baseline", "caf-backup-baseline", "caf-cost-baseline", "caf-identity-baseline"], k)
    ]
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Built-in Initiative References
# ══════════════════════════════════════════════════════════════════════════════

output "builtin_initiative_ids" {
  description = "Reference to built-in Azure Policy initiative IDs used in this module."
  value = {
    azure_security_benchmark = "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8"
    vm_insights              = "/providers/Microsoft.Authorization/policySetDefinitions/924bfe3a-762f-40e7-86dd-5c8b95eb09e6"
    nist_sp_800_53_r5        = "/providers/Microsoft.Authorization/policySetDefinitions/179d1daa-458f-4e47-8086-2a68d0d6c38f"
    iso_27001_2013           = "/providers/Microsoft.Authorization/policySetDefinitions/89c6cddc-1c73-4ac1-b19c-54d1a15a42f2"
  }
}
