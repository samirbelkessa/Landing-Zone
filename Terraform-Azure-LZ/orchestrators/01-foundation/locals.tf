# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Locals - Orchestrator LZA Governance                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

locals {
  # ══════════════════════════════════════════════════════════════════════════════
  # Tags
  # ══════════════════════════════════════════════════════════════════════════════

  default_tags = {
    ManagedBy = "Terraform"
    Module    = "orchestrator-lza-gov"
  }

  tags = merge(local.default_tags, var.tags)

  # ══════════════════════════════════════════════════════════════════════════════
  # Management Group References
  # ══════════════════════════════════════════════════════════════════════════════

  # Build the CAF management groups map for G03 policy assignments
  caf_management_groups = {
    root           = module.management_groups.root_mg_id
    platform       = module.management_groups.platform_mg_id
    connectivity   = module.management_groups.connectivity_mg_id
    identity       = module.management_groups.identity_mg_id
    management     = module.management_groups.management_mg_id
    landing_zones  = module.management_groups.landing_zones_mg_id
    online_prod    = module.management_groups.online_prod_mg_id
    online_nonprod = module.management_groups.online_nonprod_mg_id
    corp_prod      = module.management_groups.corp_prod_mg_id
    corp_nonprod   = module.management_groups.corp_nonprod_mg_id
    sandbox        = module.management_groups.sandbox_mg_id
    decommissioned = module.management_groups.decommissioned_mg_id
  }

  # Filter out null values from management groups map
  valid_caf_management_groups = {
    for k, v in local.caf_management_groups : k => v
    if v != null
  }

  # Sandbox management group ID for exemptions
  sandbox_mg_id = module.management_groups.sandbox_mg_id

  # ══════════════════════════════════════════════════════════════════════════════
  # Policy Assignment IDs for Exemptions
  # ══════════════════════════════════════════════════════════════════════════════

  # Get assignment IDs from G03 for use in G04 exemptions
  assignment_ids = var.deploy_caf_assignments ? module.policy_assignments.mg_assignment_ids : {}

  # Sandbox exempted assignments - resolve from G03 outputs
  sandbox_exempted_assignments = var.enable_sandbox_exemptions ? [
    for assignment_key in var.sandbox_exempted_policy_assignments :
    lookup(local.assignment_ids, assignment_key, assignment_key)
  ] : []

  # ══════════════════════════════════════════════════════════════════════════════
  # Deployment Summary
  # ══════════════════════════════════════════════════════════════════════════════

  deployment_summary = {
    root_id              = var.root_id
    root_name            = var.root_name
    default_location     = var.default_location
    allowed_regions      = var.allowed_regions
    deploy_caf_policies  = var.deploy_caf_policies
    deploy_caf_initiatives = var.deploy_caf_initiatives
    deploy_caf_assignments = var.deploy_caf_assignments
    deploy_exemptions    = var.deploy_exemptions
    brownfield_enabled   = var.enable_brownfield_exemptions
    sandbox_exemptions   = var.enable_sandbox_exemptions
  }
}
