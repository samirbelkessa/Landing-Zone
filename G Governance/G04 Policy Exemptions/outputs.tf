# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Outputs - Policy Exemptions (G04)                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════════════════════════════════════════════════════════════════════════════
# Management Group Exemption Outputs
# ══════════════════════════════════════════════════════════════════════════════

output "mg_exemption_ids" {
  description = "Map of management group policy exemption names to their resource IDs."
  value = {
    for k, v in azurerm_management_group_policy_exemption.exemptions : k => v.id
  }
}

output "mg_exemptions" {
  description = "Full map of management group policy exemptions with all attributes."
  value = {
    for k, v in azurerm_management_group_policy_exemption.exemptions : k => {
      id                   = v.id
      name                 = v.name
      display_name         = v.display_name
      description          = v.description
      management_group_id  = v.management_group_id
      policy_assignment_id = v.policy_assignment_id
      exemption_category   = v.exemption_category
      expires_on           = v.expires_on
    }
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Subscription Exemption Outputs
# ══════════════════════════════════════════════════════════════════════════════

output "sub_exemption_ids" {
  description = "Map of subscription policy exemption names to their resource IDs."
  value = {
    for k, v in azurerm_subscription_policy_exemption.exemptions : k => v.id
  }
}

output "sub_exemptions" {
  description = "Full map of subscription policy exemptions with all attributes."
  value = {
    for k, v in azurerm_subscription_policy_exemption.exemptions : k => {
      id                   = v.id
      name                 = v.name
      display_name         = v.display_name
      description          = v.description
      subscription_id      = v.subscription_id
      policy_assignment_id = v.policy_assignment_id
      exemption_category   = v.exemption_category
      expires_on           = v.expires_on
    }
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Resource Group Exemption Outputs
# ══════════════════════════════════════════════════════════════════════════════

output "rg_exemption_ids" {
  description = "Map of resource group policy exemption names to their resource IDs."
  value = {
    for k, v in azurerm_resource_group_policy_exemption.exemptions : k => v.id
  }
}

output "rg_exemptions" {
  description = "Full map of resource group policy exemptions with all attributes."
  value = {
    for k, v in azurerm_resource_group_policy_exemption.exemptions : k => {
      id                   = v.id
      name                 = v.name
      display_name         = v.display_name
      description          = v.description
      resource_group_id    = v.resource_group_id
      policy_assignment_id = v.policy_assignment_id
      exemption_category   = v.exemption_category
      expires_on           = v.expires_on
    }
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Resource-Level Exemption Outputs
# ══════════════════════════════════════════════════════════════════════════════

output "resource_exemption_ids" {
  description = "Map of resource policy exemption names to their resource IDs."
  value = {
    for k, v in azurerm_resource_policy_exemption.exemptions : k => v.id
  }
}

output "resource_exemptions" {
  description = "Full map of resource policy exemptions with all attributes."
  value = {
    for k, v in azurerm_resource_policy_exemption.exemptions : k => {
      id                   = v.id
      name                 = v.name
      display_name         = v.display_name
      description          = v.description
      resource_id          = v.resource_id
      policy_assignment_id = v.policy_assignment_id
      exemption_category   = v.exemption_category
      expires_on           = v.expires_on
    }
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Combined Outputs
# ══════════════════════════════════════════════════════════════════════════════

output "all_exemption_ids" {
  description = "Map of all policy exemption names to their resource IDs (all scopes combined)."
  value = merge(
    { for k, v in azurerm_management_group_policy_exemption.exemptions : "mg-${k}" => v.id },
    { for k, v in azurerm_subscription_policy_exemption.exemptions : "sub-${k}" => v.id },
    { for k, v in azurerm_resource_group_policy_exemption.exemptions : "rg-${k}" => v.id },
    { for k, v in azurerm_resource_policy_exemption.exemptions : "resource-${k}" => v.id }
  )
}

# ══════════════════════════════════════════════════════════════════════════════
# Brownfield Migration Outputs
# ══════════════════════════════════════════════════════════════════════════════

output "brownfield_exemption_ids" {
  description = "Map of brownfield migration exemption IDs (subscriptions and resource groups)."
  value = {
    subscriptions = {
      for k, v in azurerm_subscription_policy_exemption.exemptions : k => v.id
      if startswith(k, "bf-sub-")
    }
    resource_groups = {
      for k, v in azurerm_resource_group_policy_exemption.exemptions : k => v.id
      if startswith(k, "bf-rg-")
    }
  }
}

output "brownfield_migration_end_date" {
  description = "End date for brownfield migration exemptions."
  value       = var.brownfield_migration_end_date
}

# ══════════════════════════════════════════════════════════════════════════════
# Sandbox Exemption Outputs
# ══════════════════════════════════════════════════════════════════════════════

output "sandbox_exemption_ids" {
  description = "Map of Sandbox exemption IDs."
  value = {
    for k, v in azurerm_management_group_policy_exemption.exemptions : k => v.id
    if startswith(k, "sandbox-exemption-")
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Expiration Tracking Outputs
# ══════════════════════════════════════════════════════════════════════════════

output "exemptions_by_category" {
  description = "Exemptions organized by category (Waiver vs Mitigated)."
  value = {
    waiver = merge(
      { for k, v in azurerm_management_group_policy_exemption.exemptions : k => v.id if v.exemption_category == "Waiver" },
      { for k, v in azurerm_subscription_policy_exemption.exemptions : k => v.id if v.exemption_category == "Waiver" },
      { for k, v in azurerm_resource_group_policy_exemption.exemptions : k => v.id if v.exemption_category == "Waiver" },
      { for k, v in azurerm_resource_policy_exemption.exemptions : k => v.id if v.exemption_category == "Waiver" }
    )
    mitigated = merge(
      { for k, v in azurerm_management_group_policy_exemption.exemptions : k => v.id if v.exemption_category == "Mitigated" },
      { for k, v in azurerm_subscription_policy_exemption.exemptions : k => v.id if v.exemption_category == "Mitigated" },
      { for k, v in azurerm_resource_group_policy_exemption.exemptions : k => v.id if v.exemption_category == "Mitigated" },
      { for k, v in azurerm_resource_policy_exemption.exemptions : k => v.id if v.exemption_category == "Mitigated" }
    )
  }
}

output "exemptions_with_expiration" {
  description = "List of exemptions that have expiration dates set."
  value = [
    for exemption in local.exemptions_expiring_soon : {
      key        = exemption.key
      scope      = exemption.scope
      expires_on = exemption.expires_on
    }
  ]
}

output "waivers_without_expiration" {
  description = "List of Waiver exemptions without expiration dates (compliance warning)."
  value       = local.waivers_without_expiration
}

# ══════════════════════════════════════════════════════════════════════════════
# Summary Output
# ══════════════════════════════════════════════════════════════════════════════

output "summary" {
  description = "Summary of deployed policy exemptions."
  value = {
    total_exemptions = (
      length(azurerm_management_group_policy_exemption.exemptions) +
      length(azurerm_subscription_policy_exemption.exemptions) +
      length(azurerm_resource_group_policy_exemption.exemptions) +
      length(azurerm_resource_policy_exemption.exemptions)
    )
    by_scope = {
      management_groups = length(azurerm_management_group_policy_exemption.exemptions)
      subscriptions     = length(azurerm_subscription_policy_exemption.exemptions)
      resource_groups   = length(azurerm_resource_group_policy_exemption.exemptions)
      resources         = length(azurerm_resource_policy_exemption.exemptions)
    }
    by_category = {
      waiver    = length([for k, v in merge(
        { for k, v in azurerm_management_group_policy_exemption.exemptions : k => v },
        { for k, v in azurerm_subscription_policy_exemption.exemptions : k => v },
        { for k, v in azurerm_resource_group_policy_exemption.exemptions : k => v },
        { for k, v in azurerm_resource_policy_exemption.exemptions : k => v }
      ) : k if v.exemption_category == "Waiver"])
      mitigated = length([for k, v in merge(
        { for k, v in azurerm_management_group_policy_exemption.exemptions : k => v },
        { for k, v in azurerm_subscription_policy_exemption.exemptions : k => v },
        { for k, v in azurerm_resource_group_policy_exemption.exemptions : k => v },
        { for k, v in azurerm_resource_policy_exemption.exemptions : k => v }
      ) : k if v.exemption_category == "Mitigated"])
    }
    brownfield_migration = {
      enabled  = var.enable_brownfield_exemptions
      end_date = var.brownfield_migration_end_date
      count    = length(local.brownfield_subscription_exemptions) + length(local.brownfield_rg_exemptions)
    }
    sandbox = {
      enabled = var.enable_sandbox_exemptions
      count   = length(local.sandbox_exemptions)
    }
    compliance_warnings = {
      waivers_without_expiration = length(local.waivers_without_expiration)
    }
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Audit Report Output
# ══════════════════════════════════════════════════════════════════════════════

output "audit_report" {
  description = "Audit report for compliance review - lists all exemptions with their justifications."
  value = {
    management_groups = {
      for k, v in azurerm_management_group_policy_exemption.exemptions : k => {
        display_name       = v.display_name
        description        = v.description
        category           = v.exemption_category
        expires_on         = v.expires_on
        policy_assignment  = v.policy_assignment_id
        requires_attention = v.exemption_category == "Waiver" && v.expires_on == null
      }
    }
    subscriptions = {
      for k, v in azurerm_subscription_policy_exemption.exemptions : k => {
        display_name       = v.display_name
        description        = v.description
        category           = v.exemption_category
        expires_on         = v.expires_on
        policy_assignment  = v.policy_assignment_id
        requires_attention = v.exemption_category == "Waiver" && v.expires_on == null
      }
    }
    resource_groups = {
      for k, v in azurerm_resource_group_policy_exemption.exemptions : k => {
        display_name       = v.display_name
        description        = v.description
        category           = v.exemption_category
        expires_on         = v.expires_on
        policy_assignment  = v.policy_assignment_id
        requires_attention = v.exemption_category == "Waiver" && v.expires_on == null
      }
    }
    resources = {
      for k, v in azurerm_resource_policy_exemption.exemptions : k => {
        display_name       = v.display_name
        description        = v.description
        category           = v.exemption_category
        expires_on         = v.expires_on
        policy_assignment  = v.policy_assignment_id
        requires_attention = v.exemption_category == "Waiver" && v.expires_on == null
      }
    }
  }
}
