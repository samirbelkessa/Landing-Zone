# =============================================================================
# OUTPUTS.TF - Identity Orchestrator Outputs
# =============================================================================
# Orchestrator: 05-identity
# Purpose: Expose identity resources for downstream consumption
# =============================================================================

# =============================================================================
# ROLE ASSIGNMENTS
# =============================================================================

output "role_assignments_summary" {
  description = "Summary of role assignments created."
  value = {
    for key, assignment in local.role_assignments_resolved :
    key => {
      group           = assignment.group_display_name
      role            = assignment.role_name
      scope           = assignment.scope
      scope_type      = can(regex("managementGroups", assignment.scope)) ? "management_group" : "subscription"
    }
    if assignment.scope != null
  }
}

output "role_assignments_count" {
  description = "Number of role assignments created."
  value       = var.deploy_role_assignments ? length([for k, v in local.role_assignments_resolved : k if v.scope != null]) : 0
}

# =============================================================================
# MANAGED IDENTITIES
# =============================================================================

output "managed_identity_ids" {
  description = "Map of managed identity resource IDs."
  value = {
    for key, mi in module.managed_identities :
    key => mi.resource_id
  }
}

output "managed_identity_principal_ids" {
  description = "Map of managed identity principal IDs (for role assignments)."
  value = {
    for key, mi in module.managed_identities :
    key => mi.principal_id
  }
}

output "managed_identity_client_ids" {
  description = "Map of managed identity client IDs (for authentication)."
  value = {
    for key, mi in module.managed_identities :
    key => mi.client_id
  }
}

# =============================================================================
# RESOURCE GROUP
# =============================================================================

output "resource_group_name" {
  description = "Name of the identity resource group."
  value       = var.deploy_managed_identities ? azurerm_resource_group.identity[0].name : null
}

output "resource_group_id" {
  description = "ID of the identity resource group."
  value       = var.deploy_managed_identities ? azurerm_resource_group.identity[0].id : null
}

# =============================================================================
# TAGS
# =============================================================================

output "tags" {
  description = "Tags applied to identity resources."
  value       = local.tags
}

# =============================================================================
# DEPLOYMENT STATUS
# =============================================================================

output "deployment_status" {
  description = "Status of each module deployment."
  value = {
    role_assignments   = var.deploy_role_assignments ? "deployed" : "skipped"
    managed_identities = var.deploy_managed_identities ? "deployed" : "skipped"
    resource_group     = var.deploy_managed_identities ? "deployed" : "skipped"
  }
}

# =============================================================================
# CONFIGURATION SUMMARY
# =============================================================================

output "identity_config" {
  description = "Complete identity configuration for downstream consumption."
  value = {
    tenant_id       = var.tenant_id
    subscription_id = var.identity_subscription_id
    location        = var.location
    environment     = var.environment
    
    role_assignments = {
      count   = var.deploy_role_assignments ? length([for k, v in local.role_assignments_resolved : k if v.scope != null]) : 0
      enabled = var.deploy_role_assignments
    }
    
    managed_identities = {
      count   = var.deploy_managed_identities ? length(var.managed_identities) : 0
      enabled = var.deploy_managed_identities
      ids     = var.deploy_managed_identities ? { for key, mi in module.managed_identities : key => mi.principal_id } : {}
    }
  }
}
