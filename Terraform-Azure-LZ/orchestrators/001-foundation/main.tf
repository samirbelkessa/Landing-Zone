# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Main - Orchestrator Foundation                                                ║
# ║ Deploys: F01 Management Groups ONLY                                           ║
# ║ Output: foundation.tfstate (used by Governance, Management, Connectivity)     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════════════════════════════════════════════════════════════════════════════
# F01 - Management Groups
# ══════════════════════════════════════════════════════════════════════════════
# Creates the CAF-aligned management group hierarchy
# This is the foundation for ALL other orchestrators

module "management_groups" {
  source = "../../modules/Fondations/F01-management-groups"

  # ════════════════════════════════════════════════════════════════════════════
  # Required - Organization Identity
  # ════════════════════════════════════════════════════════════════════════════
  root_parent_id = var.root_parent_id
  root_name      = var.root_name
  root_id        = var.root_id

  # ════════════════════════════════════════════════════════════════════════════
  # Structure Configuration
  # ════════════════════════════════════════════════════════════════════════════
  deploy_platform_mg             = var.deploy_platform_mg
  deploy_landing_zones_mg        = var.deploy_landing_zones_mg
  deploy_decommissioned_mg       = var.deploy_decommissioned_mg
  deploy_sandbox_mg              = var.deploy_sandbox_mg
  deploy_corp_landing_zones      = var.deploy_corp_landing_zones
  deploy_online_landing_zones    = var.deploy_online_landing_zones
  deploy_prod_nonprod_separation = var.deploy_prod_nonprod_separation

  # ════════════════════════════════════════════════════════════════════════════
  # Custom Management Groups
  # ════════════════════════════════════════════════════════════════════════════
  custom_landing_zone_children = var.custom_landing_zone_children
  custom_platform_children     = var.custom_platform_children

  # ════════════════════════════════════════════════════════════════════════════
  # Subscription Placement (Brownfield Migration)
  # ════════════════════════════════════════════════════════════════════════════
  subscription_ids_by_mg = var.subscription_ids_by_mg

  # ════════════════════════════════════════════════════════════════════════════
  # Configuration
  # ════════════════════════════════════════════════════════════════════════════
  default_location = var.default_location
  timeouts         = var.timeouts
}

# ══════════════════════════════════════════════════════════════════════════════
# NO OTHER MODULES HERE!
# ══════════════════════════════════════════════════════════════════════════════
# Governance (G01-G04) is deployed by orchestrator 02-governance
# Management (M01-M08) is deployed by orchestrator 03-management
# Connectivity (C01-C13) is deployed by orchestrator 04-connectivity
# ══════════════════════════════════════════════════════════════════════════════
