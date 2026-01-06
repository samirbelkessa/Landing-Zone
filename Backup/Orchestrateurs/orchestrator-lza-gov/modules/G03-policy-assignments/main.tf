# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Main - Policy Assignments (G03)                                               ║
# ║ Creates Azure Policy Assignments at various scopes                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════════════════════════════════════════════════════════════════════════════
# Management Group Policy Assignments
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_management_group_policy_assignment" "assignments" {
  for_each = local.all_mg_assignments

  name                 = substr(each.key, 0, 24) # Max 24 characters
  management_group_id  = each.value.management_group_id
  policy_definition_id = each.value.policy_set_definition_id != null ? each.value.policy_set_definition_id : each.value.policy_definition_id
  
  display_name = each.value.display_name
  description  = each.value.description != "" ? each.value.description : null
  enforce      = each.value.enforce
  
  parameters = each.value.parameters
  metadata   = each.value.metadata != null ? each.value.metadata : local.standard_metadata
  
  not_scopes = each.value.not_scopes

  location = each.value.identity_type != "None" ? coalesce(each.value.location, var.default_location) : null

  # Managed Identity configuration
  dynamic "identity" {
    for_each = each.value.identity_type != "None" ? [1] : []
    content {
      type         = each.value.identity_type
      identity_ids = each.value.identity_type == "UserAssigned" ? each.value.identity_ids : null
    }
  }

  # Non-compliance message
  dynamic "non_compliance_message" {
    for_each = each.value.non_compliance_message != null ? [1] : []
    content {
      content = each.value.non_compliance_message
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Subscription Policy Assignments
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_subscription_policy_assignment" "assignments" {
  for_each = var.subscription_assignments

  name            = substr(each.key, 0, 24)
  subscription_id = each.value.subscription_id
  policy_definition_id = each.value.policy_set_definition_id != null ? each.value.policy_set_definition_id : each.value.policy_definition_id
  
  display_name = each.value.display_name
  description  = each.value.description != "" ? each.value.description : null
  enforce      = each.value.enforce
  
  parameters = each.value.parameters
  metadata   = each.value.metadata != null ? each.value.metadata : local.standard_metadata
  
  not_scopes = each.value.not_scopes

  location = each.value.identity_type != "None" ? coalesce(each.value.location, var.default_location) : null

  dynamic "identity" {
    for_each = each.value.identity_type != "None" ? [1] : []
    content {
      type         = each.value.identity_type
      identity_ids = each.value.identity_type == "UserAssigned" ? each.value.identity_ids : null
    }
  }

  dynamic "non_compliance_message" {
    for_each = each.value.non_compliance_message != null ? [1] : []
    content {
      content = each.value.non_compliance_message
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Resource Group Policy Assignments
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_resource_group_policy_assignment" "assignments" {
  for_each = var.resource_group_assignments

  name              = substr(each.key, 0, 24)
  resource_group_id = each.value.resource_group_id
  policy_definition_id = each.value.policy_set_definition_id != null ? each.value.policy_set_definition_id : each.value.policy_definition_id
  
  display_name = each.value.display_name
  description  = each.value.description != "" ? each.value.description : null
  enforce      = each.value.enforce
  
  parameters = each.value.parameters
  metadata   = each.value.metadata != null ? each.value.metadata : local.standard_metadata
  
  not_scopes = each.value.not_scopes

  location = each.value.identity_type != "None" ? coalesce(each.value.location, var.default_location) : null

  dynamic "identity" {
    for_each = each.value.identity_type != "None" ? [1] : []
    content {
      type         = each.value.identity_type
      identity_ids = each.value.identity_type == "UserAssigned" ? each.value.identity_ids : null
    }
  }

  dynamic "non_compliance_message" {
    for_each = each.value.non_compliance_message != null ? [1] : []
    content {
      content = each.value.non_compliance_message
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Role Assignments for Policy Managed Identities
# ══════════════════════════════════════════════════════════════════════════════
# DeployIfNotExists and Modify policies require role assignments for their
# managed identities to perform remediation tasks.

# Role assignments for Management Group policy assignments
resource "azurerm_role_assignment" "mg_policy_identity" {
  for_each = var.create_role_assignments ? {
    for k, v in local.mg_assignments_with_identity : k => v
    if v.identity_type == "SystemAssigned"
  } : {}

  scope                = each.value.management_group_id
  role_definition_id   = lookup(var.role_definition_ids, each.key, [var.default_role_definition_id])[0]
  principal_id         = azurerm_management_group_policy_assignment.assignments[each.key].identity[0].principal_id
  skip_service_principal_aad_check = true

  depends_on = [azurerm_management_group_policy_assignment.assignments]
}

# Role assignments for Subscription policy assignments
resource "azurerm_role_assignment" "sub_policy_identity" {
  for_each = var.create_role_assignments ? {
    for k, v in local.sub_assignments_with_identity : k => v
    if v.identity_type == "SystemAssigned"
  } : {}

  scope                = each.value.subscription_id
  role_definition_id   = lookup(var.role_definition_ids, each.key, [var.default_role_definition_id])[0]
  principal_id         = azurerm_subscription_policy_assignment.assignments[each.key].identity[0].principal_id
  skip_service_principal_aad_check = true

  depends_on = [azurerm_subscription_policy_assignment.assignments]
}

# Role assignments for Resource Group policy assignments
resource "azurerm_role_assignment" "rg_policy_identity" {
  for_each = var.create_role_assignments ? {
    for k, v in local.rg_assignments_with_identity : k => v
    if v.identity_type == "SystemAssigned"
  } : {}

  scope                = each.value.resource_group_id
  role_definition_id   = lookup(var.role_definition_ids, each.key, [var.default_role_definition_id])[0]
  principal_id         = azurerm_resource_group_policy_assignment.assignments[each.key].identity[0].principal_id
  skip_service_principal_aad_check = true

  depends_on = [azurerm_resource_group_policy_assignment.assignments]
}
