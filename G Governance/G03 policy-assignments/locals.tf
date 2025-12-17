################################################################################
# Locals - Policy Assignments (G03)
# Calculations, transformations, and assignment configurations
################################################################################

locals {
  # ════════════════════════════════════════════════════════════════════════════
  # Tags
  # ════════════════════════════════════════════════════════════════════════════
  
  default_tags = {
    ManagedBy = "Terraform"
    Module    = "policy-assignments"
  }
  
  tags = merge(local.default_tags, var.tags)

  # ════════════════════════════════════════════════════════════════════════════
  # Management Group References
  # ════════════════════════════════════════════════════════════════════════════
  
  # Safely lookup management group IDs with fallback to empty string
  mg_root           = lookup(var.management_group_hierarchy, "root", "")
  mg_platform       = lookup(var.management_group_hierarchy, "platform", "")
  mg_management     = lookup(var.management_group_hierarchy, "management", "")
  mg_connectivity   = lookup(var.management_group_hierarchy, "connectivity", "")
  mg_identity       = lookup(var.management_group_hierarchy, "identity", "")
  mg_landing_zones  = lookup(var.management_group_hierarchy, "landing_zones", "")
  mg_corp_prod      = lookup(var.management_group_hierarchy, "corp_prod", "")
  mg_corp_nonprod   = lookup(var.management_group_hierarchy, "corp_nonprod", "")
  mg_online_prod    = lookup(var.management_group_hierarchy, "online_prod", "")
  mg_online_nonprod = lookup(var.management_group_hierarchy, "online_nonprod", "")
  mg_sandbox        = lookup(var.management_group_hierarchy, "sandbox", "")
  mg_decommissioned = lookup(var.management_group_hierarchy, "decommissioned", "")

  # ════════════════════════════════════════════════════════════════════════════
  # Built-in Policy/Initiative IDs
  # ════════════════════════════════════════════════════════════════════════════
  
  builtin_policy_ids = {
    allowed_locations           = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
    allowed_locations_rg        = "/providers/Microsoft.Authorization/policyDefinitions/e765b5de-1225-4ba3-bd56-1ac6695af988"
    not_allowed_resource_types  = "/providers/Microsoft.Authorization/policyDefinitions/6c112d4e-5bc7-47ae-a041-ea2d9dccd749"
    require_tag_rg              = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"
    inherit_tag_rg              = "/providers/Microsoft.Authorization/policyDefinitions/cd3aa116-8754-49c9-a813-ad46512ece54"
    ama_installed               = "/providers/Microsoft.Authorization/policyDefinitions/32133ab0-ee4b-4b44-98d6-042180979d50"
    defender_enabled            = "/providers/Microsoft.Authorization/policyDefinitions/0015ea4d-51ff-4ce3-8d8c-f3f8f0179a56"
    secure_transfer_storage     = "/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9"
    vm_encryption_host          = "/providers/Microsoft.Authorization/policyDefinitions/fc4d8e41-e223-45ea-9bf5-eada37891d87"
    backup_vms                  = "/providers/Microsoft.Authorization/policyDefinitions/013e242c-8828-4970-87b3-ab247555486d"
    subnet_nsg                  = "/providers/Microsoft.Authorization/policyDefinitions/f1776c76-f58c-4245-a9d0-bf0a1b89ed0e"
    nsg_flow_logs               = "/providers/Microsoft.Authorization/policyDefinitions/27960feb-a23c-4577-8d36-ef8b5f35e0be"
    keyvault_rbac               = "/providers/Microsoft.Authorization/policyDefinitions/12d4fa5e-1f9f-4c21-97a9-b99b3c6611b5"
    keyvault_soft_delete        = "/providers/Microsoft.Authorization/policyDefinitions/1e66c121-a66a-4b1f-9b83-0fd99bf0fc2d"
    keyvault_purge_protection   = "/providers/Microsoft.Authorization/policyDefinitions/0b60c0b2-2dc2-4e1c-b5c9-abbed971de53"
    waf_appgw                   = "/providers/Microsoft.Authorization/policyDefinitions/564feb30-bf6a-4854-b4bb-0d2d2d1e6c66"
    waf_frontdoor               = "/providers/Microsoft.Authorization/policyDefinitions/055aa869-bc98-4af8-bafc-23f1ab6ffe2c"
    webapp_https                = "/providers/Microsoft.Authorization/policyDefinitions/a4af4a39-4135-47fb-b175-47fbdf85311d"
    tls_minimum                 = "/providers/Microsoft.Authorization/policyDefinitions/f0e6e85b-9b9f-4a4b-b67b-f730d42f1b0b"
    deny_public_ip              = "/providers/Microsoft.Authorization/policyDefinitions/6c112d4e-5bc7-47ae-a041-ea2d9dccd749"
    deny_public_ip_on_nic       = "/providers/Microsoft.Authorization/policyDefinitions/83a86a26-fd1f-447c-b59d-e51f44264114"
    managed_identity            = "/providers/Microsoft.Authorization/policyDefinitions/2f83ccfe-70c0-4ca4-bb7c-b1f26c826a8f"
    allowed_vm_skus             = "/providers/Microsoft.Authorization/policyDefinitions/cccc23c7-8427-4f53-ad12-b6a63eb452b3"
    storage_deny_public         = "/providers/Microsoft.Authorization/policyDefinitions/b2982f36-99f2-4db5-8eff-283140c09693"
    sql_private_endpoint        = "/providers/Microsoft.Authorization/policyDefinitions/28b0b1e5-17ba-4963-a7a4-5a1ab4400a0b"
    cosmos_private_endpoint     = "/providers/Microsoft.Authorization/policyDefinitions/797b37f7-06b8-444c-b1ad-fc62867f335a"
  }

  builtin_initiative_ids = {
    azure_security_benchmark = "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8"
    vm_insights              = "/providers/Microsoft.Authorization/policySetDefinitions/924bfe3a-762f-40e7-86dd-5c8b95eb09e6"
    nist_sp_800_53_r5        = "/providers/Microsoft.Authorization/policySetDefinitions/179d1daa-458f-4e47-8086-2a68d0d6c38f"
    iso_27001_2013           = "/providers/Microsoft.Authorization/policySetDefinitions/89c6cddc-1c73-4ac1-b19c-54d1a15a42f2"
  }

  # ════════════════════════════════════════════════════════════════════════════
  # Initiative References from G02 (with safe lookup)
  # ════════════════════════════════════════════════════════════════════════════
  
  # Baseline initiatives
  init_security_baseline   = lookup(var.initiative_ids, "caf-security-baseline", null)
  init_network_baseline    = lookup(var.initiative_ids, "caf-network-baseline", null)
  init_monitoring_baseline = lookup(var.initiative_ids, "caf-monitoring-baseline", null)
  init_governance_baseline = lookup(var.initiative_ids, "caf-governance-baseline", null)
  init_backup_baseline     = lookup(var.initiative_ids, "caf-backup-baseline", null)
  init_cost_baseline       = lookup(var.initiative_ids, "caf-cost-baseline", null)
  init_identity_baseline   = lookup(var.initiative_ids, "caf-identity-baseline", null)

  # Archetype initiatives
  init_online_prod    = lookup(var.initiative_ids, "caf-online-prod", null)
  init_online_nonprod = lookup(var.initiative_ids, "caf-online-nonprod", null)
  init_corp_prod      = lookup(var.initiative_ids, "caf-corp-prod", null)
  init_corp_nonprod   = lookup(var.initiative_ids, "caf-corp-nonprod", null)
  init_sandbox        = lookup(var.initiative_ids, "caf-sandbox", null)
  init_decommissioned = lookup(var.initiative_ids, "caf-decommissioned", null)

  # ════════════════════════════════════════════════════════════════════════════
  # Enforcement Mode
  # ════════════════════════════════════════════════════════════════════════════
  
  # Use override if set, otherwise use default "Default"
  default_enforcement_mode = coalesce(var.enforcement_mode_override, "Default")

  # ════════════════════════════════════════════════════════════════════════════
  # Common Parameters
  # ════════════════════════════════════════════════════════════════════════════
  
  # Allowed locations parameter (used by multiple policies)
  allowed_locations_param = jsonencode({
    listOfAllowedLocations = {
      value = var.allowed_locations
    }
  })

  # Required tags parameters
  required_tags_params = {
    for tag in var.required_tags : "tagName_${tag}" => {
      value = tag
    }
  }

  # Log Analytics workspace parameter
  log_analytics_param = var.log_analytics_workspace_id != "" ? jsonencode({
    logAnalyticsWorkspaceId = {
      value = var.log_analytics_workspace_id
    }
  }) : null

  # Allowed VM SKUs for Sandbox
  allowed_vm_skus_param = jsonencode({
    listOfAllowedSKUs = {
      value = var.allowed_vm_skus_sandbox
    }
  })

  # ════════════════════════════════════════════════════════════════════════════
  # Assignment Metadata
  # ════════════════════════════════════════════════════════════════════════════
  
  base_metadata = merge(var.assignment_metadata, {
    assignedBy = "Terraform"
    project    = "CAF Landing Zone Australia"
    version    = "1.0.0"
  })

  # ════════════════════════════════════════════════════════════════════════════
  # ROOT LEVEL ASSIGNMENTS
  # ════════════════════════════════════════════════════════════════════════════
  
  root_assignments = var.deploy_root_assignments && local.mg_root != "" ? {
    # Allowed Locations
    "root-allowed-locations" = {
      policy_definition_id   = local.builtin_policy_ids.allowed_locations
      display_name           = "Allowed locations"
      description            = "Restricts deployments to Australia East and Australia Southeast only."
      enforcement_mode       = local.default_enforcement_mode
      parameters             = local.allowed_locations_param
      non_compliance_message = "${var.non_compliance_message_prefix} Resources must be deployed in Australia East or Australia Southeast."
      identity_type          = "None"
    }

    # Allowed Locations for Resource Groups
    "root-allowed-locations-rg" = {
      policy_definition_id   = local.builtin_policy_ids.allowed_locations_rg
      display_name           = "Allowed locations for resource groups"
      description            = "Restricts resource group creation to Australia East and Australia Southeast."
      enforcement_mode       = local.default_enforcement_mode
      parameters             = local.allowed_locations_param
      non_compliance_message = "${var.non_compliance_message_prefix} Resource groups must be created in Australia East or Australia Southeast."
      identity_type          = "None"
    }

    # Secure transfer to storage accounts
    "root-secure-transfer-storage" = {
      policy_definition_id   = local.builtin_policy_ids.secure_transfer_storage
      display_name           = "Secure transfer to storage accounts should be enabled"
      description            = "Audit secure transfer requirement for storage accounts."
      enforcement_mode       = local.default_enforcement_mode
      parameters             = null
      non_compliance_message = "${var.non_compliance_message_prefix} Storage accounts must have secure transfer enabled (HTTPS only)."
      identity_type          = "None"
    }

    # Azure Monitor Agent installed
    "root-ama-installed" = {
      policy_definition_id   = local.builtin_policy_ids.ama_installed
      display_name           = "Azure Monitor Agent should be installed on virtual machines"
      description            = "Audit that Azure Monitor Agent is installed on all VMs."
      enforcement_mode       = local.default_enforcement_mode
      parameters             = null
      non_compliance_message = "${var.non_compliance_message_prefix} Virtual machines must have Azure Monitor Agent installed."
      identity_type          = "None"
    }

    # Microsoft Defender for Cloud
    "root-defender-enabled" = {
      policy_definition_id   = local.builtin_policy_ids.defender_enabled
      display_name           = "Microsoft Defender for Cloud should be enabled"
      description            = "Audit that Microsoft Defender for Cloud is enabled."
      enforcement_mode       = local.default_enforcement_mode
      parameters             = null
      non_compliance_message = "${var.non_compliance_message_prefix} Microsoft Defender for Cloud must be enabled."
      identity_type          = "None"
    }

    # VM encryption at host
    "root-vm-encryption-host" = {
      policy_definition_id   = local.builtin_policy_ids.vm_encryption_host
      display_name           = "Virtual machines should have encryption at host enabled"
      description            = "Audit encryption at host for virtual machines."
      enforcement_mode       = local.default_enforcement_mode
      parameters             = null
      non_compliance_message = "${var.non_compliance_message_prefix} Virtual machines should have encryption at host enabled."
      identity_type          = "None"
    }

    # Azure Backup for VMs
    "root-backup-vms" = {
      policy_definition_id   = local.builtin_policy_ids.backup_vms
      display_name           = "Azure Backup should be enabled for Virtual Machines"
      description            = "Audit that Azure Backup is configured for all VMs."
      enforcement_mode       = local.default_enforcement_mode
      parameters             = null
      non_compliance_message = "${var.non_compliance_message_prefix} Virtual machines must have Azure Backup configured."
      identity_type          = "None"
    }
  } : {}

  # Root initiative assignments
  root_initiative_assignments = var.deploy_root_assignments && local.mg_root != "" ? merge(
    # CAF Governance Baseline
    local.init_governance_baseline != null ? {
      "root-governance-baseline" = {
        policy_set_definition_id = local.init_governance_baseline
        display_name             = "CAF Governance Baseline"
        description              = "Governance baseline initiative including required tags and naming conventions."
        enforcement_mode         = local.default_enforcement_mode
        parameters               = null
        non_compliance_message   = "${var.non_compliance_message_prefix} Resource does not comply with governance baseline."
        identity_type            = "None"
      }
    } : {},
    # CAF Monitoring Baseline
    local.init_monitoring_baseline != null ? {
      "root-monitoring-baseline" = {
        policy_set_definition_id = local.init_monitoring_baseline
        display_name             = "CAF Monitoring Baseline"
        description              = "Monitoring baseline initiative for diagnostic settings and Log Analytics."
        enforcement_mode         = local.default_enforcement_mode
        parameters               = local.log_analytics_param
        non_compliance_message   = "${var.non_compliance_message_prefix} Resource does not comply with monitoring baseline."
        identity_type            = "SystemAssigned"
      }
    } : {}
  ) : {}

  # ════════════════════════════════════════════════════════════════════════════
  # PLATFORM LEVEL ASSIGNMENTS
  # ════════════════════════════════════════════════════════════════════════════
  
  platform_assignments = var.deploy_platform_assignments && local.mg_platform != "" ? {} : {}

  platform_initiative_assignments = var.deploy_platform_assignments && local.mg_platform != "" ? merge(
    # Azure Security Benchmark
    var.assign_azure_security_benchmark ? {
      "platform-azure-security-benchmark" = {
        policy_set_definition_id = local.builtin_initiative_ids.azure_security_benchmark
        display_name             = "Azure Security Benchmark"
        description              = "Azure Security Benchmark initiative for comprehensive security compliance."
        enforcement_mode         = "DoNotEnforce" # Audit only for security benchmark
        parameters               = null
        non_compliance_message   = "${var.non_compliance_message_prefix} Resource does not comply with Azure Security Benchmark."
        identity_type            = "None"
      }
    } : {},
    # VM Insights
    var.assign_vm_insights ? {
      "platform-vm-insights" = {
        policy_set_definition_id = local.builtin_initiative_ids.vm_insights
        display_name             = "Enable Azure Monitor for VMs"
        description              = "VM Insights initiative for automatic monitoring configuration."
        enforcement_mode         = local.default_enforcement_mode
        parameters               = local.log_analytics_param
        non_compliance_message   = "${var.non_compliance_message_prefix} VM Insights must be enabled."
        identity_type            = "SystemAssigned"
      }
    } : {},
    # CAF Security Baseline
    local.init_security_baseline != null ? {
      "platform-security-baseline" = {
        policy_set_definition_id = local.init_security_baseline
        display_name             = "CAF Security Baseline"
        description              = "Security baseline initiative for Platform resources."
        enforcement_mode         = local.default_enforcement_mode
        parameters               = null
        non_compliance_message   = "${var.non_compliance_message_prefix} Resource does not comply with security baseline."
        identity_type            = "None"
      }
    } : {},
    # CAF Network Baseline
    local.init_network_baseline != null ? {
      "platform-network-baseline" = {
        policy_set_definition_id = local.init_network_baseline
        display_name             = "CAF Network Baseline"
        description              = "Network baseline initiative for Platform resources."
        enforcement_mode         = local.default_enforcement_mode
        parameters               = null
        non_compliance_message   = "${var.non_compliance_message_prefix} Resource does not comply with network baseline."
        identity_type            = "None"
      }
    } : {},
    # NIST SP 800-53 R5 (optional)
    var.assign_nist_sp_800_53 ? {
      "platform-nist-sp-800-53" = {
        policy_set_definition_id = local.builtin_initiative_ids.nist_sp_800_53_r5
        display_name             = "NIST SP 800-53 Rev. 5"
        description              = "NIST SP 800-53 R5 compliance reporting initiative."
        enforcement_mode         = "DoNotEnforce" # Compliance reporting only
        parameters               = null
        non_compliance_message   = "${var.non_compliance_message_prefix} Resource does not comply with NIST SP 800-53 R5."
        identity_type            = "None"
      }
    } : {},
    # ISO 27001:2013 (optional)
    var.assign_iso_27001 ? {
      "platform-iso-27001" = {
        policy_set_definition_id = local.builtin_initiative_ids.iso_27001_2013
        display_name             = "ISO 27001:2013"
        description              = "ISO 27001:2013 compliance reporting initiative."
        enforcement_mode         = "DoNotEnforce" # Compliance reporting only
        parameters               = null
        non_compliance_message   = "${var.non_compliance_message_prefix} Resource does not comply with ISO 27001:2013."
        identity_type            = "None"
      }
    } : {}
  ) : {}

  # ════════════════════════════════════════════════════════════════════════════
  # CONNECTIVITY MANAGEMENT GROUP ASSIGNMENTS
  # ════════════════════════════════════════════════════════════════════════════
  
  connectivity_assignments = var.deploy_platform_assignments && local.mg_connectivity != "" ? {
    # Subnets should have NSG
    "connectivity-subnet-nsg" = {
      policy_definition_id   = local.builtin_policy_ids.subnet_nsg
      display_name           = "Subnets should have a Network Security Group"
      description            = "Audit that all subnets have an associated NSG."
      enforcement_mode       = local.default_enforcement_mode
      parameters             = null
      non_compliance_message = "${var.non_compliance_message_prefix} All subnets must have an associated Network Security Group."
      identity_type          = "None"
    }
  } : {}

  # ════════════════════════════════════════════════════════════════════════════
  # LANDING ZONES LEVEL ASSIGNMENTS
  # ════════════════════════════════════════════════════════════════════════════
  
  landing_zones_assignments = var.deploy_landing_zone_assignments && local.mg_landing_zones != "" ? {
    # Key Vault RBAC
    "lz-keyvault-rbac" = {
      policy_definition_id   = local.builtin_policy_ids.keyvault_rbac
      display_name           = "Key Vault should use RBAC authorization"
      description            = "Audit that Key Vaults use RBAC permission model."
      enforcement_mode       = local.default_enforcement_mode
      parameters             = null
      non_compliance_message = "${var.non_compliance_message_prefix} Key Vaults must use RBAC authorization model."
      identity_type          = "None"
    }

    # Key Vault soft delete
    "lz-keyvault-soft-delete" = {
      policy_definition_id   = local.builtin_policy_ids.keyvault_soft_delete
      display_name           = "Key Vault should have soft delete enabled"
      description            = "Audit that Key Vaults have soft delete enabled."
      enforcement_mode       = local.default_enforcement_mode
      parameters             = null
      non_compliance_message = "${var.non_compliance_message_prefix} Key Vaults must have soft delete enabled."
      identity_type          = "None"
    }

    # Key Vault purge protection
    "lz-keyvault-purge-protection" = {
      policy_definition_id   = local.builtin_policy_ids.keyvault_purge_protection
      display_name           = "Key Vault should have purge protection enabled"
      description            = "Audit that Key Vaults have purge protection enabled."
      enforcement_mode       = local.default_enforcement_mode
      parameters             = null
      non_compliance_message = "${var.non_compliance_message_prefix} Key Vaults must have purge protection enabled."
      identity_type          = "None"
    }

    # NSG flow logs
    "lz-nsg-flow-logs" = {
      policy_definition_id   = local.builtin_policy_ids.nsg_flow_logs
      display_name           = "NSG flow logs should be enabled"
      description            = "Deploy NSG flow logs if not exists."
      enforcement_mode       = local.default_enforcement_mode
      parameters             = null
      non_compliance_message = "${var.non_compliance_message_prefix} Network Security Groups must have flow logs enabled."
      identity_type          = "SystemAssigned"
    }
  } : {}

  landing_zones_initiative_assignments = var.deploy_landing_zone_assignments && local.mg_landing_zones != "" ? merge(
    # CAF Backup Baseline
    local.init_backup_baseline != null ? {
      "lz-backup-baseline" = {
        policy_set_definition_id = local.init_backup_baseline
        display_name             = "CAF Backup Baseline"
        description              = "Backup baseline initiative for Landing Zone resources."
        enforcement_mode         = local.default_enforcement_mode
        parameters               = null
        non_compliance_message   = "${var.non_compliance_message_prefix} Resource does not comply with backup baseline."
        identity_type            = "None"
      }
    } : {},
    # CAF Cost Baseline
    local.init_cost_baseline != null ? {
      "lz-cost-baseline" = {
        policy_set_definition_id = local.init_cost_baseline
        display_name             = "CAF Cost Management Baseline"
        description              = "Cost management baseline initiative for Landing Zones."
        enforcement_mode         = local.default_enforcement_mode
        parameters               = null
        non_compliance_message   = "${var.non_compliance_message_prefix} Resource does not comply with cost management baseline."
        identity_type            = "None"
      }
    } : {}
  ) : {}

  # ════════════════════════════════════════════════════════════════════════════
  # ARCHETYPE-SPECIFIC ASSIGNMENTS
  # ════════════════════════════════════════════════════════════════════════════
  
  # Online-Prod
  online_prod_assignments = var.deploy_landing_zone_assignments && local.mg_online_prod != "" ? {
    # WAF on Application Gateway
    "online-prod-waf-appgw" = {
      policy_definition_id   = local.builtin_policy_ids.waf_appgw
      display_name           = "Web Application Firewall should be enabled for Application Gateway"
      description            = "WAF is required for all Application Gateways in Online-Prod."
      enforcement_mode       = local.default_enforcement_mode
      parameters             = null
      non_compliance_message = "${var.non_compliance_message_prefix} Application Gateways must have WAF enabled in production."
      identity_type          = "None"
    }

    # WAF on Front Door
    "online-prod-waf-frontdoor" = {
      policy_definition_id   = local.builtin_policy_ids.waf_frontdoor
      display_name           = "Web Application Firewall should be enabled for Front Door"
      description            = "WAF is required for all Front Door profiles in Online-Prod."
      enforcement_mode       = local.default_enforcement_mode
      parameters             = null
      non_compliance_message = "${var.non_compliance_message_prefix} Front Door must have WAF enabled in production."
      identity_type          = "None"
    }

    # HTTPS required for web apps
    "online-prod-webapp-https" = {
      policy_definition_id   = local.builtin_policy_ids.webapp_https
      display_name           = "Web Application should only be accessible over HTTPS"
      description            = "HTTPS is required for all web applications in Online-Prod."
      enforcement_mode       = local.default_enforcement_mode
      parameters             = null
      non_compliance_message = "${var.non_compliance_message_prefix} Web applications must be accessible over HTTPS only."
      identity_type          = "None"
    }

    # TLS 1.2 minimum
    "online-prod-tls-minimum" = {
      policy_definition_id   = local.builtin_policy_ids.tls_minimum
      display_name           = "TLS 1.2 should be the minimum version"
      description            = "Minimum TLS 1.2 is required for all resources in Online-Prod."
      enforcement_mode       = local.default_enforcement_mode
      parameters             = null
      non_compliance_message = "${var.non_compliance_message_prefix} Resources must use TLS 1.2 or higher."
      identity_type          = "None"
    }
  } : {}

  online_prod_initiative_assignments = var.deploy_landing_zone_assignments && local.mg_online_prod != "" && local.init_online_prod != null ? {
    "online-prod-archetype" = {
      policy_set_definition_id = local.init_online_prod
      display_name             = "CAF Online-Prod Archetype"
      description              = "Policy initiative for Online Production landing zones."
      enforcement_mode         = local.default_enforcement_mode
      parameters               = null
      non_compliance_message   = "${var.non_compliance_message_prefix} Resource does not comply with Online-Prod requirements."
      identity_type            = "None"
    }
  } : {}

  # Online-NonProd
  online_nonprod_assignments = var.deploy_landing_zone_assignments && local.mg_online_nonprod != "" ? {
    # HTTPS required (still enforced in non-prod)
    "online-nonprod-webapp-https" = {
      policy_definition_id   = local.builtin_policy_ids.webapp_https
      display_name           = "Web Application should only be accessible over HTTPS"
      description            = "HTTPS is required for all web applications in Online-NonProd."
      enforcement_mode       = local.default_enforcement_mode
      parameters             = null
      non_compliance_message = "${var.non_compliance_message_prefix} Web applications must be accessible over HTTPS only."
      identity_type          = "None"
    }
  } : {}

  online_nonprod_initiative_assignments = var.deploy_landing_zone_assignments && local.mg_online_nonprod != "" && local.init_online_nonprod != null ? {
    "online-nonprod-archetype" = {
      policy_set_definition_id = local.init_online_nonprod
      display_name             = "CAF Online-NonProd Archetype"
      description              = "Policy initiative for Online Non-Production landing zones."
      enforcement_mode         = local.default_enforcement_mode
      parameters               = null
      non_compliance_message   = "${var.non_compliance_message_prefix} Resource does not comply with Online-NonProd requirements."
      identity_type            = "None"
    }
  } : {}

  # Corp-Prod
  corp_prod_assignments = var.deploy_landing_zone_assignments && local.mg_corp_prod != "" ? {
    # Deny public IPs
    "corp-prod-deny-public-ip-nic" = {
      policy_definition_id   = local.builtin_policy_ids.deny_public_ip_on_nic
      display_name           = "Network interfaces should not have public IPs"
      description            = "Public IPs are not allowed on network interfaces in Corp-Prod."
      enforcement_mode       = local.default_enforcement_mode
      parameters             = null
      non_compliance_message = "${var.non_compliance_message_prefix} Network interfaces cannot have public IP addresses in Corp environments."
      identity_type          = "None"
    }

    # Storage deny public access
    "corp-prod-storage-deny-public" = {
      policy_definition_id   = local.builtin_policy_ids.storage_deny_public
      display_name           = "Storage accounts should deny public access"
      description            = "Storage accounts must deny public access in Corp-Prod."
      enforcement_mode       = local.default_enforcement_mode
      parameters             = null
      non_compliance_message = "${var.non_compliance_message_prefix} Storage accounts must deny public access in Corp environments."
      identity_type          = "None"
    }

    # SQL private endpoints
    "corp-prod-sql-private-endpoint" = {
      policy_definition_id   = local.builtin_policy_ids.sql_private_endpoint
      display_name           = "SQL Servers should use private endpoints"
      description            = "SQL Servers must use private endpoints in Corp-Prod."
      enforcement_mode       = local.default_enforcement_mode
      parameters             = null
      non_compliance_message = "${var.non_compliance_message_prefix} SQL Servers must use private endpoints in Corp environments."
      identity_type          = "None"
    }

    # Cosmos DB private endpoints
    "corp-prod-cosmos-private-endpoint" = {
      policy_definition_id   = local.builtin_policy_ids.cosmos_private_endpoint
      display_name           = "Cosmos DB should use private endpoints"
      description            = "Cosmos DB must use private endpoints in Corp-Prod."
      enforcement_mode       = local.default_enforcement_mode
      parameters             = null
      non_compliance_message = "${var.non_compliance_message_prefix} Cosmos DB must use private endpoints in Corp environments."
      identity_type          = "None"
    }
  } : {}

  corp_prod_initiative_assignments = var.deploy_landing_zone_assignments && local.mg_corp_prod != "" && local.init_corp_prod != null ? {
    "corp-prod-archetype" = {
      policy_set_definition_id = local.init_corp_prod
      display_name             = "CAF Corp-Prod Archetype"
      description              = "Policy initiative for Corporate Production landing zones."
      enforcement_mode         = local.default_enforcement_mode
      parameters               = null
      non_compliance_message   = "${var.non_compliance_message_prefix} Resource does not comply with Corp-Prod requirements."
      identity_type            = "None"
    }
  } : {}

  # Corp-NonProd
  corp_nonprod_assignments = var.deploy_landing_zone_assignments && local.mg_corp_nonprod != "" ? {
    # Deny public IPs (still enforced in non-prod for Corp)
    "corp-nonprod-deny-public-ip-nic" = {
      policy_definition_id   = local.builtin_policy_ids.deny_public_ip_on_nic
      display_name           = "Network interfaces should not have public IPs"
      description            = "Public IPs are not allowed on network interfaces in Corp-NonProd."
      enforcement_mode       = local.default_enforcement_mode
      parameters             = null
      non_compliance_message = "${var.non_compliance_message_prefix} Network interfaces cannot have public IP addresses in Corp environments."
      identity_type          = "None"
    }
  } : {}

  corp_nonprod_initiative_assignments = var.deploy_landing_zone_assignments && local.mg_corp_nonprod != "" && local.init_corp_nonprod != null ? {
    "corp-nonprod-archetype" = {
      policy_set_definition_id = local.init_corp_nonprod
      display_name             = "CAF Corp-NonProd Archetype"
      description              = "Policy initiative for Corporate Non-Production landing zones."
      enforcement_mode         = local.default_enforcement_mode
      parameters               = null
      non_compliance_message   = "${var.non_compliance_message_prefix} Resource does not comply with Corp-NonProd requirements."
      identity_type            = "None"
    }
  } : {}

  # Sandbox
  sandbox_assignments = var.deploy_landing_zone_assignments && local.mg_sandbox != "" ? {
    # Allowed VM SKUs (cost control)
    "sandbox-allowed-vm-skus" = {
      policy_definition_id   = local.builtin_policy_ids.allowed_vm_skus
      display_name           = "Allowed virtual machine size SKUs"
      description            = "Restricts VM SKUs to cost-effective sizes in Sandbox."
      enforcement_mode       = local.default_enforcement_mode
      parameters             = local.allowed_vm_skus_param
      non_compliance_message = "${var.non_compliance_message_prefix} Only B-series and small D-series VMs are allowed in Sandbox."
      identity_type          = "None"
    }
  } : {}

  sandbox_initiative_assignments = var.deploy_landing_zone_assignments && local.mg_sandbox != "" && local.init_sandbox != null ? {
    "sandbox-archetype" = {
      policy_set_definition_id = local.init_sandbox
      display_name             = "CAF Sandbox Archetype"
      description              = "Policy initiative for Sandbox landing zones with cost controls and expiration requirements."
      enforcement_mode         = local.default_enforcement_mode
      parameters               = null
      non_compliance_message   = "${var.non_compliance_message_prefix} Resource does not comply with Sandbox requirements."
      identity_type            = "None"
    }
  } : {}

  # ════════════════════════════════════════════════════════════════════════════
  # DECOMMISSIONED ASSIGNMENTS
  # ════════════════════════════════════════════════════════════════════════════
  
  decommissioned_initiative_assignments = var.deploy_decommissioned_assignments && local.mg_decommissioned != "" && local.init_decommissioned != null ? {
    "decommissioned-deny-all" = {
      policy_set_definition_id = local.init_decommissioned
      display_name             = "CAF Decommissioned - Deny All"
      description              = "Denies all resource creation and modification in Decommissioned management group."
      enforcement_mode         = local.default_enforcement_mode
      parameters               = null
      non_compliance_message   = "${var.non_compliance_message_prefix} No resource creation or modification is allowed in Decommissioned subscriptions."
      identity_type            = "None"
    }
  } : {}

  # ════════════════════════════════════════════════════════════════════════════
  # CONSOLIDATED ASSIGNMENT MAPS
  # ════════════════════════════════════════════════════════════════════════════
  
  # All policy assignments by scope
  all_policy_assignments = {
    root           = local.root_assignments
    platform       = local.platform_assignments
    connectivity   = local.connectivity_assignments
    landing_zones  = local.landing_zones_assignments
    online_prod    = local.online_prod_assignments
    online_nonprod = local.online_nonprod_assignments
    corp_prod      = local.corp_prod_assignments
    corp_nonprod   = local.corp_nonprod_assignments
    sandbox        = local.sandbox_assignments
  }

  # All initiative assignments by scope
  all_initiative_assignments = {
    root           = local.root_initiative_assignments
    platform       = local.platform_initiative_assignments
    landing_zones  = local.landing_zones_initiative_assignments
    online_prod    = local.online_prod_initiative_assignments
    online_nonprod = local.online_nonprod_initiative_assignments
    corp_prod      = local.corp_prod_initiative_assignments
    corp_nonprod   = local.corp_nonprod_initiative_assignments
    sandbox        = local.sandbox_initiative_assignments
    decommissioned = local.decommissioned_initiative_assignments
  }

  # Flattened maps for resource creation
  flattened_policy_assignments = merge(
    { for k, v in local.root_assignments : k => merge(v, { scope = local.mg_root }) },
    { for k, v in local.platform_assignments : k => merge(v, { scope = local.mg_platform }) },
    { for k, v in local.connectivity_assignments : k => merge(v, { scope = local.mg_connectivity }) },
    { for k, v in local.landing_zones_assignments : k => merge(v, { scope = local.mg_landing_zones }) },
    { for k, v in local.online_prod_assignments : k => merge(v, { scope = local.mg_online_prod }) },
    { for k, v in local.online_nonprod_assignments : k => merge(v, { scope = local.mg_online_nonprod }) },
    { for k, v in local.corp_prod_assignments : k => merge(v, { scope = local.mg_corp_prod }) },
    { for k, v in local.corp_nonprod_assignments : k => merge(v, { scope = local.mg_corp_nonprod }) },
    { for k, v in local.sandbox_assignments : k => merge(v, { scope = local.mg_sandbox }) }
  )

  flattened_initiative_assignments = merge(
    { for k, v in local.root_initiative_assignments : k => merge(v, { scope = local.mg_root }) },
    { for k, v in local.platform_initiative_assignments : k => merge(v, { scope = local.mg_platform }) },
    { for k, v in local.landing_zones_initiative_assignments : k => merge(v, { scope = local.mg_landing_zones }) },
    { for k, v in local.online_prod_initiative_assignments : k => merge(v, { scope = local.mg_online_prod }) },
    { for k, v in local.online_nonprod_initiative_assignments : k => merge(v, { scope = local.mg_online_nonprod }) },
    { for k, v in local.corp_prod_initiative_assignments : k => merge(v, { scope = local.mg_corp_prod }) },
    { for k, v in local.corp_nonprod_initiative_assignments : k => merge(v, { scope = local.mg_corp_nonprod }) },
    { for k, v in local.sandbox_initiative_assignments : k => merge(v, { scope = local.mg_sandbox }) },
    { for k, v in local.decommissioned_initiative_assignments : k => merge(v, { scope = local.mg_decommissioned }) }
  )

  # Assignments requiring managed identity (for remediation)
  assignments_requiring_identity = {
    for k, v in merge(local.flattened_policy_assignments, local.flattened_initiative_assignments) :
    k => v if v.identity_type != "None"
  }
}
