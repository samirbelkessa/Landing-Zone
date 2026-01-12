# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Main - Orchestrator 02-Governance                                             ║
# ║ Deploys: G01 → G02 → G03 → G04 in sequence                                   ║
# ║ NOTE: F01 is NOT deployed here - it reads from foundation.tfstate            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════════════════════════════════════════════════════════════════════════════
# ⚠️  F01 - Management Groups - ALREADY DEPLOYED
# ══════════════════════════════════════════════════════════════════════════════
# Management Groups are read from foundation.tfstate via data.tf
# DO NOT add module "management_groups" here!
#
# Available via: local.root_mg_id, local.all_mg_ids, local.deployment_flags, etc.
# See data.tf and locals.tf for details
# ══════════════════════════════════════════════════════════════════════════════

# ══════════════════════════════════════════════════════════════════════════════
# G01 - Policy Definitions
# ══════════════════════════════════════════════════════════════════════════════
# Creates custom Azure Policy definitions at the root management group
# Uses root_mg_id from foundation remote state

module "policy_definitions" {
  source = "../../modules/Governance/G01-policy-definitions"

  # Required - Use root MG from foundation remote state
  management_group_id = local.root_mg_id

  # CAF Policies
  deploy_caf_policies = var.deploy_caf_policies

  # Custom policies
  custom_policy_definitions = var.custom_policy_definitions

  # Policy categories
  enable_network_policies    = var.enable_network_policies
  enable_security_policies   = var.enable_security_policies
  enable_monitoring_policies = var.enable_monitoring_policies
  enable_backup_policies     = var.enable_backup_policies
  enable_cost_policies       = var.enable_cost_policies
  enable_lifecycle_policies  = var.enable_lifecycle_policies

  # Parameters - Use values from foundation where available
  allowed_regions            = local.allowed_regions
  log_analytics_workspace_id = var.log_analytics_workspace_id
  log_retention_days         = var.log_retention_days
  required_tags              = var.required_tags
  allowed_vm_skus_sandbox    = var.allowed_vm_skus_sandbox
  denied_resource_types      = var.denied_resource_types
  expensive_resource_types   = var.expensive_resource_types
}

# ══════════════════════════════════════════════════════════════════════════════
# G02 - Policy Set Definitions (Initiatives)
# ══════════════════════════════════════════════════════════════════════════════
# Creates policy initiatives grouping policies by domain
# Depends on: G01 (policy definitions)

module "policy_set_definitions" {
  source = "../../modules/Governance/G02-policy-set-definitions"

  # Required - Use root MG and policy IDs from G01
  management_group_id    = local.root_mg_id
  policy_definition_ids  = module.policy_definitions.policy_definition_ids
  builtin_policy_ids     = module.policy_definitions.builtin_policy_ids
  builtin_initiative_ids = module.policy_definitions.builtin_initiative_ids

  # CAF Initiatives
  deploy_caf_initiatives       = var.deploy_caf_initiatives
  deploy_security_initiative   = var.deploy_security_initiative
  deploy_network_initiative    = var.deploy_network_initiative
  deploy_monitoring_initiative = var.deploy_monitoring_initiative
  deploy_governance_initiative = var.deploy_governance_initiative
  deploy_backup_initiative     = var.deploy_backup_initiative
  deploy_cost_initiative       = var.deploy_cost_initiative
  deploy_identity_initiative   = var.deploy_identity_initiative

  # Archetype initiatives
  deploy_archetype_initiatives = var.deploy_archetype_initiatives
  archetypes_to_deploy         = var.archetypes_to_deploy

  # Built-in initiatives
  include_azure_security_benchmark = var.include_azure_security_benchmark
  include_vm_insights              = var.include_vm_insights
  include_nist_initiative          = var.include_nist_initiative
  include_iso27001_initiative      = var.include_iso27001_initiative

  # Custom initiatives
  custom_policy_set_definitions = var.custom_policy_set_definitions

  # Parameters - Use values from foundation where available
  allowed_regions            = local.allowed_regions
  log_analytics_workspace_id = var.log_analytics_workspace_id
  log_retention_days         = var.log_retention_days
  required_tags              = var.required_tags
  allowed_vm_skus_sandbox    = var.allowed_vm_skus_sandbox
  expensive_resource_types   = var.expensive_resource_types

  # Tags
  tags = local.tags

  depends_on = [module.policy_definitions]
}

# ══════════════════════════════════════════════════════════════════════════════
# G03 - Policy Assignments
# ══════════════════════════════════════════════════════════════════════════════
# Assigns policies and initiatives to management groups
# Depends on: G02 (policy set definitions)
# Uses: valid_caf_management_groups from foundation remote state

module "policy_assignments" {
  source = "../../modules/Governance/G03-policy-assignments"

  # CAF Automatic Assignments
  deploy_caf_assignments = var.deploy_caf_assignments

  # Management Group IDs from foundation remote state (via locals)
  # CRITICAL: This uses static values from all_mg_ids, NOT dynamic resource references
  # This solves the for_each error!
  caf_management_groups = local.valid_caf_management_groups

  # Initiative IDs from G02
  caf_initiative_ids = module.policy_set_definitions.all_initiative_ids

  # Built-in initiative IDs from G02
  caf_builtin_initiative_ids = module.policy_set_definitions.builtin_initiatives_for_assignment

  # Role assignments for managed identities
  create_role_assignments    = var.create_role_assignments
  role_definition_ids        = var.role_definition_ids
  default_role_definition_id = var.default_role_definition_id

  # Manual assignments
  management_group_assignments = var.management_group_assignments
  subscription_assignments     = var.subscription_assignments
  resource_group_assignments   = var.resource_group_assignments

  # Parameters - Use values from foundation where available
  default_location           = local.primary_location
  log_analytics_workspace_id = var.log_analytics_workspace_id
  allowed_regions            = local.allowed_regions
  required_tags              = var.required_tags

  # Tags
  tags = local.tags

  depends_on = [module.policy_set_definitions]
}

# ══════════════════════════════════════════════════════════════════════════════
# G04 - Policy Exemptions
# ══════════════════════════════════════════════════════════════════════════════
# Manages policy exemptions for brownfield migration and legitimate exceptions
# Depends on: G03 (policy assignments)

module "policy_exemptions" {
  source = "../../modules/Governance/G04-Policy-exemptions"
  count  = var.deploy_exemptions ? 1 : 0

  # Manual exemptions
  management_group_exemptions = var.management_group_exemptions
  subscription_exemptions     = var.subscription_exemptions
  resource_group_exemptions   = var.resource_group_exemptions
  resource_exemptions         = var.resource_exemptions

  # Brownfield migration
  enable_brownfield_exemptions  = var.enable_brownfield_exemptions
  brownfield_migration_end_date = var.brownfield_migration_end_date
  brownfield_subscriptions      = var.brownfield_subscriptions
  brownfield_resource_groups    = var.brownfield_resource_groups

  # Sandbox exemptions
  enable_sandbox_exemptions           = var.enable_sandbox_exemptions
  sandbox_management_group_id         = local.sandbox_mg_id != null ? local.sandbox_mg_id : ""
  sandbox_exempted_policy_assignments = local.sandbox_exempted_assignments

  # Validation settings
  require_expiration_for_waivers = var.require_expiration_for_waivers
  max_waiver_duration_days       = var.max_waiver_duration_days

  # Tags
  tags = local.tags

  depends_on = [module.policy_assignments]
}
