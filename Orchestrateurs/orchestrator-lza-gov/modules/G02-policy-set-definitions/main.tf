# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Main - Policy Set Definitions (Initiatives)                                    ║
# ║ Creates Azure Policy Initiatives for CAF Landing Zone                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════════════════════════════════════════════════════════════════════════════
# CAF Baseline and Archetype Initiatives
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_policy_set_definition" "caf_initiatives" {
  for_each = local.all_caf_initiatives

  name                = each.key
  display_name        = each.value.display_name
  description         = each.value.description
  policy_type         = "Custom"
  management_group_id = var.management_group_id

  metadata = jsonencode({
    version  = "1.0.0"
    category = each.value.category
    source   = "CAF Landing Zone - Terraform"
    project  = "Australia Landing Zone"
  })

  # Dynamic block for each policy reference in the initiative
  dynamic "policy_definition_reference" {
    for_each = each.value.policies

    content {
      policy_definition_id = policy_definition_reference.value.policy_definition_id
      reference_id         = policy_definition_reference.value.reference_id
      parameter_values     = policy_definition_reference.value.parameter_values
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Platform Initiative - NOTE IMPORTANTE
# ══════════════════════════════════════════════════════════════════════════════
# Azure ne permet PAS d'inclure des Policy Set Definitions (initiatives) à 
# l'intérieur d'autres Policy Set Definitions. 
#
# Les initiatives built-in comme Azure Security Benchmark et VM Insights doivent
# être assignées DIRECTEMENT via le module G03 (policy-assignments).
#
# Les IDs de ces initiatives sont exposés via l'output "builtin_initiatives_for_assignment"
# ══════════════════════════════════════════════════════════════════════════════

# ══════════════════════════════════════════════════════════════════════════════
# Compliance Initiatives - NOTE IMPORTANTE  
# ══════════════════════════════════════════════════════════════════════════════
# Les initiatives de compliance (NIST, ISO 27001, CIS) sont des initiatives 
# built-in Azure qui doivent être assignées DIRECTEMENT via le module G03.
#
# Azure ne permet pas d'inclure des initiatives dans d'autres initiatives.
# Les IDs sont exposés via l'output "builtin_initiatives_for_assignment"
# ══════════════════════════════════════════════════════════════════════════════

# ══════════════════════════════════════════════════════════════════════════════
# Custom Policy Set Definitions
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_policy_set_definition" "custom_initiatives" {
  for_each = var.custom_policy_set_definitions

  name                = each.key
  display_name        = each.value.display_name
  description         = each.value.description
  policy_type         = "Custom"
  management_group_id = var.management_group_id

  metadata   = each.value.metadata
  parameters = each.value.parameters

  dynamic "policy_definition_reference" {
    for_each = each.value.policy_definition_references

    content {
      policy_definition_id = policy_definition_reference.value.policy_definition_id
      parameter_values     = policy_definition_reference.value.parameter_values
      reference_id         = policy_definition_reference.value.reference_id
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
