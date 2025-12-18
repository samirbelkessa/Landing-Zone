# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Locals - Policy Assignments (G03)                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

locals {
  # ══════════════════════════════════════════════════════════════════════════════
  # Tags
  # ══════════════════════════════════════════════════════════════════════════════
  
  default_tags = {
    ManagedBy = "Terraform"
    Module    = "policy-assignments"
  }
  
  tags = merge(local.default_tags, var.tags)

  # ══════════════════════════════════════════════════════════════════════════════
  # Standard Metadata for Assignments
  # ══════════════════════════════════════════════════════════════════════════════

  standard_metadata = jsonencode({
    createdBy   = "Terraform"
    createdOn   = timestamp()
    project     = "Australia Landing Zone"
    source      = "CAF Landing Zone - G03 Policy Assignments"
  })

  # ══════════════════════════════════════════════════════════════════════════════
  # CAF Assignment Configuration
  # ══════════════════════════════════════════════════════════════════════════════

  # Baseline initiatives to assign at Root
  caf_root_assignments = var.deploy_caf_assignments ? {
    # Governance Baseline - Root level
    "root-governance-baseline" = {
      management_group_id      = lookup(var.caf_management_groups, "root", "")
      policy_set_definition_id = lookup(var.caf_initiative_ids, "caf-governance-baseline", null)
      display_name             = "CAF Governance Baseline"
      description              = "Enforces governance baseline including allowed locations and required tags."
      enforce                  = true
      identity_type            = "None"
      location                 = null
      parameters = jsonencode({
        listOfAllowedLocations = { value = var.allowed_regions }
      })
    }

    # Security Baseline - Root level
    "root-security-baseline" = {
      management_group_id      = lookup(var.caf_management_groups, "root", "")
      policy_set_definition_id = lookup(var.caf_initiative_ids, "caf-security-baseline", null)
      display_name             = "CAF Security Baseline"
      description              = "Enforces security baseline including storage security and Key Vault hardening."
      enforce                  = true
      identity_type            = "None"
      location                 = null
      parameters               = null
    }

    # Azure Security Benchmark - Root level (built-in)
    "root-azure-security-benchmark" = {
      management_group_id      = lookup(var.caf_management_groups, "root", "")
      policy_set_definition_id = lookup(var.caf_builtin_initiative_ids, "azure_security_benchmark", null)
      display_name             = "Microsoft Cloud Security Benchmark"
      description              = "Azure Security Benchmark for comprehensive security coverage."
      enforce                  = false # Audit mode for benchmark
      identity_type            = "None"
      location                 = null
      parameters               = null
    }
  } : {}

  # Platform-level assignments
  caf_platform_assignments = var.deploy_caf_assignments ? {
    # Network Baseline - Connectivity
    "connectivity-network-baseline" = {
      management_group_id      = lookup(var.caf_management_groups, "connectivity", lookup(var.caf_management_groups, "platform", ""))
      policy_set_definition_id = lookup(var.caf_initiative_ids, "caf-network-baseline", null)
      display_name             = "CAF Network Baseline"
      description              = "Enforces network baseline including hub validation and firewall routing."
      enforce                  = true
      identity_type            = "None"
      location                 = null
      parameters               = null
    }

    # Identity Baseline - Identity MG
    "identity-baseline" = {
      management_group_id      = lookup(var.caf_management_groups, "identity", lookup(var.caf_management_groups, "platform", ""))
      policy_set_definition_id = lookup(var.caf_initiative_ids, "caf-identity-baseline", null)
      display_name             = "CAF Identity Baseline"
      description              = "Enforces identity baseline including managed identity requirements."
      enforce                  = true
      identity_type            = "None"
      location                 = null
      parameters               = null
    }

    # Monitoring Baseline - Management MG
    "management-monitoring-baseline" = {
      management_group_id      = lookup(var.caf_management_groups, "management", lookup(var.caf_management_groups, "platform", ""))
      policy_set_definition_id = lookup(var.caf_initiative_ids, "caf-monitoring-baseline", null)
      display_name             = "CAF Monitoring Baseline"
      description              = "Enforces monitoring baseline including Log Analytics retention."
      enforce                  = true
      identity_type            = "SystemAssigned"
      location                 = var.default_location
      parameters = var.log_analytics_workspace_id != "" ? jsonencode({
        logAnalyticsWorkspaceId = { value = var.log_analytics_workspace_id }
      }) : null
    }

    # VM Insights - Platform (built-in)
    "platform-vm-insights" = {
      management_group_id      = lookup(var.caf_management_groups, "platform", "")
      policy_set_definition_id = lookup(var.caf_builtin_initiative_ids, "vm_insights", null)
      display_name             = "Enable Azure Monitor for VMs"
      description              = "Enables Azure Monitor for VMs with Azure Monitoring Agent."
      enforce                  = true
      identity_type            = "SystemAssigned"
      location                 = var.default_location
      parameters = var.log_analytics_workspace_id != "" ? jsonencode({
        logAnalyticsWorkspace = { value = var.log_analytics_workspace_id }
      }) : null
    }
  } : {}

  # Landing Zone parent assignments
  caf_landing_zones_assignments = var.deploy_caf_assignments ? {
    # Backup Baseline - Landing Zones
    "lz-backup-baseline" = {
      management_group_id      = lookup(var.caf_management_groups, "landing_zones", "")
      policy_set_definition_id = lookup(var.caf_initiative_ids, "caf-backup-baseline", null)
      display_name             = "CAF Backup Baseline"
      description              = "Enforces backup requirements for all Landing Zones."
      enforce                  = true
      identity_type            = "None"
      location                 = null
      parameters               = null
    }

    # Cost Baseline - Landing Zones
    "lz-cost-baseline" = {
      management_group_id      = lookup(var.caf_management_groups, "landing_zones", "")
      policy_set_definition_id = lookup(var.caf_initiative_ids, "caf-cost-baseline", null)
      display_name             = "CAF Cost Management Baseline"
      description              = "Enforces cost management including budget requirements."
      enforce                  = true
      identity_type            = "None"
      location                 = null
      parameters               = null
    }

    # VM Insights - Landing Zones (built-in)
    "lz-vm-insights" = {
      management_group_id      = lookup(var.caf_management_groups, "landing_zones", "")
      policy_set_definition_id = lookup(var.caf_builtin_initiative_ids, "vm_insights", null)
      display_name             = "Enable Azure Monitor for VMs"
      description              = "Enables Azure Monitor for VMs in Landing Zones."
      enforce                  = true
      identity_type            = "SystemAssigned"
      location                 = var.default_location
      parameters = var.log_analytics_workspace_id != "" ? jsonencode({
        logAnalyticsWorkspace = { value = var.log_analytics_workspace_id }
      }) : null
    }
  } : {}

  # Archetype-specific assignments
  caf_archetype_assignments = var.deploy_caf_assignments ? merge(
    # Online Production
    lookup(var.caf_management_groups, "online_prod", "") != "" ? {
      "online-prod-initiative" = {
        management_group_id      = var.caf_management_groups["online_prod"]
        policy_set_definition_id = lookup(var.caf_initiative_ids, "caf-online-prod", null)
        display_name             = "CAF Online Production"
        description              = "Policy initiative for Online Production Landing Zone."
        enforce                  = true
        identity_type            = "None"
        location                 = null
        parameters               = null
      }
    } : {},

    # Online Non-Production
    lookup(var.caf_management_groups, "online_nonprod", "") != "" ? {
      "online-nonprod-initiative" = {
        management_group_id      = var.caf_management_groups["online_nonprod"]
        policy_set_definition_id = lookup(var.caf_initiative_ids, "caf-online-nonprod", null)
        display_name             = "CAF Online Non-Production"
        description              = "Policy initiative for Online Non-Production Landing Zone."
        enforce                  = true
        identity_type            = "None"
        location                 = null
        parameters               = null
      }
    } : {},

    # Corporate Production
    lookup(var.caf_management_groups, "corp_prod", "") != "" ? {
      "corp-prod-initiative" = {
        management_group_id      = var.caf_management_groups["corp_prod"]
        policy_set_definition_id = lookup(var.caf_initiative_ids, "caf-corp-prod", null)
        display_name             = "CAF Corporate Production"
        description              = "Policy initiative for Corporate Production Landing Zone."
        enforce                  = true
        identity_type            = "None"
        location                 = null
        parameters               = null
      }
    } : {},

    # Corporate Non-Production
    lookup(var.caf_management_groups, "corp_nonprod", "") != "" ? {
      "corp-nonprod-initiative" = {
        management_group_id      = var.caf_management_groups["corp_nonprod"]
        policy_set_definition_id = lookup(var.caf_initiative_ids, "caf-corp-nonprod", null)
        display_name             = "CAF Corporate Non-Production"
        description              = "Policy initiative for Corporate Non-Production Landing Zone."
        enforce                  = true
        identity_type            = "None"
        location                 = null
        parameters               = null
      }
    } : {},

    # Sandbox
    lookup(var.caf_management_groups, "sandbox", "") != "" ? {
      "sandbox-initiative" = {
        management_group_id      = var.caf_management_groups["sandbox"]
        policy_set_definition_id = lookup(var.caf_initiative_ids, "caf-sandbox", null)
        display_name             = "CAF Sandbox"
        description              = "Policy initiative for Sandbox Landing Zone - Audit mode with restrictions."
        enforce                  = true
        identity_type            = "SystemAssigned"
        location                 = var.default_location
        parameters               = null
      }
    } : {},

    # Decommissioned
    lookup(var.caf_management_groups, "decommissioned", "") != "" ? {
      "decommissioned-initiative" = {
        management_group_id      = var.caf_management_groups["decommissioned"]
        policy_set_definition_id = lookup(var.caf_initiative_ids, "caf-decommissioned", null)
        display_name             = "CAF Decommissioned"
        description              = "Policy initiative for Decommissioned subscriptions - Denies all changes."
        enforce                  = true
        identity_type            = "None"
        location                 = null
        parameters               = null
      }
    } : {}
  ) : {}

  # ══════════════════════════════════════════════════════════════════════════════
  # Merge All CAF Assignments
  # ══════════════════════════════════════════════════════════════════════════════

  all_caf_mg_assignments = merge(
    local.caf_root_assignments,
    local.caf_platform_assignments,
    local.caf_landing_zones_assignments,
    local.caf_archetype_assignments
  )

  # Filter out assignments with null initiative IDs
  valid_caf_mg_assignments = {
    for k, v in local.all_caf_mg_assignments : k => v
    if v.policy_set_definition_id != null && v.management_group_id != ""
  }

  # ══════════════════════════════════════════════════════════════════════════════
  # Combined Assignments
  # ══════════════════════════════════════════════════════════════════════════════

  # Transform CAF assignments to match manual assignment structure
  caf_transformed_assignments = {
    for k, v in local.valid_caf_mg_assignments : k => {
      management_group_id      = v.management_group_id
      policy_definition_id     = null
      policy_set_definition_id = v.policy_set_definition_id
      display_name             = v.display_name
      description              = v.description
      enforce                  = v.enforce
      parameters               = v.parameters
      non_compliance_message   = null
      identity_type            = v.identity_type
      identity_ids             = []
      location                 = v.location
      not_scopes               = []
      metadata                 = null
    }
  }

  # All management group assignments (CAF + manual)
  all_mg_assignments = merge(
    local.caf_transformed_assignments,
    var.management_group_assignments
  )

  # ══════════════════════════════════════════════════════════════════════════════
  # Identity and Role Assignment Helpers
  # ══════════════════════════════════════════════════════════════════════════════

  # Assignments requiring system-assigned identity
  mg_assignments_with_identity = {
    for k, v in local.all_mg_assignments : k => v
    if v.identity_type == "SystemAssigned" || v.identity_type == "UserAssigned"
  }

  sub_assignments_with_identity = {
    for k, v in var.subscription_assignments : k => v
    if v.identity_type == "SystemAssigned" || v.identity_type == "UserAssigned"
  }

  rg_assignments_with_identity = {
    for k, v in var.resource_group_assignments : k => v
    if v.identity_type == "SystemAssigned" || v.identity_type == "UserAssigned"
  }

  # ══════════════════════════════════════════════════════════════════════════════
  # Non-Compliance Messages
  # ══════════════════════════════════════════════════════════════════════════════

  default_non_compliance_messages = {
    governance = "This resource does not comply with the organization's governance policies. Contact the Platform Team for guidance."
    security   = "This resource does not meet security requirements. Private endpoints and encryption may be required."
    network    = "This resource does not comply with network topology requirements. Ensure hub-spoke connectivity is configured."
    backup     = "This resource does not meet backup requirements. Production resources require GRS backup."
    cost       = "This resource exceeds cost management restrictions for this environment."
  }
}
