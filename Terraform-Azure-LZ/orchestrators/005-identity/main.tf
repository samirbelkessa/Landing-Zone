# =============================================================================
# MAIN.TF - Identity Resources
# =============================================================================
# Orchestrator: 05-identity
# Purpose: Deploy RBAC Role Assignments and Managed Identities
# Uses: Native azurerm resources + AVM Managed Identity module
# =============================================================================

# =============================================================================
# RESOURCE GROUP (for Managed Identities)
# =============================================================================

resource "azurerm_resource_group" "identity" {
  count = var.deploy_managed_identities ? 1 : 0

  name     = local.resource_group_name
  location = var.location

  tags = local.tags
}

# =============================================================================
# ROLE ASSIGNMENTS - Using Native azurerm_role_assignment
# =============================================================================
# Simple, reliable, no external module dependency
# =============================================================================

resource "azurerm_role_assignment" "group_assignments" {
  for_each = var.deploy_role_assignments ? {
    for key, assignment in local.role_assignments_resolved :
    key => assignment
    if assignment.scope != null
  } : {}

  scope                = each.value.scope
  role_definition_name = each.value.role_name
  principal_id         = each.value.principal_id
  description          = each.value.description

  skip_service_principal_aad_check = false
}

# =============================================================================
# MANAGED IDENTITIES - Using AVM Resource Module
# =============================================================================
# Module: Azure/avm-res-managedidentity-userassignedidentity/azurerm
# Documentation: https://github.com/Azure/terraform-azurerm-avm-res-managedidentity-userassignedidentity
# =============================================================================

module "managed_identities" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "~> 0.3"

  for_each = var.deploy_managed_identities ? local.managed_identities_resolved : {}

  name                = each.value.name
  resource_group_name = azurerm_resource_group.identity[0].name
  location            = var.location

  tags = local.tags

  enable_telemetry = false
}

# =============================================================================
# ROLE ASSIGNMENTS FOR MANAGED IDENTITIES
# =============================================================================

resource "azurerm_role_assignment" "managed_identity_roles" {
  for_each = var.deploy_managed_identities ? merge([
    for mi_key, mi in local.managed_identities_resolved : {
      for ra_key, ra in mi.role_assignments :
      "${mi_key}-${ra_key}" => {
        principal_id         = module.managed_identities[mi_key].principal_id
        role_definition_name = ra.role_name
        scope                = ra.scope
      }
      if ra.scope != null
    }
  ]...) : {}

  principal_id         = each.value.principal_id
  role_definition_name = each.value.role_definition_name
  scope                = each.value.scope

  skip_service_principal_aad_check = true
}