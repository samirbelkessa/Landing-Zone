# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Locals - Orchestrator 02-Governance                                           ║
# ║ Uses outputs from foundation.tfstate (NOT module.management_groups)           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

locals {
  # ══════════════════════════════════════════════════════════════════════════════
  # Foundation Outputs (from remote state)
  # ══════════════════════════════════════════════════════════════════════════════

  foundation = data.terraform_remote_state.foundation.outputs

  # Shortcuts for commonly used values
  root_mg_id       = local.foundation.root_mg_id
  root_id          = local.foundation.root_id
  root_name        = local.foundation.root_name
  tenant_id        = local.foundation.tenant_id
  all_mg_ids       = local.foundation.all_mg_ids
  deployment_flags = local.foundation.deployment_flags
  primary_location = local.foundation.primary_location
  allowed_regions  = local.foundation.allowed_regions

  # ══════════════════════════════════════════════════════════════════════════════
  # Tags
  # ══════════════════════════════════════════════════════════════════════════════

  default_tags = {
    ManagedBy = "Terraform"
    Module    = "orchestrator-02-governance"
  }

  tags = merge(local.default_tags, local.foundation.common_tags, var.tags)

  # ══════════════════════════════════════════════════════════════════════════════
  # Management Group References for G03
  # Uses all_mg_ids from foundation remote state
  # ══════════════════════════════════════════════════════════════════════════════

  caf_management_groups = {
    root           = local.all_mg_ids["root"]
    platform       = local.all_mg_ids["platform"]
    connectivity   = local.all_mg_ids["connectivity"]
    identity       = local.all_mg_ids["identity"]
    management     = local.all_mg_ids["management"]
    landing_zones  = local.all_mg_ids["landing_zones"]
    online_prod    = local.all_mg_ids["online_prod"]
    online_nonprod = local.all_mg_ids["online_nonprod"]
    corp_prod      = local.all_mg_ids["corp_prod"]
    corp_nonprod   = local.all_mg_ids["corp_nonprod"]
    sandbox        = local.all_mg_ids["sandbox"]
    decommissioned = local.all_mg_ids["decommissioned"]
  }

  # Filter out null values from management groups map
  # This handles cases where some MGs are not deployed (e.g., corp, online without separation)
  valid_caf_management_groups = {
    for k, v in local.caf_management_groups : k => v
    if v != null
  }

  # Sandbox management group ID for exemptions
  sandbox_mg_id = local.all_mg_ids["sandbox"]

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
    # From foundation remote state
    root_id          = local.root_id
    root_name        = local.root_name
    tenant_id        = local.tenant_id
    primary_location = local.primary_location
    allowed_regions  = local.allowed_regions

    # Governance configuration
    deploy_caf_policies    = var.deploy_caf_policies
    deploy_caf_initiatives = var.deploy_caf_initiatives
    deploy_caf_assignments = var.deploy_caf_assignments
    deploy_exemptions      = var.deploy_exemptions
    brownfield_enabled     = var.enable_brownfield_exemptions
    sandbox_exemptions     = var.enable_sandbox_exemptions

    # Deployment flags from foundation
    deployment_flags = local.deployment_flags
  }
}
