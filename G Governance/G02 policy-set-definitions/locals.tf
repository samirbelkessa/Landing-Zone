# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Locals - Policy Set Definitions (Initiatives)                                  ║
# ║ FIXED: Static keys + guaranteed base policies for each initiative              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

locals {
  # ══════════════════════════════════════════════════════════════════════════════
  # Tags
  # ══════════════════════════════════════════════════════════════════════════════
  
  default_tags = {
    ManagedBy = "Terraform"
    Module    = "policy-set-definitions"
  }
  
  tags = merge(local.default_tags, var.tags)

  # ══════════════════════════════════════════════════════════════════════════════
  # Built-in Policy Definition IDs (Hardcoded - stable)
  # ══════════════════════════════════════════════════════════════════════════════

  builtin_policies = {
    allowed_locations       = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
    allowed_locations_rg    = "/providers/Microsoft.Authorization/policyDefinitions/e765b5de-1225-4ba3-bd56-1ac6695af988"
    require_tag_rg          = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"
    secure_transfer_storage = "/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9"
    keyvault_soft_delete    = "/providers/Microsoft.Authorization/policyDefinitions/1e66c121-a66a-4b1f-9b83-0fd99bf0fc2d"
    keyvault_purge_protection = "/providers/Microsoft.Authorization/policyDefinitions/0b60c0b2-2dc2-4e1c-b5c9-abbed971de53"
    backup_enabled_vms      = "/providers/Microsoft.Authorization/policyDefinitions/013e242c-8828-4970-87b3-ab247555486d"
    allowed_vm_skus         = "/providers/Microsoft.Authorization/policyDefinitions/cccc23c7-8427-4f53-ad12-b6a63eb452b3"
    waf_enabled_app_gw      = "/providers/Microsoft.Authorization/policyDefinitions/564feb30-bf6a-4854-b4bb-0d2d2d1e6c66"
    waf_enabled_frontdoor   = "/providers/Microsoft.Authorization/policyDefinitions/055aa869-bc98-4af8-bafc-23f1ab6ffe2c"
    https_web_apps          = "/providers/Microsoft.Authorization/policyDefinitions/a4af4a39-4135-47fb-b175-47fbdf85311d"
  }

  builtin_initiatives = {
    azure_security_benchmark = "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8"
    vm_insights              = "/providers/Microsoft.Authorization/policySetDefinitions/924bfe3a-762f-40e7-86dd-5c8b95eb09e6"
    nist_sp_800_53_r5        = "/providers/Microsoft.Authorization/policySetDefinitions/179d1daa-458f-4e47-8086-2a68d0d6c38f"
    iso_27001_2013           = "/providers/Microsoft.Authorization/policySetDefinitions/89c6cddc-1c73-4ac1-b19c-54d1a15a42f2"
  }

  # ══════════════════════════════════════════════════════════════════════════════
  # STEP 1: Static Initiative Keys (based on variables only)
  # ══════════════════════════════════════════════════════════════════════════════

  caf_initiative_keys = var.deploy_caf_initiatives ? toset([
    var.deploy_security_initiative ? "caf-security-baseline" : null,
    var.deploy_network_initiative ? "caf-network-baseline" : null,
    var.deploy_monitoring_initiative ? "caf-monitoring-baseline" : null,
    var.deploy_governance_initiative ? "caf-governance-baseline" : null,
    var.deploy_backup_initiative ? "caf-backup-baseline" : null,
    var.deploy_cost_initiative ? "caf-cost-baseline" : null,
    var.deploy_identity_initiative ? "caf-identity-baseline" : null,
  ]) : toset([])

  archetype_initiative_keys = var.deploy_archetype_initiatives ? toset([
    contains(var.archetypes_to_deploy, "online-prod") ? "caf-online-prod" : null,
    contains(var.archetypes_to_deploy, "online-nonprod") ? "caf-online-nonprod" : null,
    contains(var.archetypes_to_deploy, "corp-prod") ? "caf-corp-prod" : null,
    contains(var.archetypes_to_deploy, "corp-nonprod") ? "caf-corp-nonprod" : null,
    contains(var.archetypes_to_deploy, "sandbox") ? "caf-sandbox" : null,
    contains(var.archetypes_to_deploy, "decommissioned") ? "caf-decommissioned" : null,
  ]) : toset([])

  # Remove nulls and combine
  all_initiative_keys = setsubtract(
    setunion(local.caf_initiative_keys, local.archetype_initiative_keys),
    toset([null])
  )

  # ══════════════════════════════════════════════════════════════════════════════
  # STEP 2: Initiative Metadata (static)
  # ══════════════════════════════════════════════════════════════════════════════

  initiative_metadata = {
    "caf-security-baseline" = {
      display_name = "CAF Security Baseline"
      description  = "Security baseline policies including storage security, Key Vault hardening."
      category     = "Security"
    }
    "caf-network-baseline" = {
      display_name = "CAF Network Baseline"
      description  = "Network baseline policies including hub validation and firewall routing."
      category     = "Network"
    }
    "caf-monitoring-baseline" = {
      display_name = "CAF Monitoring Baseline"
      description  = "Monitoring baseline policies including Log Analytics retention."
      category     = "Monitoring"
    }
    "caf-governance-baseline" = {
      display_name = "CAF Governance Baseline"
      description  = "Governance baseline including allowed locations and required tags."
      category     = "Governance"
    }
    "caf-backup-baseline" = {
      display_name = "CAF Backup Baseline"
      description  = "Backup baseline policies including GRS/LRS requirements."
      category     = "Backup"
    }
    "caf-cost-baseline" = {
      display_name = "CAF Cost Management Baseline"
      description  = "Cost management policies including budget requirements."
      category     = "Cost Management"
    }
    "caf-identity-baseline" = {
      display_name = "CAF Identity Baseline"
      description  = "Identity baseline policies including managed identity requirements."
      category     = "Identity"
    }
    "caf-online-prod" = {
      display_name = "CAF Online Production"
      description  = "Policy initiative for Online Production Landing Zone."
      category     = "Landing Zone"
    }
    "caf-online-nonprod" = {
      display_name = "CAF Online Non-Production"
      description  = "Policy initiative for Online Non-Production Landing Zone."
      category     = "Landing Zone"
    }
    "caf-corp-prod" = {
      display_name = "CAF Corporate Production"
      description  = "Policy initiative for Corporate Production Landing Zone."
      category     = "Landing Zone"
    }
    "caf-corp-nonprod" = {
      display_name = "CAF Corporate Non-Production"
      description  = "Policy initiative for Corporate Non-Production Landing Zone."
      category     = "Landing Zone"
    }
    "caf-sandbox" = {
      display_name = "CAF Sandbox"
      description  = "Policy initiative for Sandbox Landing Zone - Audit mode with restrictions."
      category     = "Landing Zone"
    }
    "caf-decommissioned" = {
      display_name = "CAF Decommissioned"
      description  = "Policy initiative for Decommissioned subscriptions - Denies all changes."
      category     = "Landing Zone"
    }
  }

  # ══════════════════════════════════════════════════════════════════════════════
  # STEP 3: Base Policies (built-in only - guarantees at least 1 per initiative)
  # ══════════════════════════════════════════════════════════════════════════════

  initiative_base_policies = {
    "caf-security-baseline" = [
      {
        policy_definition_id = local.builtin_policies.secure_transfer_storage
        reference_id         = "SecureTransferStorage"
        parameter_values     = null
      },
      {
        policy_definition_id = local.builtin_policies.keyvault_soft_delete
        reference_id         = "KeyVaultSoftDelete"
        parameter_values     = null
      },
      {
        policy_definition_id = local.builtin_policies.keyvault_purge_protection
        reference_id         = "KeyVaultPurgeProtection"
        parameter_values     = null
      }
    ]

    "caf-network-baseline" = [
      {
        policy_definition_id = local.builtin_policies.require_tag_rg
        reference_id         = "RequireNetworkTypeTag"
        parameter_values     = jsonencode({ tagName = { value = "NetworkType" } })
      }
    ]

    "caf-monitoring-baseline" = [
      {
        policy_definition_id = local.builtin_policies.require_tag_rg
        reference_id         = "RequireEnvironmentTag"
        parameter_values     = jsonencode({ tagName = { value = "Environment" } })
      }
    ]

    "caf-governance-baseline" = [
      {
        policy_definition_id = local.builtin_policies.allowed_locations
        reference_id         = "AllowedLocations"
        parameter_values     = jsonencode({ listOfAllowedLocations = { value = var.allowed_regions } })
      },
      {
        policy_definition_id = local.builtin_policies.allowed_locations_rg
        reference_id         = "AllowedLocationsRg"
        parameter_values     = jsonencode({ listOfAllowedLocations = { value = var.allowed_regions } })
      }
    ]

    "caf-backup-baseline" = [
      {
        policy_definition_id = local.builtin_policies.backup_enabled_vms
        reference_id         = "BackupEnabledVms"
        parameter_values     = null
      }
    ]

    "caf-cost-baseline" = [
      {
        policy_definition_id = local.builtin_policies.require_tag_rg
        reference_id         = "RequireCostCenterTag"
        parameter_values     = jsonencode({ tagName = { value = "CostCenter" } })
      }
    ]

    "caf-identity-baseline" = [
      {
        policy_definition_id = local.builtin_policies.require_tag_rg
        reference_id         = "RequireOwnerTag"
        parameter_values     = jsonencode({ tagName = { value = "Owner" } })
      }
    ]

    "caf-online-prod" = [
      {
        policy_definition_id = local.builtin_policies.waf_enabled_app_gw
        reference_id         = "WafEnabledAppGw"
        parameter_values     = null
      },
      {
        policy_definition_id = local.builtin_policies.waf_enabled_frontdoor
        reference_id         = "WafEnabledFrontDoor"
        parameter_values     = null
      },
      {
        policy_definition_id = local.builtin_policies.https_web_apps
        reference_id         = "HttpsWebApps"
        parameter_values     = null
      }
    ]

    "caf-online-nonprod" = [
      {
        policy_definition_id = local.builtin_policies.waf_enabled_app_gw
        reference_id         = "WafRecommended"
        parameter_values     = null
      },
      {
        policy_definition_id = local.builtin_policies.https_web_apps
        reference_id         = "HttpsWebApps"
        parameter_values     = null
      }
    ]

    "caf-corp-prod" = [
      {
        policy_definition_id = local.builtin_policies.https_web_apps
        reference_id         = "HttpsWebApps"
        parameter_values     = null
      }
    ]

    "caf-corp-nonprod" = [
      {
        policy_definition_id = local.builtin_policies.require_tag_rg
        reference_id         = "RequireEnvironmentTag"
        parameter_values     = jsonencode({ tagName = { value = "Environment" } })
      }
    ]

    "caf-sandbox" = [
      {
        policy_definition_id = local.builtin_policies.allowed_vm_skus
        reference_id         = "AllowedVmSkus"
        parameter_values     = jsonencode({ listOfAllowedSKUs = { value = var.allowed_vm_skus_sandbox } })
      }
    ]

    "caf-decommissioned" = [
      {
        policy_definition_id = local.builtin_policies.require_tag_rg
        reference_id         = "RequireDecommissionDateTag"
        parameter_values     = jsonencode({ tagName = { value = "DecommissionDate" } })
      }
    ]
  }

  # ══════════════════════════════════════════════════════════════════════════════
  # STEP 4: G01 Custom Policies (may be null - filtered)
  # ══════════════════════════════════════════════════════════════════════════════

  # G01 policy lookups (may return null)
  g01_deny_storage_public     = lookup(var.policy_definition_ids, "deny-storage-public-access", null)
  g01_deny_sql_public         = lookup(var.policy_definition_ids, "deny-sql-without-private-endpoint", null)
  g01_deny_cosmos_public      = lookup(var.policy_definition_ids, "deny-cosmos-without-private-endpoint", null)
  g01_audit_app_service_pe    = lookup(var.policy_definition_ids, "audit-app-service-private-endpoint", null)
  g01_audit_vnet_peered       = lookup(var.policy_definition_ids, "audit-vnet-peered-to-hub", null)
  g01_audit_route_firewall    = lookup(var.policy_definition_ids, "audit-route-to-firewall", null)
  g01_audit_firewall_premium  = lookup(var.policy_definition_ids, "audit-firewall-premium", null)
  g01_audit_private_dns       = lookup(var.policy_definition_ids, "audit-private-dns-hub-link", null)
  g01_disabled_ddos           = lookup(var.policy_definition_ids, "disabled-ddos-standard", null)
  g01_audit_la_retention      = lookup(var.policy_definition_ids, "audit-la-retention-minimum", null)
  g01_audit_la_archive        = lookup(var.policy_definition_ids, "audit-la-archive-enabled", null)
  g01_audit_sentinel          = lookup(var.policy_definition_ids, "audit-sentinel-connectors", null)
  g01_audit_backup_grs_prod   = lookup(var.policy_definition_ids, "audit-backup-grs-production", null)
  g01_audit_backup_lrs_np     = lookup(var.policy_definition_ids, "audit-backup-lrs-nonproduction", null)
  g01_audit_budget            = lookup(var.policy_definition_ids, "audit-budget-configured", null)
  g01_deny_expensive_vm       = lookup(var.policy_definition_ids, "deny-expensive-vm-skus-sandbox", null)
  g01_deny_expensive_res      = lookup(var.policy_definition_ids, "deny-expensive-resources-sandbox", null)
  g01_deny_no_expiration      = lookup(var.policy_definition_ids, "deny-sandbox-without-expiration", null)
  g01_audit_only_sandbox      = lookup(var.policy_definition_ids, "audit-only-sandbox", null)
  g01_deny_all_creation       = lookup(var.policy_definition_ids, "deny-all-resource-creation", null)
  g01_deny_all_modification   = lookup(var.policy_definition_ids, "deny-all-resource-modification", null)

  initiative_g01_policies = {
    "caf-security-baseline" = [
      local.g01_deny_storage_public != null ? {
        policy_definition_id = local.g01_deny_storage_public
        reference_id         = "DenyStoragePublicAccess"
        parameter_values     = null
      } : null,
      local.g01_deny_sql_public != null ? {
        policy_definition_id = local.g01_deny_sql_public
        reference_id         = "DenySqlPublicAccess"
        parameter_values     = null
      } : null,
      local.g01_deny_cosmos_public != null ? {
        policy_definition_id = local.g01_deny_cosmos_public
        reference_id         = "DenyCosmosPublicAccess"
        parameter_values     = null
      } : null,
      local.g01_audit_app_service_pe != null ? {
        policy_definition_id = local.g01_audit_app_service_pe
        reference_id         = "AuditAppServicePrivateEndpoint"
        parameter_values     = null
      } : null
    ]

    "caf-network-baseline" = [
      local.g01_audit_vnet_peered != null ? {
        policy_definition_id = local.g01_audit_vnet_peered
        reference_id         = "VnetPeeredToHub"
        parameter_values     = null
      } : null,
      local.g01_audit_route_firewall != null ? {
        policy_definition_id = local.g01_audit_route_firewall
        reference_id         = "RouteToFirewall"
        parameter_values     = null
      } : null,
      local.g01_audit_firewall_premium != null ? {
        policy_definition_id = local.g01_audit_firewall_premium
        reference_id         = "FirewallPremium"
        parameter_values     = null
      } : null,
      local.g01_audit_private_dns != null ? {
        policy_definition_id = local.g01_audit_private_dns
        reference_id         = "PrivateDnsLinkedToHub"
        parameter_values     = null
      } : null,
      local.g01_disabled_ddos != null ? {
        policy_definition_id = local.g01_disabled_ddos
        reference_id         = "DdosStandardDisabled"
        parameter_values     = null
      } : null
    ]

    "caf-monitoring-baseline" = [
      local.g01_audit_la_retention != null ? {
        policy_definition_id = local.g01_audit_la_retention
        reference_id         = "LogAnalyticsRetention"
        parameter_values     = null
      } : null,
      local.g01_audit_la_archive != null ? {
        policy_definition_id = local.g01_audit_la_archive
        reference_id         = "LogAnalyticsArchive"
        parameter_values     = null
      } : null,
      local.g01_audit_sentinel != null ? {
        policy_definition_id = local.g01_audit_sentinel
        reference_id         = "SentinelConnectors"
        parameter_values     = null
      } : null
    ]

    "caf-governance-baseline" = []

    "caf-backup-baseline" = [
      local.g01_audit_backup_grs_prod != null ? {
        policy_definition_id = local.g01_audit_backup_grs_prod
        reference_id         = "BackupGrsProduction"
        parameter_values     = null
      } : null,
      local.g01_audit_backup_lrs_np != null ? {
        policy_definition_id = local.g01_audit_backup_lrs_np
        reference_id         = "BackupLrsNonProduction"
        parameter_values     = null
      } : null
    ]

    "caf-cost-baseline" = [
      local.g01_audit_budget != null ? {
        policy_definition_id = local.g01_audit_budget
        reference_id         = "BudgetConfigured"
        parameter_values     = null
      } : null
    ]

    "caf-identity-baseline" = []

    "caf-online-prod" = [
      local.g01_audit_backup_grs_prod != null ? {
        policy_definition_id = local.g01_audit_backup_grs_prod
        reference_id         = "BackupGrsProduction"
        parameter_values     = null
      } : null
    ]

    "caf-online-nonprod" = [
      local.g01_audit_backup_lrs_np != null ? {
        policy_definition_id = local.g01_audit_backup_lrs_np
        reference_id         = "BackupLrsNonProd"
        parameter_values     = null
      } : null
    ]

    "caf-corp-prod" = [
      local.g01_deny_storage_public != null ? {
        policy_definition_id = local.g01_deny_storage_public
        reference_id         = "DenyStoragePublicAccess"
        parameter_values     = null
      } : null,
      local.g01_deny_sql_public != null ? {
        policy_definition_id = local.g01_deny_sql_public
        reference_id         = "DenySqlPublicAccess"
        parameter_values     = null
      } : null,
      local.g01_deny_cosmos_public != null ? {
        policy_definition_id = local.g01_deny_cosmos_public
        reference_id         = "DenyCosmosPublicAccess"
        parameter_values     = null
      } : null,
      local.g01_audit_backup_grs_prod != null ? {
        policy_definition_id = local.g01_audit_backup_grs_prod
        reference_id         = "BackupGrsProduction"
        parameter_values     = null
      } : null
    ]

    "caf-corp-nonprod" = [
      local.g01_audit_backup_lrs_np != null ? {
        policy_definition_id = local.g01_audit_backup_lrs_np
        reference_id         = "BackupLrsNonProd"
        parameter_values     = null
      } : null
    ]

    "caf-sandbox" = [
      local.g01_deny_expensive_vm != null ? {
        policy_definition_id = local.g01_deny_expensive_vm
        reference_id         = "DenyExpensiveVmSkus"
        parameter_values     = null
      } : null,
      local.g01_deny_expensive_res != null ? {
        policy_definition_id = local.g01_deny_expensive_res
        reference_id         = "DenyExpensiveResources"
        parameter_values     = null
      } : null,
      local.g01_deny_no_expiration != null ? {
        policy_definition_id = local.g01_deny_no_expiration
        reference_id         = "RequireExpirationTag"
        parameter_values     = null
      } : null,
      local.g01_audit_only_sandbox != null ? {
        policy_definition_id = local.g01_audit_only_sandbox
        reference_id         = "AuditOnlySandbox"
        parameter_values     = null
      } : null
    ]

    "caf-decommissioned" = [
      local.g01_deny_all_creation != null ? {
        policy_definition_id = local.g01_deny_all_creation
        reference_id         = "DenyAllCreation"
        parameter_values     = null
      } : null,
      local.g01_deny_all_modification != null ? {
        policy_definition_id = local.g01_deny_all_modification
        reference_id         = "DenyAllModification"
        parameter_values     = null
      } : null
    ]
  }

  # ══════════════════════════════════════════════════════════════════════════════
  # STEP 5: Merge Base + G01 Policies (filter nulls from G01)
  # ══════════════════════════════════════════════════════════════════════════════

  initiative_policies_merged = {
    for key in local.all_initiative_keys : key => concat(
      local.initiative_base_policies[key],
      [for p in lookup(local.initiative_g01_policies, key, []) : p if p != null]
    )
  }

  # ══════════════════════════════════════════════════════════════════════════════
  # STEP 6: Build Final Initiatives Map
  # ══════════════════════════════════════════════════════════════════════════════

  all_caf_initiatives = {
    for key in local.all_initiative_keys : key => {
      display_name = local.initiative_metadata[key].display_name
      description  = local.initiative_metadata[key].description
      category     = local.initiative_metadata[key].category
      policies     = local.initiative_policies_merged[key]
    }
  }

  # Built-in initiatives for direct assignment via G03
  builtin_initiatives_for_assignment = {
    azure_security_benchmark = var.include_azure_security_benchmark ? local.builtin_initiatives.azure_security_benchmark : null
    vm_insights              = var.include_vm_insights ? local.builtin_initiatives.vm_insights : null
    nist_sp_800_53_r5        = var.include_nist_initiative ? local.builtin_initiatives.nist_sp_800_53_r5 : null
    iso_27001_2013           = var.include_iso27001_initiative ? local.builtin_initiatives.iso_27001_2013 : null
  }
}