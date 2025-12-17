# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Locals - Policy Set Definitions (Initiatives)                                  ║
# ║ CORRECTED: Mapped to actual G01 policy keys                                    ║
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
  # Built-in Policy Definition IDs - VERIFIED AZURE POLICY IDs
  # ══════════════════════════════════════════════════════════════════════════════

  builtin_policies = {
    # Locations
    allowed_locations    = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
    allowed_locations_rg = "/providers/Microsoft.Authorization/policyDefinitions/e765b5de-1225-4ba3-bd56-1ac6695af988"
    
    # Tags
    require_tag_rg      = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"
    inherit_tag_from_rg = "/providers/Microsoft.Authorization/policyDefinitions/ea3f2387-9b95-492a-a190-fcdc54f7b070"
    
    # Storage
    secure_transfer_storage = "/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9"
    
    # Key Vault
    keyvault_soft_delete      = "/providers/Microsoft.Authorization/policyDefinitions/1e66c121-a66a-4b1f-9b83-0fd99bf0fc2d"
    keyvault_purge_protection = "/providers/Microsoft.Authorization/policyDefinitions/0b60c0b2-2dc2-4e1c-b5c9-abbed971de53"
    
    # Backup
    backup_enabled_vms = "/providers/Microsoft.Authorization/policyDefinitions/013e242c-8828-4970-87b3-ab247555486d"
    
    # Compute
    allowed_vm_skus = "/providers/Microsoft.Authorization/policyDefinitions/cccc23c7-8427-4f53-ad12-b6a63eb452b3"
    
    # Web Apps
    https_web_apps = "/providers/Microsoft.Authorization/policyDefinitions/a4af4a39-4135-47fb-b175-47fbdf85311d"
    
    # WAF
    waf_enabled_app_gw    = "/providers/Microsoft.Authorization/policyDefinitions/564feb30-bf6a-4854-b4bb-0d2d2d1e6c66"
    waf_enabled_frontdoor = "/providers/Microsoft.Authorization/policyDefinitions/055aa869-bc98-4af8-bafc-23f1ab6ffe2c"
  }

  # Built-in Initiative IDs
  builtin_initiatives = {
    azure_security_benchmark = "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8"
    vm_insights              = "/providers/Microsoft.Authorization/policySetDefinitions/924bfe3a-762f-40e7-86dd-5c8b95eb09e6"
    nist_sp_800_53_r5        = "/providers/Microsoft.Authorization/policySetDefinitions/179d1daa-458f-4e47-8086-2a68d0d6c38f"
    iso_27001_2013           = "/providers/Microsoft.Authorization/policySetDefinitions/89c6cddc-1c73-4ac1-b19c-54d1a15a42f2"
  }

  # ══════════════════════════════════════════════════════════════════════════════
  # G01 Custom Policy References - CORRECTED WITH ACTUAL G01 KEYS
  # ══════════════════════════════════════════════════════════════════════════════

  # Network policies from G01
  g01_audit_vnet_peered_to_hub   = lookup(var.policy_definition_ids, "audit-vnet-peered-to-hub", null)
  g01_audit_route_to_firewall    = lookup(var.policy_definition_ids, "audit-route-to-firewall", null)
  g01_audit_route_via_firewall   = lookup(var.policy_definition_ids, "audit-route-via-firewall", null)
  g01_audit_hub_vnet_australia   = lookup(var.policy_definition_ids, "audit-hub-vnet-australia-east", null)
  g01_audit_firewall_premium     = lookup(var.policy_definition_ids, "audit-firewall-premium", null)
  g01_audit_private_dns_hub_link = lookup(var.policy_definition_ids, "audit-private-dns-hub-link", null)
  g01_audit_public_ip_appgw      = lookup(var.policy_definition_ids, "audit-public-ip-via-appgw-frontdoor", null)
  g01_disabled_ddos              = lookup(var.policy_definition_ids, "disabled-ddos-standard", null)

  # Security policies from G01
  g01_deny_storage_public        = lookup(var.policy_definition_ids, "deny-storage-public-access", null)
  g01_audit_storage_public_np    = lookup(var.policy_definition_ids, "audit-storage-public-access-nonprod", null)
  g01_deny_sql_public            = lookup(var.policy_definition_ids, "deny-sql-public-access", null)
  g01_deny_cosmos_public         = lookup(var.policy_definition_ids, "deny-cosmos-public-access", null)
  g01_deny_appservice_public     = lookup(var.policy_definition_ids, "deny-appservice-public-access", null)
  g01_audit_private_endpoints    = lookup(var.policy_definition_ids, "audit-private-endpoints-recommended", null)

  # Monitoring policies from G01
  g01_deploy_diag_settings       = lookup(var.policy_definition_ids, "deploy-diagnostic-settings-la", null)
  g01_audit_la_retention         = lookup(var.policy_definition_ids, "audit-la-retention-minimum", null)
  g01_audit_la_archive           = lookup(var.policy_definition_ids, "audit-la-archive-enabled", null)
  g01_audit_sentinel_connectors  = lookup(var.policy_definition_ids, "audit-sentinel-connectors", null)

  # Backup policies from G01
  g01_audit_backup_grs_prod      = lookup(var.policy_definition_ids, "audit-backup-grs-production", null)
  g01_audit_backup_grs_cross     = lookup(var.policy_definition_ids, "audit-backup-grs-cross-region", null)
  g01_audit_backup_lrs_nonprod   = lookup(var.policy_definition_ids, "audit-backup-lrs-nonproduction", null)
  g01_audit_backup_lrs_sufficient = lookup(var.policy_definition_ids, "audit-backup-lrs-sufficient", null)

  # Cost policies from G01
  g01_audit_budget_configured    = lookup(var.policy_definition_ids, "audit-budget-configured", null)
  g01_deny_expensive_vm_skus     = lookup(var.policy_definition_ids, "deny-expensive-vm-skus", null)
  g01_deny_expensive_resources   = lookup(var.policy_definition_ids, "deny-expensive-resources", null)

  # Lifecycle policies from G01
  g01_deny_without_expiration    = lookup(var.policy_definition_ids, "deny-without-expiration-tag", null)
  g01_audit_only_sandbox         = lookup(var.policy_definition_ids, "audit-only-sandbox-mode", null)
  g01_deploy_auto_delete         = lookup(var.policy_definition_ids, "deploy-auto-delete-expired", null)

  # Identity policies from G01
  g01_audit_domain_services      = lookup(var.policy_definition_ids, "audit-domain-services-required", null)

  # Decommissioned policies from G01
  g01_deny_all_creation          = lookup(var.policy_definition_ids, "deny-all-resource-creation", null)
  g01_deny_all_modification      = lookup(var.policy_definition_ids, "deny-all-resource-modification", null)

  # ══════════════════════════════════════════════════════════════════════════════
  # CAF Baseline Initiative Definitions
  # ══════════════════════════════════════════════════════════════════════════════

  # Security Baseline Initiative
  security_initiative_policies = var.deploy_caf_initiatives && var.deploy_security_initiative ? [
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
    },
    {
      policy_definition_id = local.g01_deny_storage_public
      reference_id         = "DenyStoragePublicAccess"
      parameter_values     = null
    },
    {
      policy_definition_id = local.g01_deny_sql_public
      reference_id         = "DenySqlPublicAccess"
      parameter_values     = null
    },
    {
      policy_definition_id = local.g01_deny_cosmos_public
      reference_id         = "DenyCosmosPublicAccess"
      parameter_values     = null
    },
    {
      policy_definition_id = local.g01_deny_appservice_public
      reference_id         = "DenyAppServicePublicAccess"
      parameter_values     = null
    }
  ] : []

  # Network Baseline Initiative
  network_initiative_policies = var.deploy_caf_initiatives && var.deploy_network_initiative ? [
    {
      policy_definition_id = local.g01_audit_vnet_peered_to_hub
      reference_id         = "VnetPeeredToHub"
      parameter_values     = null
    },
    {
      policy_definition_id = local.g01_audit_route_to_firewall
      reference_id         = "RouteToFirewall"
      parameter_values     = null
    },
    {
      policy_definition_id = local.g01_audit_hub_vnet_australia
      reference_id         = "HubVnetAustraliaEast"
      parameter_values     = null
    },
    {
      policy_definition_id = local.g01_audit_firewall_premium
      reference_id         = "FirewallPremium"
      parameter_values     = null
    },
    {
      policy_definition_id = local.g01_audit_private_dns_hub_link
      reference_id         = "PrivateDnsLinkedToHub"
      parameter_values     = null
    },
    {
      policy_definition_id = local.g01_disabled_ddos
      reference_id         = "DdosStandardDisabled"
      parameter_values     = null
    }
  ] : []

  # Monitoring Baseline Initiative
  monitoring_initiative_policies = var.deploy_caf_initiatives && var.deploy_monitoring_initiative ? [
    {
      policy_definition_id = local.g01_audit_la_retention
      reference_id         = "LogAnalyticsRetention"
      parameter_values     = null
    },
    {
      policy_definition_id = local.g01_audit_la_archive
      reference_id         = "LogAnalyticsArchive"
      parameter_values     = null
    },
    {
      policy_definition_id = local.g01_audit_sentinel_connectors
      reference_id         = "SentinelConnectors"
      parameter_values     = null
    }
  ] : []

  # Governance Baseline Initiative (Tags & Locations)
  governance_initiative_policies = var.deploy_caf_initiatives && var.deploy_governance_initiative ? concat(
    [
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
    ],
    [for tag in var.required_tags : {
      policy_definition_id = local.builtin_policies.require_tag_rg
      reference_id         = "RequireTag${replace(tag, "/[^a-zA-Z0-9]/", "")}"
      parameter_values     = jsonencode({ tagName = { value = tag } })
    }]
  ) : []

  # Backup Baseline Initiative
  backup_initiative_policies = var.deploy_caf_initiatives && var.deploy_backup_initiative ? [
    {
      policy_definition_id = local.builtin_policies.backup_enabled_vms
      reference_id         = "BackupEnabledVms"
      parameter_values     = null
    },
    {
      policy_definition_id = local.g01_audit_backup_grs_prod
      reference_id         = "BackupGrsProduction"
      parameter_values     = null
    },
    {
      policy_definition_id = local.g01_audit_backup_lrs_nonprod
      reference_id         = "BackupLrsNonProduction"
      parameter_values     = null
    }
  ] : []

  # Cost Management Initiative
  cost_initiative_policies = var.deploy_caf_initiatives && var.deploy_cost_initiative ? [
    {
      policy_definition_id = local.g01_audit_budget_configured
      reference_id         = "BudgetConfigured"
      parameter_values     = null
    }
  ] : []

  # Identity Baseline Initiative
  identity_initiative_policies = var.deploy_caf_initiatives && var.deploy_identity_initiative ? [
    {
      policy_definition_id = local.g01_audit_domain_services
      reference_id         = "DomainServicesRequired"
      parameter_values     = null
    }
  ] : []

  # ══════════════════════════════════════════════════════════════════════════════
  # Archetype-Specific Initiative Definitions
  # ══════════════════════════════════════════════════════════════════════════════

  # Online-Prod Archetype Initiative
  online_prod_policies = var.deploy_archetype_initiatives && contains(var.archetypes_to_deploy, "online-prod") ? [
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
    },
    {
      policy_definition_id = local.g01_audit_public_ip_appgw
      reference_id         = "PublicIpViaAppGw"
      parameter_values     = null
    },
    {
      policy_definition_id = local.g01_audit_backup_grs_prod
      reference_id         = "BackupGrsProduction"
      parameter_values     = null
    },
    {
      policy_definition_id = local.g01_audit_backup_grs_cross
      reference_id         = "BackupGrsCrossRegion"
      parameter_values     = null
    }
  ] : []

  # Online-NonProd Archetype Initiative
  online_nonprod_policies = var.deploy_archetype_initiatives && contains(var.archetypes_to_deploy, "online-nonprod") ? [
    {
      policy_definition_id = local.builtin_policies.waf_enabled_app_gw
      reference_id         = "WafRecommended"
      parameter_values     = null
    },
    {
      policy_definition_id = local.builtin_policies.https_web_apps
      reference_id         = "HttpsWebApps"
      parameter_values     = null
    },
    {
      policy_definition_id = local.g01_audit_backup_lrs_nonprod
      reference_id         = "BackupLrsNonProd"
      parameter_values     = null
    },
    {
      policy_definition_id = local.g01_audit_storage_public_np
      reference_id         = "AuditStoragePublicAccess"
      parameter_values     = null
    }
  ] : []

  # Corp-Prod Archetype Initiative
  corp_prod_policies = var.deploy_archetype_initiatives && contains(var.archetypes_to_deploy, "corp-prod") ? [
    {
      policy_definition_id = local.g01_deny_storage_public
      reference_id         = "DenyStoragePublicAccess"
      parameter_values     = null
    },
    {
      policy_definition_id = local.g01_deny_sql_public
      reference_id         = "DenySqlPublicAccess"
      parameter_values     = null
    },
    {
      policy_definition_id = local.g01_deny_cosmos_public
      reference_id         = "DenyCosmosPublicAccess"
      parameter_values     = null
    },
    {
      policy_definition_id = local.g01_deny_appservice_public
      reference_id         = "DenyAppServicePublicAccess"
      parameter_values     = null
    },
    {
      policy_definition_id = local.builtin_policies.https_web_apps
      reference_id         = "HttpsWebApps"
      parameter_values     = null
    },
    {
      policy_definition_id = local.g01_audit_backup_grs_prod
      reference_id         = "BackupGrsProduction"
      parameter_values     = null
    },
    {
      policy_definition_id = local.g01_audit_backup_grs_cross
      reference_id         = "BackupGrsCrossRegion"
      parameter_values     = null
    }
  ] : []

  # Corp-NonProd Archetype Initiative
  corp_nonprod_policies = var.deploy_archetype_initiatives && contains(var.archetypes_to_deploy, "corp-nonprod") ? [
    {
      policy_definition_id = local.g01_audit_private_endpoints
      reference_id         = "PrivateEndpointsRecommended"
      parameter_values     = null
    },
    {
      policy_definition_id = local.g01_audit_storage_public_np
      reference_id         = "AuditStoragePublicAccess"
      parameter_values     = null
    },
    {
      policy_definition_id = local.g01_audit_backup_lrs_nonprod
      reference_id         = "BackupLrsNonProd"
      parameter_values     = null
    }
  ] : []

  # Sandbox Archetype Initiative
  # NOTE: deploy-auto-delete-expired removed - policy has DeployIfNotExists configuration issue in G01
  sandbox_policies = var.deploy_archetype_initiatives && contains(var.archetypes_to_deploy, "sandbox") ? [
    {
      policy_definition_id = local.builtin_policies.allowed_vm_skus
      reference_id         = "AllowedVmSkus"
      parameter_values     = jsonencode({ listOfAllowedSKUs = { value = var.allowed_vm_skus_sandbox } })
    },
    {
      policy_definition_id = local.g01_deny_expensive_vm_skus
      reference_id         = "DenyExpensiveVmSkus"
      parameter_values     = null
    },
    {
      policy_definition_id = local.g01_deny_expensive_resources
      reference_id         = "DenyExpensiveResources"
      parameter_values     = null
    },
    {
      policy_definition_id = local.g01_deny_without_expiration
      reference_id         = "RequireExpirationTag"
      parameter_values     = null
    },
    {
      policy_definition_id = local.g01_audit_only_sandbox
      reference_id         = "AuditOnlySandbox"
      parameter_values     = null
    }
  ] : []

  # Decommissioned Archetype Initiative
  decommissioned_policies = var.deploy_archetype_initiatives && contains(var.archetypes_to_deploy, "decommissioned") ? [
    {
      policy_definition_id = local.g01_deny_all_creation
      reference_id         = "DenyAllCreation"
      parameter_values     = null
    },
    {
      policy_definition_id = local.g01_deny_all_modification
      reference_id         = "DenyAllModification"
      parameter_values     = null
    }
  ] : []

  # ══════════════════════════════════════════════════════════════════════════════
  # Initiative Definitions Map
  # ══════════════════════════════════════════════════════════════════════════════

  # Filter out null policy references
  filter_null_policies = { for k, v in {
    security_initiative_policies   = local.security_initiative_policies
    network_initiative_policies    = local.network_initiative_policies
    monitoring_initiative_policies = local.monitoring_initiative_policies
    governance_initiative_policies = local.governance_initiative_policies
    backup_initiative_policies     = local.backup_initiative_policies
    cost_initiative_policies       = local.cost_initiative_policies
    identity_initiative_policies   = local.identity_initiative_policies
    online_prod_policies           = local.online_prod_policies
    online_nonprod_policies        = local.online_nonprod_policies
    corp_prod_policies             = local.corp_prod_policies
    corp_nonprod_policies          = local.corp_nonprod_policies
    sandbox_policies               = local.sandbox_policies
    decommissioned_policies        = local.decommissioned_policies
  } : k => [for p in v : p if p.policy_definition_id != null] }

  # CAF Baseline Initiatives
  caf_initiatives = var.deploy_caf_initiatives ? {
    "caf-security-baseline" = {
      display_name = "CAF Security Baseline"
      description  = "Security baseline policies for CAF Landing Zone including storage security, Key Vault hardening, and private endpoints."
      category     = "Security"
      policies     = local.filter_null_policies.security_initiative_policies
    }
    "caf-network-baseline" = {
      display_name = "CAF Network Baseline"
      description  = "Network baseline policies for CAF Landing Zone including hub validation, firewall routing, and DNS zones."
      category     = "Network"
      policies     = local.filter_null_policies.network_initiative_policies
    }
    "caf-monitoring-baseline" = {
      display_name = "CAF Monitoring Baseline"
      description  = "Monitoring baseline policies for CAF Landing Zone including Log Analytics retention and Sentinel."
      category     = "Monitoring"
      policies     = local.filter_null_policies.monitoring_initiative_policies
    }
    "caf-governance-baseline" = {
      display_name = "CAF Governance Baseline"
      description  = "Governance baseline policies for CAF Landing Zone including allowed locations and required tags."
      category     = "Governance"
      policies     = local.filter_null_policies.governance_initiative_policies
    }
    "caf-backup-baseline" = {
      display_name = "CAF Backup Baseline"
      description  = "Backup baseline policies for CAF Landing Zone including GRS/LRS requirements."
      category     = "Backup"
      policies     = local.filter_null_policies.backup_initiative_policies
    }
    "caf-cost-baseline" = {
      display_name = "CAF Cost Management Baseline"
      description  = "Cost management policies for CAF Landing Zone including budget requirements."
      category     = "Cost Management"
      policies     = local.filter_null_policies.cost_initiative_policies
    }
    "caf-identity-baseline" = {
      display_name = "CAF Identity Baseline"
      description  = "Identity baseline policies for CAF Landing Zone including domain services requirements."
      category     = "Identity"
      policies     = local.filter_null_policies.identity_initiative_policies
    }
  } : {}

  # Archetype-Specific Initiatives
  archetype_initiatives = var.deploy_archetype_initiatives ? {
    "caf-online-prod" = {
      display_name = "CAF Online Production"
      description  = "Policy initiative for Online Production Landing Zone. Enforces WAF, HTTPS, and GRS backup."
      category     = "Landing Zone"
      policies     = local.filter_null_policies.online_prod_policies
    }
    "caf-online-nonprod" = {
      display_name = "CAF Online Non-Production"
      description  = "Policy initiative for Online Non-Production Landing Zone. WAF recommended, HTTPS required."
      category     = "Landing Zone"
      policies     = local.filter_null_policies.online_nonprod_policies
    }
    "caf-corp-prod" = {
      display_name = "CAF Corporate Production"
      description  = "Policy initiative for Corporate Production Landing Zone. Denies public access, requires private endpoints and GRS backup."
      category     = "Landing Zone"
      policies     = local.filter_null_policies.corp_prod_policies
    }
    "caf-corp-nonprod" = {
      display_name = "CAF Corporate Non-Production"
      description  = "Policy initiative for Corporate Non-Production Landing Zone. Audits public access, recommends private endpoints."
      category     = "Landing Zone"
      policies     = local.filter_null_policies.corp_nonprod_policies
    }
    "caf-sandbox" = {
      display_name = "CAF Sandbox"
      description  = "Policy initiative for Sandbox Landing Zone. Limited VM SKUs, expiration tag required, auto-delete expired resources."
      category     = "Landing Zone"
      policies     = local.filter_null_policies.sandbox_policies
    }
    "caf-decommissioned" = {
      display_name = "CAF Decommissioned"
      description  = "Policy initiative for Decommissioned subscriptions. Denies all resource creation and modification."
      category     = "Landing Zone"
      policies     = local.filter_null_policies.decommissioned_policies
    }
  } : {}

  # Combine all CAF initiatives - only include initiatives with at least one policy
  all_caf_initiatives = merge(
    { for k, v in local.caf_initiatives : k => v if length(v.policies) > 0 },
    { for k, v in local.archetype_initiatives : k => v if length(v.policies) > 0 }
  )

  # Built-in initiatives for direct assignment via G03
  builtin_initiatives_for_assignment = {
    azure_security_benchmark = var.include_azure_security_benchmark ? local.builtin_initiatives.azure_security_benchmark : null
    vm_insights              = var.include_vm_insights ? local.builtin_initiatives.vm_insights : null
    nist_sp_800_53_r5        = var.include_nist_initiative ? local.builtin_initiatives.nist_sp_800_53_r5 : null
    iso_27001_2013           = var.include_iso27001_initiative ? local.builtin_initiatives.iso_27001_2013 : null
  }
}
