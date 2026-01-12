# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Outputs - Orchestrator LZA Governance                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════════════════════════════════════════════════════════════════════════════
# F01 - Management Groups Outputs
# ══════════════════════════════════════════════════════════════════════════════

output "root_mg_id" {
  description = "Resource ID of the root intermediate management group."
  value       = module.management_groups.root_mg_id
}

output "root_mg_name" {
  description = "Name of the root intermediate management group."
  value       = module.management_groups.root_mg_name
}

output "platform_mg_id" {
  description = "Resource ID of the Platform management group."
  value       = module.management_groups.platform_mg_id
}

output "landing_zones_mg_id" {
  description = "Resource ID of the Landing Zones management group."
  value       = module.management_groups.landing_zones_mg_id
}

output "all_mg_ids" {
  description = "Map of all management group names to their resource IDs."
  value       = module.management_groups.all_mg_ids
}

output "all_mg_names" {
  description = "Map of all management group logical names to their Azure names."
  value       = module.management_groups.all_mg_names
}

output "archetype_mg_ids" {
  description = "Map of landing zone archetypes to their management group IDs."
  value       = module.management_groups.archetype_mg_ids
}

output "hierarchy" {
  description = "Full management group hierarchy structure for documentation."
  value       = module.management_groups.hierarchy
}

# ══════════════════════════════════════════════════════════════════════════════
# G01 - Policy Definitions Outputs
# ══════════════════════════════════════════════════════════════════════════════

output "policy_definition_ids" {
  description = "Map of custom policy definition names to their resource IDs."
  value       = module.policy_definitions.policy_definition_ids
}

output "policy_definition_names" {
  description = "Map of custom policy definition keys to their display names."
  value       = module.policy_definitions.policy_definition_names
}

output "network_policy_ids" {
  description = "Map of network-related policy definition IDs."
  value       = module.policy_definitions.network_policy_ids
}

output "security_policy_ids" {
  description = "Map of security-related policy definition IDs."
  value       = module.policy_definitions.security_policy_ids
}

output "monitoring_policy_ids" {
  description = "Map of monitoring-related policy definition IDs."
  value       = module.policy_definitions.monitoring_policy_ids
}

output "backup_policy_ids" {
  description = "Map of backup-related policy definition IDs."
  value       = module.policy_definitions.backup_policy_ids
}

output "cost_policy_ids" {
  description = "Map of cost management policy definition IDs."
  value       = module.policy_definitions.cost_policy_ids
}

output "lifecycle_policy_ids" {
  description = "Map of lifecycle management policy definition IDs."
  value       = module.policy_definitions.lifecycle_policy_ids
}

output "builtin_policy_ids" {
  description = "Map of commonly used built-in policy definition IDs."
  value       = module.policy_definitions.builtin_policy_ids
}

output "builtin_initiative_ids_g01" {
  description = "Map of commonly used built-in policy initiative IDs from G01."
  value       = module.policy_definitions.builtin_initiative_ids
}

output "policy_definitions_summary" {
  description = "Summary of deployed policy definitions."
  value       = module.policy_definitions.summary
}

# ══════════════════════════════════════════════════════════════════════════════
# G02 - Policy Set Definitions (Initiatives) Outputs
# ══════════════════════════════════════════════════════════════════════════════

output "caf_initiative_ids" {
  description = "Map of CAF initiative names to their resource IDs."
  value       = module.policy_set_definitions.caf_initiative_ids
}

output "caf_initiative_names" {
  description = "Map of CAF initiative keys to their display names."
  value       = module.policy_set_definitions.caf_initiative_names
}

output "caf_initiatives" {
  description = "Full map of CAF initiatives with all attributes."
  value       = module.policy_set_definitions.caf_initiatives
}

output "all_initiative_ids" {
  description = "Map of all initiative names to their resource IDs."
  value       = module.policy_set_definitions.all_initiative_ids
}

output "archetype_initiative_ids" {
  description = "Map of archetype-specific initiative names to their resource IDs."
  value       = module.policy_set_definitions.archetype_initiative_ids
}

output "baseline_initiative_ids" {
  description = "Map of baseline initiative names to their resource IDs."
  value       = module.policy_set_definitions.baseline_initiative_ids
}

output "builtin_initiatives_for_assignment" {
  description = "Built-in initiative IDs for direct assignment via G03."
  value       = module.policy_set_definitions.builtin_initiatives_for_assignment
}

output "custom_initiative_ids" {
  description = "Map of custom initiative names to their resource IDs."
  value       = module.policy_set_definitions.custom_initiative_ids
}

output "policy_set_definitions_summary" {
  description = "Summary of deployed policy set definitions."
  value       = module.policy_set_definitions.summary
}

# ══════════════════════════════════════════════════════════════════════════════
# G03 - Policy Assignments Outputs
# ══════════════════════════════════════════════════════════════════════════════

output "mg_assignment_ids" {
  description = "Map of management group policy assignment names to their resource IDs."
  value       = module.policy_assignments.mg_assignment_ids
}

output "mg_assignments" {
  description = "Full map of management group policy assignments with all attributes."
  value       = module.policy_assignments.mg_assignments
}

output "mg_assignment_identities" {
  description = "Map of management group assignments to their managed identity principal IDs."
  value       = module.policy_assignments.mg_assignment_identities
}

output "sub_assignment_ids" {
  description = "Map of subscription policy assignment names to their resource IDs."
  value       = module.policy_assignments.sub_assignment_ids
}

output "rg_assignment_ids" {
  description = "Map of resource group policy assignment names to their resource IDs."
  value       = module.policy_assignments.rg_assignment_ids
}

output "all_assignment_ids" {
  description = "Map of all policy assignment names to their resource IDs."
  value       = module.policy_assignments.all_assignment_ids
}

output "all_assignment_principal_ids" {
  description = "Map of all policy assignments with managed identities to their principal IDs."
  value       = module.policy_assignments.all_assignment_principal_ids
}

output "caf_assignment_ids" {
  description = "Map of CAF policy assignment names to their resource IDs."
  value       = module.policy_assignments.caf_assignment_ids
}

output "caf_assignments_by_scope" {
  description = "CAF assignments organized by management group scope."
  value       = module.policy_assignments.caf_assignments_by_scope
}

output "role_assignment_ids" {
  description = "Map of role assignment IDs created for policy managed identities."
  value       = module.policy_assignments.role_assignment_ids
}

output "policy_assignments_summary" {
  description = "Summary of deployed policy assignments."
  value       = module.policy_assignments.summary
}

output "remediation_commands" {
  description = "Azure CLI commands to trigger remediation for DeployIfNotExists policies."
  value       = module.policy_assignments.remediation_commands
}

# ══════════════════════════════════════════════════════════════════════════════
# G04 - Policy Exemptions Outputs
# ══════════════════════════════════════════════════════════════════════════════

output "mg_exemption_ids" {
  description = "Map of management group policy exemption names to their resource IDs."
  value       = var.deploy_exemptions ? module.policy_exemptions[0].mg_exemption_ids : {}
}

output "sub_exemption_ids" {
  description = "Map of subscription policy exemption names to their resource IDs."
  value       = var.deploy_exemptions ? module.policy_exemptions[0].sub_exemption_ids : {}
}

output "rg_exemption_ids" {
  description = "Map of resource group policy exemption names to their resource IDs."
  value       = var.deploy_exemptions ? module.policy_exemptions[0].rg_exemption_ids : {}
}

output "resource_exemption_ids" {
  description = "Map of resource policy exemption names to their resource IDs."
  value       = var.deploy_exemptions ? module.policy_exemptions[0].resource_exemption_ids : {}
}

output "all_exemption_ids" {
  description = "Map of all policy exemption names to their resource IDs."
  value       = var.deploy_exemptions ? module.policy_exemptions[0].all_exemption_ids : {}
}

output "brownfield_exemption_ids" {
  description = "Map of brownfield migration exemption IDs."
  value       = var.deploy_exemptions ? module.policy_exemptions[0].brownfield_exemption_ids : {}
}

output "sandbox_exemption_ids" {
  description = "Map of Sandbox exemption IDs."
  value       = var.deploy_exemptions ? module.policy_exemptions[0].sandbox_exemption_ids : {}
}

output "exemptions_by_category" {
  description = "Exemptions organized by category (Waiver vs Mitigated)."
  value       = var.deploy_exemptions ? module.policy_exemptions[0].exemptions_by_category : {}
}

output "waivers_without_expiration" {
  description = "List of Waiver exemptions without expiration dates (compliance warning)."
  value       = var.deploy_exemptions ? module.policy_exemptions[0].waivers_without_expiration : []
}

output "policy_exemptions_summary" {
  description = "Summary of deployed policy exemptions."
  value       = var.deploy_exemptions ? module.policy_exemptions[0].summary : null
}

output "audit_report" {
  description = "Audit report for compliance review - lists all exemptions with their justifications."
  value       = var.deploy_exemptions ? module.policy_exemptions[0].audit_report : null
}

# ══════════════════════════════════════════════════════════════════════════════
# Orchestrator Summary
# ══════════════════════════════════════════════════════════════════════════════

output "orchestrator_summary" {
  description = "Overall summary of the orchestrator deployment."
  value = {
    deployment_info = local.deployment_summary
    
    management_groups = {
      root_mg_id        = module.management_groups.root_mg_id
      total_mg_count    = length([for k, v in module.management_groups.all_mg_ids : v if v != null])
      platform_enabled  = var.deploy_platform_mg
      lz_enabled        = var.deploy_landing_zones_mg
      sandbox_enabled   = var.deploy_sandbox_mg
    }
    
    policy_definitions = {
      total_custom      = module.policy_definitions.summary.total_custom_policies
      caf_enabled       = var.deploy_caf_policies
      categories        = module.policy_definitions.summary.categories
    }
    
    policy_initiatives = {
      total_initiatives = module.policy_set_definitions.summary.total_initiatives
      caf_count         = module.policy_set_definitions.summary.caf_initiatives_count
      custom_count      = module.policy_set_definitions.summary.custom_initiatives_count
    }
    
    policy_assignments = {
      total_assignments = module.policy_assignments.summary.total_assignments
      by_scope          = module.policy_assignments.summary.by_scope
      caf_enabled       = var.deploy_caf_assignments
      with_identity     = module.policy_assignments.summary.assignments_with_identity
    }
    
    policy_exemptions = var.deploy_exemptions ? {
      total_exemptions  = module.policy_exemptions[0].summary.total_exemptions
      by_scope          = module.policy_exemptions[0].summary.by_scope
      by_category       = module.policy_exemptions[0].summary.by_category
      brownfield        = module.policy_exemptions[0].summary.brownfield_migration
    } : null
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Quick Reference Outputs
# ══════════════════════════════════════════════════════════════════════════════

output "quick_reference" {
  description = "Quick reference for commonly needed IDs and commands."
  value = {
    # Management Group IDs for subscription placement
    mg_ids_for_subscription_placement = {
      corp_prod      = module.management_groups.corp_prod_mg_id
      corp_nonprod   = module.management_groups.corp_nonprod_mg_id
      online_prod    = module.management_groups.online_prod_mg_id
      online_nonprod = module.management_groups.online_nonprod_mg_id
      sandbox        = module.management_groups.sandbox_mg_id
    }
    
    # Initiative IDs for manual assignments
    initiative_ids_for_assignment = module.policy_set_definitions.all_initiative_ids
    
    # Assignment IDs for creating exemptions
    assignment_ids_for_exemptions = module.policy_assignments.mg_assignment_ids
    
    # Remediation commands for DINE policies
    remediation_needed = length(module.policy_assignments.remediation_commands) > 0
    remediation_count  = length(module.policy_assignments.remediation_commands)
  }
}
