# =============================================================================
# LOCALS.TF - CALCULATED VALUES FROM REMOTE STATES
# =============================================================================
# Orchestrator: 04-connectivity
#
# This file derives values from remote states to avoid hardcoding
# =============================================================================

locals {
  # ===========================================================================
  # REMOTE STATE REFERENCES
  # ===========================================================================
  foundation = data.terraform_remote_state.foundation.outputs
  governance = data.terraform_remote_state.governance.outputs
  management = data.terraform_remote_state.management.outputs

  # ===========================================================================
  # LOCATIONS FROM FOUNDATION
  # ===========================================================================
  primary_location   = local.foundation.primary_location    # "australiaeast"
  secondary_location = local.foundation.secondary_location  # "australiasoutheast"
  allowed_regions    = local.foundation.allowed_regions

  # Location abbreviations for naming
  location_abbrev = {
    "australiaeast"      = "aue"
    "australiasoutheast" = "ause"
    "eastus"             = "eus"
    "westus"             = "wus"
    "westeurope"         = "weu"
    "northeurope"        = "neu"
  }

  primary_region   = local.location_abbrev[local.primary_location]
  secondary_region = local.location_abbrev[local.secondary_location]

  # ===========================================================================
  # IDENTITY FROM FOUNDATION
  # ===========================================================================
  tenant_id = local.foundation.tenant_id
  root_id   = local.foundation.root_id

  # ===========================================================================
  # MANAGEMENT LAYER REFERENCES
  # ===========================================================================
  log_analytics_id           = local.management.m01_log_analytics_id
  log_analytics_workspace_id = local.management.m01_log_analytics_workspace_id
  log_analytics_name         = local.management.m01_log_analytics_name
  management_rg_name         = local.management.resource_group_name
  effective_log_analytics_workspace_id = local.log_analytics_id
  # Action Groups for alerts
  action_group_ids = try(local.management.m03_action_group_ids, {})
  critical_action_group_id = try(local.management.m03_critical_action_group_id, null)
  warning_action_group_id  = try(local.management.m03_warning_action_group_id, null)
  
  # Diagnostics storage
  diagnostics_storage_id = try(local.management.m08_diagnostics_storage_id, null)

  # ===========================================================================
  # VALIDATION FLAGS
  # ===========================================================================
  has_foundation_state = try(data.terraform_remote_state.foundation.outputs, null) != null
  has_governance_state = try(data.terraform_remote_state.governance.outputs, null) != null
  has_management_state = try(data.terraform_remote_state.management.outputs, null) != null
  has_log_analytics    = local.log_analytics_id != null && local.log_analytics_id != ""

  # ===========================================================================
  # TAGS - Merge foundation common_tags with connectivity-specific
  # ===========================================================================
  common_tags = merge(
    try(local.foundation.common_tags, {}),
    {
      Layer       = "Connectivity"
      Environment = var.environment
      Project     = var.project_name
      Owner       = var.owner
      CostCenter  = var.cost_center
      ManagedBy   = "Terraform"
      Module      = "avm-ptn-alz-connectivity-hub-and-spoke-vnet"
    },
    var.tags
  )

  # ===========================================================================
  # RESOURCE GROUP NAMES
  # ===========================================================================
  rg_network_aue  = var.resource_group_name_network_aue
  rg_network_ause = var.resource_group_name_network_ause
  rg_dns_aue      = var.resource_group_name_dns_aue
  rg_dns_ause     = var.resource_group_name_dns_ause

  # Resource Group IDs (for references)
  rg_id_network_aue  = "/subscriptions/${var.connectivity_subscription_id}/resourceGroups/${local.rg_network_aue}"
  rg_id_network_ause = "/subscriptions/${var.connectivity_subscription_id}/resourceGroups/${local.rg_network_ause}"
  rg_id_dns_aue      = "/subscriptions/${var.connectivity_subscription_id}/resourceGroups/${local.rg_dns_aue}"
  rg_id_dns_ause     = "/subscriptions/${var.connectivity_subscription_id}/resourceGroups/${local.rg_dns_ause}"

  # ===========================================================================
  # NAMING CONVENTIONS
  # ===========================================================================
  naming = {
    # Australia East (Primary)
    hub_vnet_aue        = "vnet-hub-${local.primary_region}-001"
    firewall_aue        = "afw-hub-${local.primary_region}-001"
    firewall_policy_aue = "afwp-hub-${local.primary_region}-001"
    bastion_aue         = "bas-hub-${local.primary_region}-001"
    vpn_gateway_aue     = "vgw-hub-${local.primary_region}-001"
    er_gateway_aue      = "ergw-hub-${local.primary_region}-001"
    dns_resolver_aue    = "pdr-hub-${local.primary_region}-001"
    route_table_aue     = "rt-hub-${local.primary_region}-001"

    # Australia Southeast (DR)
    hub_vnet_ause        = "vnet-hub-${local.secondary_region}-001"
    firewall_ause        = "afw-hub-${local.secondary_region}-001"
    firewall_policy_ause = "afwp-hub-${local.secondary_region}-001"
    bastion_ause         = "bas-hub-${local.secondary_region}-001"
    vpn_gateway_ause     = "vgw-hub-${local.secondary_region}-001"
    er_gateway_ause      = "ergw-hub-${local.secondary_region}-001"
    dns_resolver_ause    = "pdr-hub-${local.secondary_region}-001"
    route_table_ause     = "rt-hub-${local.secondary_region}-001"

    # Application Gateway
    appgw_aue      = "agw-hub-${local.primary_region}-001"
    pip_appgw_aue  = "pip-agw-hub-${local.primary_region}-001"
    waf_policy_aue = "waf-hub-${local.primary_region}-001"
    id_appgw_aue   = "id-appgw-${local.primary_region}-001"
  }

  # ===========================================================================
  # CUSTOM SUBNETS (beyond AVM managed subnets)
  # ===========================================================================
  custom_subnets_aue = {
    snet-hub-mgmt = {
      name             = "snet-hub-mgmt"
      address_prefixes = [var.hub_subnets_aue.management_subnet]
    }
    snet-hub-shared = {
      name             = "snet-hub-shared"
      address_prefixes = [var.hub_subnets_aue.shared_services_subnet]
    }
    snet-hub-pe = {
      name                                          = "snet-hub-pe"
      address_prefixes                              = [var.hub_subnets_aue.private_endpoints_subnet]
      private_endpoint_network_policies_enabled     = false
      private_link_service_network_policies_enabled = false
    }
  }

  custom_subnets_ause = {
    snet-hub-mgmt = {
      name             = "snet-hub-mgmt"
      address_prefixes = [var.hub_subnets_ause.management_subnet]
    }
    snet-hub-shared = {
      name             = "snet-hub-shared"
      address_prefixes = [var.hub_subnets_ause.shared_services_subnet]
    }
    snet-hub-pe = {
      name                                          = "snet-hub-pe"
      address_prefixes                              = [var.hub_subnets_ause.private_endpoints_subnet]
      private_endpoint_network_policies_enabled     = false
      private_link_service_network_policies_enabled = false
    }
  }

  # Merge with Application Gateway subnet if enabled
  all_custom_subnets_aue = local.custom_subnets_aue

  # ===========================================================================
  # VPN CONNECTIONS - Transform for module
  # ===========================================================================
  vpn_local_network_gateways = {
    for k in keys(var.vpn_connections) : k => {
      name            = "lgw-${k}"
      gateway_address = var.vpn_connections[k].gateway_address
      address_space   = var.vpn_connections[k].address_space
      bgp_settings = var.vpn_connections[k].bgp_enabled ? {
        asn                 = var.vpn_connections[k].bgp_asn
        bgp_peering_address = var.vpn_connections[k].bgp_peering_address
        peer_weight         = 0
      } : null
      connection = {
        name       = "cn-${k}"
        type       = "IPsec"
        enable_bgp = var.vpn_connections[k].bgp_enabled
        shared_key = var.vpn_connections[k].shared_key
        ipsec_policy = var.vpn_connections[k].ipsec_policy != null ? {
          dh_group         = var.vpn_connections[k].ipsec_policy.dh_group
          ike_encryption   = var.vpn_connections[k].ipsec_policy.ike_encryption
          ike_integrity    = var.vpn_connections[k].ipsec_policy.ike_integrity
          ipsec_encryption = var.vpn_connections[k].ipsec_policy.ipsec_encryption
          ipsec_integrity  = var.vpn_connections[k].ipsec_policy.ipsec_integrity
          pfs_group        = var.vpn_connections[k].ipsec_policy.pfs_group
          sa_datasize      = 102400000
          sa_lifetime      = 27000
        } : null
      }
    }
  }

  # ===========================================================================
  # DNS FORWARDING RULES
  # ===========================================================================
  dns_forwarding_rules = {
    for k, v in var.dns_forward_zones : k => {
      domain_name              = v.domain_name
      destination_ip_addresses = v.destination_ip_addresses
      enabled                  = true
    }
  }
/*
  # ===========================================================================
  # PRIVATE DNS ZONES - Minimal Configuration
  # ===========================================================================
  private_dns_zones_needed = [
    # Storage (almost always needed)
    "privatelink.blob.core.windows.net",
    "privatelink.file.core.windows.net",
    # Key Vault (almost always needed)
    "privatelink.vaultcore.azure.net",
    # SQL Database (if used)
    "privatelink.database.windows.net",
    # Add more as needed...
  ]

  all_private_link_zones = [
    # Storage
    "privatelink.blob.core.windows.net",
    "privatelink.file.core.windows.net",
    "privatelink.queue.core.windows.net",
    "privatelink.table.core.windows.net",
    "privatelink.web.core.windows.net",
    "privatelink.dfs.core.windows.net",
    # Databases
    "privatelink.database.windows.net",
    "privatelink.sql.azuresynapse.net",
    "privatelink.postgres.database.azure.com",
    "privatelink.mysql.database.azure.com",
    "privatelink.documents.azure.com",
    "privatelink.mongo.cosmos.azure.com",
    "privatelink.redis.cache.windows.net",
    # Key Vault
    "privatelink.vaultcore.azure.net",
    "privatelink.managedhsm.azure.net",
    # Containers
    "privatelink.azurecr.io",
    "privatelink.${local.primary_location}.azmk8s.io",
    "privatelink.${local.secondary_location}.azmk8s.io",
    # Web
    "privatelink.azurewebsites.net",
    "scm.privatelink.azurewebsites.net",
    # Monitoring
    "privatelink.monitor.azure.com",
    "privatelink.oms.opinsights.azure.com",
    "privatelink.ods.opinsights.azure.com",
    "privatelink.agentsvc.azure-automation.net",
    "privatelink.azure-automation.net",
    # Messaging
    "privatelink.servicebus.windows.net",
    "privatelink.eventgrid.azure.net",
    # AI
    "privatelink.cognitiveservices.azure.com",
    "privatelink.openai.azure.com",
    "privatelink.search.windows.net",
    # Backup
    "privatelink.siterecovery.windowsazure.com",
    "privatelink.${local.primary_location}.backup.windowsazure.com",
    "privatelink.${local.secondary_location}.backup.windowsazure.com",
  ]

  # Zones to exclude = all zones NOT in needed list
  private_dns_zones_excluded = [
    for zone in local.all_private_link_zones : zone
    if !contains(local.private_dns_zones_needed, zone)
  ]
*/

private_dns_zones_needed = [
    # Storage - Essentiels
    "azure_storage_blob",
    "azure_storage_file",
    
    # Key Vault - Essentiel
    "azure_key_vault",
    
    # SQL Database - Si utilisé
    "azure_sql",
    
    # Ajouter d'autres selon tes besoins...
    # "azure_container_registry",
    # "azure_kubernetes_service",
  ]

  # Liste COMPLÈTE des clés du module AVM (version 0.16.x)
  all_avm_dns_zone_keys = [
    # AI/ML
    "azure_ai_search",
    "azure_bot_service_bot",
    "azure_bot_service_token",
    "azure_cognitive_services",
    "azure_health_bot",
    "azure_machine_learning_api",
    "azure_machine_learning_cert",
    "azure_machine_learning_notebooks",
    "azure_ml",
    "azure_open_ai",
    
    # Analytics
    "azure_analysis_services",
    "azure_databricks_browser_auth",
    "azure_databricks_ui_api",
    "azure_data_explorer",
    "azure_data_factory",
    "azure_data_factory_portal",
    "azure_hdinsight",
    "azure_power_bi",
    "azure_synapse_dev",
    "azure_synapse_sql",
    "azure_synapse_sql_od",
    "azure_synapse_studio",
    
    # App Services
    "azure_app_configuration",
    "azure_app_service",
    "azure_app_service_scm",
    "azure_static_web_apps",
    
    # Automation
    "azure_automation_dsc_hybrid",
    "azure_automation_webhook",
    
    # Compute
    "azure_batch_account",
    "azure_disk_access",
    
    # Containers
    "azure_container_registry",
    "azure_kubernetes_service",
    
    # Databases
    "azure_cosmos_cassandra",
    "azure_cosmos_gremlin",
    "azure_cosmos_mongo",
    "azure_cosmos_sql",
    "azure_cosmos_table",
    "azure_mariadb",
    "azure_mysql",
    "azure_mysql_flexible",
    "azure_postgresql",
    "azure_postgresql_flexible",
    "azure_redis_cache",
    "azure_redis_enterprise",
    "azure_sql",
    
    # DevOps/GitHub
    "azure_dev_center",
    "github_arc",
    
    # Event/Messaging
    "azure_digital_twins",
    "azure_event_grid_domain",
    "azure_event_grid_topic",
    "azure_event_hub",
    "azure_iot_central",
    "azure_iot_dps",
    "azure_iot_hub",
    "azure_relay",
    "azure_service_bus",
    "azure_web_pubsub",
    
    # Integration
    "azure_api_management",
    
    # Key Vault
    "azure_key_vault",
    "azure_managed_hsm",
    
    # Media
    "azure_media_services_key",
    "azure_media_services_live",
    "azure_media_services_streaming",
    
    # Migration
    "azure_migrate_assessment",
    "azure_migrate_project",
    
    # Monitoring
    "azure_grafana",
    "azure_monitor",
    "azure_monitor_ods",
    "azure_monitor_oms",
    "azure_monitor_agentsvc",
    
    # Networking
    "azure_private_link_global",
    
    # Recovery/Backup
    "azure_backup",
    "azure_site_recovery",
    
    # Security
    "azure_attestation",
    "azure_key_vault_managed_hsm",
    
    # SignalR
    "azure_signalr",
    
    # Storage
    "azure_storage_blob",
    "azure_storage_dfs",
    "azure_storage_file",
    "azure_storage_queue",
    "azure_storage_static_web",
    "azure_storage_table",
    "azure_storage_web",
    
    # Other
    "azure_purview_account",
    "azure_purview_studio",
  ]

  # Calculer les zones à EXCLURE (toutes sauf celles à garder)
  private_dns_zones_excluded = [
    for key in local.all_avm_dns_zone_keys : key
    if !contains(local.private_dns_zones_needed, key)
  ]

  # ===========================================================================
  # APPLICATION GATEWAY
  # ===========================================================================
  application_gateway_naming = {
    name        = var.application_gateway_name
    public_ip   = "pip-${var.application_gateway_name}"
    subnet_name = "ApplicationGatewaySubnet"
  }

  appgw_diagnostic_workspace_id = local.log_analytics_id

  appgw_tags = merge(
    local.common_tags,
    local.has_management_state ? {
      ManagementRG = local.management_rg_name
    } : {},
    {
      Component = "Application Gateway"
      Module    = "avm-res-network-applicationgateway"
    }
  )

  # WAF Configuration
  waf_configuration = var.enable_waf && var.application_gateway_sku.tier == "WAF_v2" ? {
    enabled                  = true
    firewall_mode            = var.waf_mode
    rule_set_type            = "OWASP"
    rule_set_version         = var.waf_rule_set_version
    file_upload_limit_mb     = 100
    max_request_body_size_kb = 128
    request_body_check       = true
  } : null

  # SSL Policy
  appgw_ssl_policy = {
    policy_type          = var.application_gateway_ssl_policy.policy_type
    policy_name          = var.application_gateway_ssl_policy.policy_type == "Predefined" ? "AppGwSslPolicy20220101S" : null
    min_protocol_version = var.application_gateway_ssl_policy.min_protocol_version
    cipher_suites        = var.application_gateway_ssl_policy.policy_type != "Predefined" ? var.application_gateway_ssl_policy.cipher_suites : null
    disabled_protocols   = null
  }
}
