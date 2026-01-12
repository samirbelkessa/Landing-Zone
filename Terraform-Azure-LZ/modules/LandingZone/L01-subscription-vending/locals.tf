# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Locals - L01 Subscription Vending                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

locals {
  # ════════════════════════════════════════════════════════════════════════════
  # Default Tags
  # ════════════════════════════════════════════════════════════════════════════
  default_tags = merge(
    {
      ManagedBy = "Terraform"
      Module    = "L01-subscription-vending"
    },
    var.default_tags
  )

  # ════════════════════════════════════════════════════════════════════════════
  # Archetype to Management Group Mapping
  # Maps archetype names to their corresponding MG IDs from F01
  # ════════════════════════════════════════════════════════════════════════════
  archetype_to_mg = {
    # Platform archetypes
    root           = lookup(var.management_group_ids, "root", null)
    platform       = lookup(var.management_group_ids, "platform", null)
    management     = lookup(var.management_group_ids, "management", null)
    connectivity   = lookup(var.management_group_ids, "connectivity", null)
    identity       = lookup(var.management_group_ids, "identity", null)
    
    # Landing Zone archetypes
    landing_zones  = lookup(var.management_group_ids, "landing_zones", null)
    corp_prod      = lookup(var.management_group_ids, "corp_prod", null)
    corp_nonprod   = lookup(var.management_group_ids, "corp_nonprod", null)
    online_prod    = lookup(var.management_group_ids, "online_prod", null)
    online_nonprod = lookup(var.management_group_ids, "online_nonprod", null)
    sandbox        = lookup(var.management_group_ids, "sandbox", null)
    
    # Special archetypes
    decommissioned = lookup(var.management_group_ids, "decommissioned", null)
  }

  # ════════════════════════════════════════════════════════════════════════════
  # Subscriptions to Create
  # Prepare subscription data with resolved MG IDs
  # ════════════════════════════════════════════════════════════════════════════
  subscriptions_to_create = {
    for key, sub in var.subscriptions : key => {
      alias_name          = "${var.subscription_alias_prefix}-${key}"
      display_name        = sub.display_name
      workload_type       = sub.workload_type
      billing_scope       = var.billing_scope
      management_group_id = local.archetype_to_mg[sub.archetype]
      archetype           = sub.archetype
      owner_object_id     = sub.owner_object_id
      tags                = merge(local.default_tags, sub.tags, {
        Archetype   = sub.archetype
        Environment = sub.workload_type == "Production" ? "Production" : "NonProduction"
      })
      budget = sub.budget
    }
  }

  # ════════════════════════════════════════════════════════════════════════════
  # Existing Subscriptions to Place
  # For brownfield scenarios
  # ════════════════════════════════════════════════════════════════════════════
  existing_subscriptions_to_place = {
    for key, sub in var.existing_subscriptions : key => {
      subscription_id     = sub.subscription_id
      management_group_id = local.archetype_to_mg[sub.archetype]
      archetype           = sub.archetype
    }
    if local.archetype_to_mg[sub.archetype] != null
  }

  # ════════════════════════════════════════════════════════════════════════════
  # Budget Configuration
  # Flatten budgets for subscriptions that have them configured
  # ════════════════════════════════════════════════════════════════════════════
  subscription_budgets = {
    for key, sub in var.subscriptions : key => sub.budget
    if sub.budget != null
  }

  # ════════════════════════════════════════════════════════════════════════════
  # Role Assignments
  # Combine default and subscription-specific role assignments
  # ════════════════════════════════════════════════════════════════════════════
  all_role_assignments = flatten([
    for sub_key, sub in var.subscriptions : [
      for role_key, role in var.default_role_assignments : {
        key                  = "${sub_key}-${role_key}"
        subscription_key     = sub_key
        role_definition_name = role.role_definition_name
        principal_id         = role.principal_id
        principal_type       = role.principal_type
      }
    ]
  ])

  role_assignments_map = {
    for ra in local.all_role_assignments : ra.key => ra
  }
}
