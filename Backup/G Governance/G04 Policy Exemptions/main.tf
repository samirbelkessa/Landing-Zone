# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Main - Policy Exemptions (G04)                                                ║
# ║ Creates Azure Policy Exemptions at various scopes                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════════════════════════════════════════════════════════════════════════════
# Validation - Waiver Expiration Requirement
# ══════════════════════════════════════════════════════════════════════════════

resource "terraform_data" "waiver_expiration_validation" {
  count = var.require_expiration_for_waivers && length(local.waivers_without_expiration) > 0 ? 1 : 0

  lifecycle {
    precondition {
      condition     = length(local.waivers_without_expiration) == 0
      error_message = "The following Waiver exemptions do not have an expiration date: ${join(", ", local.waivers_without_expiration)}. Set expires_on or disable require_expiration_for_waivers."
    }
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Management Group Policy Exemptions
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_management_group_policy_exemption" "exemptions" {
  for_each = local.all_mg_exemptions

  name                 = substr(each.key, 0, 64)  # Max 64 characters
  management_group_id  = each.value.management_group_id
  policy_assignment_id = each.value.policy_assignment_id
  exemption_category   = each.value.exemption_category
  
  display_name = each.value.display_name
  description  = each.value.description != "" ? each.value.description : null
  
  expires_on = each.value.expires_on
  
  # For initiatives, you can exempt specific policies within the initiative
  policy_definition_reference_ids = length(each.value.policy_definition_reference_ids) > 0 ? each.value.policy_definition_reference_ids : null
  
  metadata = each.value.metadata != null ? each.value.metadata : local.standard_metadata

  lifecycle {
    create_before_destroy = true
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Subscription Policy Exemptions
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_subscription_policy_exemption" "exemptions" {
  for_each = local.all_subscription_exemptions

  name                 = substr(each.key, 0, 64)
  subscription_id      = each.value.subscription_id
  policy_assignment_id = each.value.policy_assignment_id
  exemption_category   = each.value.exemption_category
  
  display_name = each.value.display_name
  description  = each.value.description != "" ? each.value.description : null
  
  expires_on = each.value.expires_on
  
  policy_definition_reference_ids = length(each.value.policy_definition_reference_ids) > 0 ? each.value.policy_definition_reference_ids : null
  
  metadata = each.value.metadata != null ? each.value.metadata : local.standard_metadata

  lifecycle {
    create_before_destroy = true
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Resource Group Policy Exemptions
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_resource_group_policy_exemption" "exemptions" {
  for_each = local.all_rg_exemptions

  name                 = substr(each.key, 0, 64)
  resource_group_id    = each.value.resource_group_id
  policy_assignment_id = each.value.policy_assignment_id
  exemption_category   = each.value.exemption_category
  
  display_name = each.value.display_name
  description  = each.value.description != "" ? each.value.description : null
  
  expires_on = each.value.expires_on
  
  policy_definition_reference_ids = length(each.value.policy_definition_reference_ids) > 0 ? each.value.policy_definition_reference_ids : null
  
  metadata = each.value.metadata != null ? each.value.metadata : local.standard_metadata

  lifecycle {
    create_before_destroy = true
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Resource-Level Policy Exemptions
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_resource_policy_exemption" "exemptions" {
  for_each = var.resource_exemptions

  name                 = substr(each.key, 0, 64)
  resource_id          = each.value.resource_id
  policy_assignment_id = each.value.policy_assignment_id
  exemption_category   = each.value.exemption_category
  
  display_name = each.value.display_name
  description  = each.value.description != "" ? each.value.description : null
  
  expires_on = each.value.expires_on
  
  policy_definition_reference_ids = length(each.value.policy_definition_reference_ids) > 0 ? each.value.policy_definition_reference_ids : null
  
  metadata = each.value.metadata != null ? each.value.metadata : local.standard_metadata

  lifecycle {
    create_before_destroy = true
  }
}
