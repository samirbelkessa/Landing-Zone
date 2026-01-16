# =============================================================================
# LOCALS.TF - Local Values and Computations
# =============================================================================
# Module: S01-defender-for-cloud
# Purpose: Microsoft Defender for Cloud deployment
# =============================================================================

locals {
  # ---------------------------------------------------------------------------
  # Tags
  # ---------------------------------------------------------------------------
  default_tags = {
    ManagedBy = "Terraform"
    Module    = "S01-defender-for-cloud"
  }

  tags = merge(local.default_tags, var.tags)

  # ---------------------------------------------------------------------------
  # Filter Enabled Defender Plans
  # ---------------------------------------------------------------------------
  enabled_defender_plans = {
    for plan, config in var.defender_plans : plan => config
    if config.enabled
  }

  disabled_defender_plans = {
    for plan, config in var.defender_plans : plan => config
    if !config.enabled
  }

  # ---------------------------------------------------------------------------
  # Defender Plan Tier Mapping
  # ---------------------------------------------------------------------------
  # Azure uses "Standard" for enabled plans and "Free" for disabled
  plan_tier_mapping = {
    for plan, config in var.defender_plans : plan => {
      tier    = config.enabled ? "Standard" : "Free"
      subplan = config.subplan
    }
  }
}
