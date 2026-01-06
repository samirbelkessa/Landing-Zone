# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Locals - Policy Exemptions (G04)                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

locals {
  # ══════════════════════════════════════════════════════════════════════════════
  # Tags
  # ══════════════════════════════════════════════════════════════════════════════
  
  default_tags = {
    ManagedBy = "Terraform"
    Module    = "policy-exemptions"
  }
  
  tags = merge(local.default_tags, var.tags)

  # ══════════════════════════════════════════════════════════════════════════════
  # Standard Metadata for Exemptions
  # ══════════════════════════════════════════════════════════════════════════════

  standard_metadata = jsonencode({
    createdBy = "Terraform"
    createdOn = timestamp()
    project   = "Australia Landing Zone"
    source    = "CAF Landing Zone - G04 Policy Exemptions"
  })

  # ══════════════════════════════════════════════════════════════════════════════
  # Brownfield Migration Exemptions
  # ══════════════════════════════════════════════════════════════════════════════

  # Generate subscription exemptions for brownfield migration
  brownfield_subscription_exemptions = var.enable_brownfield_exemptions ? flatten([
    for sub_key, sub_config in var.brownfield_subscriptions : [
      for policy_id in sub_config.policy_assignment_ids : {
        key                  = "bf-sub-${sub_key}-${substr(md5(policy_id), 0, 8)}"
        subscription_id      = sub_config.subscription_id
        policy_assignment_id = policy_id
        exemption_category   = "Waiver"
        display_name         = "Brownfield Migration - ${sub_key}"
        description          = sub_config.reason
        expires_on           = var.brownfield_migration_end_date
      }
    ]
  ]) : []

  brownfield_subscription_exemptions_map = {
    for exemption in local.brownfield_subscription_exemptions :
    exemption.key => exemption
  }

  # Generate resource group exemptions for brownfield migration
  brownfield_rg_exemptions = var.enable_brownfield_exemptions ? flatten([
    for rg_key, rg_config in var.brownfield_resource_groups : [
      for policy_id in rg_config.policy_assignment_ids : {
        key                  = "bf-rg-${rg_key}-${substr(md5(policy_id), 0, 8)}"
        resource_group_id    = rg_config.resource_group_id
        policy_assignment_id = policy_id
        exemption_category   = "Waiver"
        display_name         = "Brownfield Migration - ${rg_key}"
        description          = rg_config.reason
        expires_on           = var.brownfield_migration_end_date
      }
    ]
  ]) : []

  brownfield_rg_exemptions_map = {
    for exemption in local.brownfield_rg_exemptions :
    exemption.key => exemption
  }

  # ══════════════════════════════════════════════════════════════════════════════
  # Sandbox Exemptions
  # ══════════════════════════════════════════════════════════════════════════════

  sandbox_exemptions = var.enable_sandbox_exemptions && var.sandbox_management_group_id != "" ? {
    for idx, policy_id in var.sandbox_exempted_policy_assignments :
    "sandbox-exemption-${idx}" => {
      management_group_id              = var.sandbox_management_group_id
      policy_assignment_id             = policy_id
      exemption_category               = "Mitigated"
      display_name                     = "Sandbox Relaxed Policy - ${idx}"
      description                      = "Policy relaxed for Sandbox environment to allow experimentation. Alternative controls: limited SKUs, expiration tag, audit logging."
      expires_on                       = null  # Sandbox exemptions don't expire
      policy_definition_reference_ids  = []
      metadata                         = null
    }
  } : {}

  # ══════════════════════════════════════════════════════════════════════════════
  # Merge All Exemptions
  # ══════════════════════════════════════════════════════════════════════════════

  # Management Group exemptions (manual + sandbox)
  all_mg_exemptions = merge(
    var.management_group_exemptions,
    local.sandbox_exemptions
  )

  # Subscription exemptions (manual + brownfield)
  all_subscription_exemptions = merge(
    var.subscription_exemptions,
    {
      for k, v in local.brownfield_subscription_exemptions_map : k => {
        subscription_id                  = v.subscription_id
        policy_assignment_id             = v.policy_assignment_id
        exemption_category               = v.exemption_category
        display_name                     = v.display_name
        description                      = v.description
        expires_on                       = v.expires_on
        policy_definition_reference_ids  = []
        metadata                         = null
      }
    }
  )

  # Resource Group exemptions (manual + brownfield)
  all_rg_exemptions = merge(
    var.resource_group_exemptions,
    {
      for k, v in local.brownfield_rg_exemptions_map : k => {
        resource_group_id                = v.resource_group_id
        policy_assignment_id             = v.policy_assignment_id
        exemption_category               = v.exemption_category
        display_name                     = v.display_name
        description                      = v.description
        expires_on                       = v.expires_on
        policy_definition_reference_ids  = []
        metadata                         = null
      }
    }
  )

  # ══════════════════════════════════════════════════════════════════════════════
  # Validation Helpers
  # ══════════════════════════════════════════════════════════════════════════════

  # Check for Waiver exemptions without expiration
  waivers_without_expiration = concat(
    [for k, v in local.all_mg_exemptions : k if v.exemption_category == "Waiver" && v.expires_on == null],
    [for k, v in local.all_subscription_exemptions : k if v.exemption_category == "Waiver" && v.expires_on == null],
    [for k, v in local.all_rg_exemptions : k if v.exemption_category == "Waiver" && v.expires_on == null],
    [for k, v in var.resource_exemptions : k if v.exemption_category == "Waiver" && v.expires_on == null]
  )

  # ══════════════════════════════════════════════════════════════════════════════
  # Expiration Summary
  # ══════════════════════════════════════════════════════════════════════════════

  exemptions_expiring_soon = concat(
    [for k, v in local.all_mg_exemptions : {
      key        = k
      scope      = "management_group"
      expires_on = v.expires_on
    } if v.expires_on != null],
    [for k, v in local.all_subscription_exemptions : {
      key        = k
      scope      = "subscription"
      expires_on = v.expires_on
    } if v.expires_on != null],
    [for k, v in local.all_rg_exemptions : {
      key        = k
      scope      = "resource_group"
      expires_on = v.expires_on
    } if v.expires_on != null],
    [for k, v in var.resource_exemptions : {
      key        = k
      scope      = "resource"
      expires_on = v.expires_on
    } if v.expires_on != null]
  )
}
