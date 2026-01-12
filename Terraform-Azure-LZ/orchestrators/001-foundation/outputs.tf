# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Outputs - Orchestrator Foundation                                             ║
# ║ CRITICAL: These outputs are consumed by ALL other orchestrators               ║
# ║ - 02-governance reads: root_mg_id, all_mg_ids, deployment_flags               ║
# ║ - 03-management reads: management_mg_id, root_id                              ║
# ║ - 04-connectivity reads: connectivity_mg_id, root_id, locations               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════════════════════════════════════════════════════════════════════════════
# Organization Identity
# ══════════════════════════════════════════════════════════════════════════════

output "root_id" {
  description = "The root_id used for naming convention (e.g., 'intelly')."
  value       = var.root_id
}

output "root_name" {
  description = "The display name of the organization."
  value       = var.root_name
}

output "tenant_id" {
  description = "The Azure AD Tenant ID."
  value       = var.root_parent_id
}

# ══════════════════════════════════════════════════════════════════════════════
# Location Configuration
# ══════════════════════════════════════════════════════════════════════════════

output "primary_location" {
  description = "Primary Azure region."
  value       = var.default_location
}

output "secondary_location" {
  description = "Secondary Azure region for DR."
  value       = var.secondary_location
}

output "allowed_regions" {
  description = "List of allowed Azure regions for policy enforcement."
  value       = var.allowed_regions
}

# ══════════════════════════════════════════════════════════════════════════════
# Management Group IDs - Individual
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

output "management_mg_id" {
  description = "Resource ID of the Management management group."
  value       = module.management_groups.management_mg_id
}

output "connectivity_mg_id" {
  description = "Resource ID of the Connectivity management group."
  value       = module.management_groups.connectivity_mg_id
}

output "identity_mg_id" {
  description = "Resource ID of the Identity management group."
  value       = module.management_groups.identity_mg_id
}

output "landing_zones_mg_id" {
  description = "Resource ID of the Landing Zones management group."
  value       = module.management_groups.landing_zones_mg_id
}

output "corp_prod_mg_id" {
  description = "Resource ID of the Corp-Prod management group."
  value       = module.management_groups.corp_prod_mg_id
}

output "corp_nonprod_mg_id" {
  description = "Resource ID of the Corp-NonProd management group."
  value       = module.management_groups.corp_nonprod_mg_id
}

output "online_prod_mg_id" {
  description = "Resource ID of the Online-Prod management group."
  value       = module.management_groups.online_prod_mg_id
}

output "online_nonprod_mg_id" {
  description = "Resource ID of the Online-NonProd management group."
  value       = module.management_groups.online_nonprod_mg_id
}

output "sandbox_mg_id" {
  description = "Resource ID of the Sandbox management group."
  value       = module.management_groups.sandbox_mg_id
}

output "decommissioned_mg_id" {
  description = "Resource ID of the Decommissioned management group."
  value       = module.management_groups.decommissioned_mg_id
}

# ══════════════════════════════════════════════════════════════════════════════
# Management Group IDs - Aggregated Map
# Used by 02-governance for policy assignments
# ══════════════════════════════════════════════════════════════════════════════

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

# ══════════════════════════════════════════════════════════════════════════════
# Deployment Flags - STATIC values for 02-governance
# These are CRITICAL to avoid the for_each error in G03
# ══════════════════════════════════════════════════════════════════════════════

output "deployment_flags" {
  description = "Static deployment flags for governance orchestrator. Used to determine which policy assignments to create."
  value = {
    # Platform MG flags
    deploy_platform_mg       = var.deploy_platform_mg
    deploy_landing_zones_mg  = var.deploy_landing_zones_mg
    deploy_decommissioned_mg = var.deploy_decommissioned_mg
    
    # Archetype flags - STATIC booleans, NOT dynamic ID checks
    deploy_online_prod    = var.deploy_online_landing_zones && var.deploy_prod_nonprod_separation && var.deploy_landing_zones_mg
    deploy_online_nonprod = var.deploy_online_landing_zones && var.deploy_prod_nonprod_separation && var.deploy_landing_zones_mg
    deploy_corp_prod      = var.deploy_corp_landing_zones && var.deploy_prod_nonprod_separation && var.deploy_landing_zones_mg
    deploy_corp_nonprod   = var.deploy_corp_landing_zones && var.deploy_prod_nonprod_separation && var.deploy_landing_zones_mg
    deploy_sandbox        = var.deploy_sandbox_mg && var.deploy_landing_zones_mg
    deploy_decommissioned = var.deploy_decommissioned_mg
    
    # Single MG flags (when prod/nonprod separation is disabled)
    deploy_corp_single   = var.deploy_corp_landing_zones && !var.deploy_prod_nonprod_separation && var.deploy_landing_zones_mg
    deploy_online_single = var.deploy_online_landing_zones && !var.deploy_prod_nonprod_separation && var.deploy_landing_zones_mg
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Custom Management Groups
# ══════════════════════════════════════════════════════════════════════════════

output "custom_platform_mg_ids" {
  description = "Map of custom Platform child management group IDs."
  value       = module.management_groups.custom_platform_mg_ids
}

output "custom_landing_zone_mg_ids" {
  description = "Map of custom Landing Zone child management group IDs."
  value       = module.management_groups.custom_landing_zone_mg_ids
}

# ══════════════════════════════════════════════════════════════════════════════
# Hierarchy Visualization
# ══════════════════════════════════════════════════════════════════════════════

output "hierarchy" {
  description = "Full management group hierarchy structure for documentation."
  value       = module.management_groups.hierarchy
}

# ══════════════════════════════════════════════════════════════════════════════
# Tags Configuration
# ══════════════════════════════════════════════════════════════════════════════

output "common_tags" {
  description = "Common tags to be applied across all resources."
  value = merge(
    {
      ManagedBy   = "Terraform"
      Environment = "Platform"
      Project     = var.root_name
    },
    var.tags
  )
}
