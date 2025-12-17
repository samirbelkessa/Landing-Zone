################################################################################
# Main - Policy Assignments (G03)
# Assigns policies and initiatives to Management Groups
################################################################################

# ══════════════════════════════════════════════════════════════════════════════
# MANAGED IDENTITY FOR REMEDIATION
# ══════════════════════════════════════════════════════════════════════════════

# User Assigned Managed Identity for policy remediation (DeployIfNotExists, Modify)
resource "azurerm_user_assigned_identity" "remediation" {
  count = var.create_remediation_identity && var.remediation_identity_resource_group != "" ? 1 : 0

  name                = var.remediation_identity_name
  resource_group_name = var.remediation_identity_resource_group
  location            = var.remediation_identity_location

  tags = local.tags
}

# ══════════════════════════════════════════════════════════════════════════════
# POLICY ASSIGNMENTS (Individual Policies)
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_management_group_policy_assignment" "policies" {
  for_each = local.flattened_policy_assignments

  name                 = substr(each.key, 0, 24) # Max 24 characters
  display_name         = each.value.display_name
  description          = each.value.description
  management_group_id  = each.value.scope
  policy_definition_id = each.value.policy_definition_id
  enforcement_mode     = each.value.enforcement_mode
  parameters           = each.value.parameters
  metadata             = jsonencode(local.base_metadata)

  # Non-compliance message
  dynamic "non_compliance_message" {
    for_each = each.value.non_compliance_message != null ? [1] : []
    content {
      content = each.value.non_compliance_message
    }
  }

  # System Assigned Managed Identity for remediation
  dynamic "identity" {
    for_each = each.value.identity_type == "SystemAssigned" ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  # User Assigned Managed Identity for remediation
  dynamic "identity" {
    for_each = each.value.identity_type == "UserAssigned" && var.create_remediation_identity ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [azurerm_user_assigned_identity.remediation[0].id]
    }
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# INITIATIVE (POLICY SET) ASSIGNMENTS
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_management_group_policy_assignment" "initiatives" {
  for_each = local.flattened_initiative_assignments

  name                     = substr(each.key, 0, 24) # Max 24 characters
  display_name             = each.value.display_name
  description              = each.value.description
  management_group_id      = each.value.scope
  policy_definition_id     = each.value.policy_set_definition_id
  enforcement_mode         = each.value.enforcement_mode
  parameters               = each.value.parameters
  metadata                 = jsonencode(local.base_metadata)

  # Non-compliance message
  dynamic "non_compliance_message" {
    for_each = each.value.non_compliance_message != null ? [1] : []
    content {
      content = each.value.non_compliance_message
    }
  }

  # System Assigned Managed Identity for remediation
  dynamic "identity" {
    for_each = each.value.identity_type == "SystemAssigned" ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  # User Assigned Managed Identity for remediation
  dynamic "identity" {
    for_each = each.value.identity_type == "UserAssigned" && var.create_remediation_identity ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [azurerm_user_assigned_identity.remediation[0].id]
    }
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# CUSTOM POLICY ASSIGNMENTS
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_management_group_policy_assignment" "custom" {
  for_each = var.custom_policy_assignments

  name                 = substr(each.key, 0, 24)
  display_name         = each.value.display_name
  description          = each.value.description
  management_group_id  = each.value.management_group_id
  enforcement_mode     = coalesce(var.enforcement_mode_override, each.value.enforcement_mode)
  metadata             = jsonencode(local.base_metadata)

  # Either policy definition or policy set definition
  policy_definition_id = coalesce(
    each.value.policy_definition_id,
    each.value.policy_set_definition_id
  )

  # Parameters
  parameters = length(each.value.parameters) > 0 ? jsonencode({
    for k, v in each.value.parameters : k => { value = v }
  }) : null

  # Non-compliance message
  dynamic "non_compliance_message" {
    for_each = each.value.non_compliance_message != null ? [1] : []
    content {
      content = each.value.non_compliance_message
    }
  }

  # Managed Identity
  dynamic "identity" {
    for_each = each.value.identity_type == "SystemAssigned" ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  dynamic "identity" {
    for_each = each.value.identity_type == "UserAssigned" && var.create_remediation_identity ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [azurerm_user_assigned_identity.remediation[0].id]
    }
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# ROLE ASSIGNMENTS FOR REMEDIATION IDENTITIES
# ══════════════════════════════════════════════════════════════════════════════

# Role assignment for System Assigned Managed Identities at Root MG
# Grants Contributor role for remediation tasks (DeployIfNotExists)
resource "azurerm_role_assignment" "policy_remediation_contributor" {
  for_each = {
    for k, v in merge(
      azurerm_management_group_policy_assignment.policies,
      azurerm_management_group_policy_assignment.initiatives
    ) : k => v if try(v.identity[0].type, "") == "SystemAssigned"
  }

  scope                = local.mg_root
  role_definition_name = "Contributor"
  principal_id         = each.value.identity[0].principal_id
}

# Additional role assignment for monitoring-related policies
resource "azurerm_role_assignment" "policy_remediation_monitoring_contributor" {
  for_each = {
    for k, v in merge(
      azurerm_management_group_policy_assignment.policies,
      azurerm_management_group_policy_assignment.initiatives
    ) : k => v if try(v.identity[0].type, "") == "SystemAssigned" && can(regex("monitoring|vm-insights|diagnostic", k))
  }

  scope                = local.mg_root
  role_definition_name = "Monitoring Contributor"
  principal_id         = each.value.identity[0].principal_id
}

# Log Analytics Contributor for Log Analytics related policies
resource "azurerm_role_assignment" "policy_remediation_log_analytics_contributor" {
  for_each = {
    for k, v in merge(
      azurerm_management_group_policy_assignment.policies,
      azurerm_management_group_policy_assignment.initiatives
    ) : k => v if try(v.identity[0].type, "") == "SystemAssigned" && can(regex("log-analytics|diagnostic|monitoring", k))
  }

  scope                = local.mg_root
  role_definition_name = "Log Analytics Contributor"
  principal_id         = each.value.identity[0].principal_id
}

# Role assignment for User Assigned Managed Identity
resource "azurerm_role_assignment" "user_identity_contributor" {
  count = var.create_remediation_identity && var.remediation_identity_resource_group != "" ? 1 : 0

  scope                = local.mg_root
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.remediation[0].principal_id
}

# ══════════════════════════════════════════════════════════════════════════════
# TIME DELAY FOR ROLE PROPAGATION
# ══════════════════════════════════════════════════════════════════════════════

# Wait for role assignments to propagate before remediation can work
resource "time_sleep" "role_propagation" {
  depends_on = [
    azurerm_role_assignment.policy_remediation_contributor,
    azurerm_role_assignment.policy_remediation_monitoring_contributor,
    azurerm_role_assignment.policy_remediation_log_analytics_contributor,
    azurerm_role_assignment.user_identity_contributor
  ]

  create_duration = "60s"
}
