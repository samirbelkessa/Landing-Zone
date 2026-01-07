# =============================================================================
# LOCALS - VALEURS CALCULÉES
# =============================================================================

locals {
  # ---------------------------------------------------------------------------
  # TAGS COMMUNS
  # ---------------------------------------------------------------------------
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      Owner       = var.owner
      CostCenter  = var.cost_center
      ManagedBy   = "Terraform"
      Module      = "avm-ptn-alz-connectivity-hub-and-spoke-vnet"
      DeployedAt  = timestamp()
    },
    var.tags
  )

  # ---------------------------------------------------------------------------
  # RESOURCE GROUP IDs
  # ---------------------------------------------------------------------------
  rg_id_aue  = "/subscriptions/${var.connectivity_subscription_id}/resourceGroups/${var.resource_group_name_aue}"
  rg_id_ause = "/subscriptions/${var.connectivity_subscription_id}/resourceGroups/${var.resource_group_name_ause}"

  # ---------------------------------------------------------------------------
  # NAMING CONVENTIONS
  # ---------------------------------------------------------------------------
  naming = {
    # Australia East
    hub_vnet_aue           = "vnet-hub-aue-001"
    firewall_aue           = "afw-hub-aue-001"
    firewall_policy_aue    = "afwp-hub-aue-001"
    bastion_aue            = "bas-hub-aue-001"
    vpn_gateway_aue        = "vgw-hub-aue-001"
    er_gateway_aue         = "ergw-hub-aue-001"
    dns_resolver_aue       = "pdr-hub-aue-001"

    # Australia Southeast
    hub_vnet_ause          = "vnet-hub-ause-001"
    firewall_ause          = "afw-hub-ause-001"
    firewall_policy_ause   = "afwp-hub-ause-001"
    bastion_ause           = "bas-hub-ause-001"
    vpn_gateway_ause       = "vgw-hub-ause-001"
    er_gateway_ause        = "ergw-hub-ause-001"
    dns_resolver_ause      = "pdr-hub-ause-001"

    # ==========================================================================
    # APPLICATION GATEWAY - Australia East
    # ==========================================================================
    appgw_aue      = "agw-hub-aue-001"
    pip_appgw_aue  = "pip-agw-hub-aue-001"
    waf_policy_aue = "waf-hub-aue-001"
    id_appgw_aue   = "id-appgw-aue-001"
    rg_appgw_aue   = "rg-appgw-aue-001"

    # ==========================================================================
    # APPLICATION GATEWAY - Australia Southeast
    # ==========================================================================
    appgw_ause      = "agw-hub-ause-001"
    pip_appgw_ause  = "pip-agw-hub-ause-001"
    waf_policy_ause = "waf-hub-ause-001"
    id_appgw_ause   = "id-appgw-ause-001"
    rg_appgw_ause   = "rg-appgw-ause-001"
  }

  # ---------------------------------------------------------------------------
  # SUBNETS CUSTOM (hors subnets gérés automatiquement par le module)
  # ---------------------------------------------------------------------------
  # Le module AVM gère automatiquement :
  # - GatewaySubnet
  # - AzureFirewallSubnet
  # - AzureFirewallManagementSubnet (si management_ip_enabled = true)
  # - AzureBastionSubnet
  # - Subnet DNS Resolver

  custom_subnets_aue = merge(
    {
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
  )

  custom_subnets_ause = merge(
    {
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
  )

  # ---------------------------------------------------------------------------
  # VPN CONNECTIONS - Transformation pour le module
  # ---------------------------------------------------------------------------
# Itérer sur les clés uniquement (non sensibles)
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

  # ---------------------------------------------------------------------------
  # DNS FORWARDING RULES - Transformation pour le module
  # ---------------------------------------------------------------------------
  dns_forwarding_rules = {
    for k, v in var.dns_forward_zones : k => {
      domain_name              = v.domain_name
      destination_ip_addresses = v.destination_ip_addresses
      enabled                  = true
    }
  }

  # ---------------------------------------------------------------------------
  # PRIVATE DNS ZONES - MINIMAL CONFIGURATION
  # ---------------------------------------------------------------------------
  # Instead of creating 100+ zones, only create what you actually need
  # Uncomment zones in private_dns_zones_needed as required
  
  private_dns_zones_needed = [
    # -------------------------------------------------------------------------
    # STORAGE (almost always needed)
    # -------------------------------------------------------------------------
    "privatelink.blob.core.windows.net",           # Blob Storage
    "privatelink.file.core.windows.net",           # File Shares
    # "privatelink.queue.core.windows.net",        # Queue Storage
    # "privatelink.table.core.windows.net",        # Table Storage
    # "privatelink.dfs.core.windows.net",          # Data Lake Gen2

    # -------------------------------------------------------------------------
    # KEY VAULT (almost always needed)
    # -------------------------------------------------------------------------
    "privatelink.vaultcore.azure.net",

    # -------------------------------------------------------------------------
    # DATABASES (choose what you use)
    # -------------------------------------------------------------------------
    "privatelink.database.windows.net",            # Azure SQL
    # "privatelink.postgres.database.azure.com",   # PostgreSQL
    # "privatelink.mysql.database.azure.com",      # MySQL
    # "privatelink.mongo.cosmos.azure.com",        # Cosmos DB

    # -------------------------------------------------------------------------
    # MONITORING (recommended for AMPLS)
    # -------------------------------------------------------------------------
    "privatelink.monitor.azure.com",
    "privatelink.oms.opinsights.azure.com",
    "privatelink.ods.opinsights.azure.com",
    "privatelink.agentsvc.azure-automation.net",

    # -------------------------------------------------------------------------
    # CONTAINER REGISTRY (if using ACR)
    # -------------------------------------------------------------------------
    "privatelink.azurecr.io",

    # -------------------------------------------------------------------------
    # WEB APPS (if using App Service with Private Endpoints)
    # -------------------------------------------------------------------------
    # "privatelink.azurewebsites.net",

    # -------------------------------------------------------------------------
    # BACKUP (if using Recovery Services Vault with PE)
    # -------------------------------------------------------------------------
    # "privatelink.siterecovery.windowsazure.com",
    # "privatelink.australiaeast.backup.windowsazure.com",
  ]

  # ---------------------------------------------------------------------------
  # FULL LIST OF ALL PRIVATE LINK ZONES
  # Used to calculate what to EXCLUDE
  # ---------------------------------------------------------------------------
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
    "privatelink.dev.azuresynapse.net",
    "privatelink.azuresynapse.net",
    "privatelink.postgres.database.azure.com",
    "privatelink.mysql.database.azure.com",
    "privatelink.mariadb.database.azure.com",
    "privatelink.documents.azure.com",
    "privatelink.mongo.cosmos.azure.com",
    "privatelink.cassandra.cosmos.azure.com",
    "privatelink.gremlin.cosmos.azure.com",
    "privatelink.table.cosmos.azure.com",
    "privatelink.analytics.cosmos.azure.com",
    "privatelink.redis.cache.windows.net",
    # Key Vault
    "privatelink.vaultcore.azure.net",
    "privatelink.managedhsm.azure.net",
    # Containers
    "privatelink.azurecr.io",
    "privatelink.australiaeast.azmk8s.io",
    "privatelink.australiasoutheast.azmk8s.io",
    # Web
    "privatelink.azurewebsites.net",
    "scm.privatelink.azurewebsites.net",
    "privatelink.azurestaticapps.net",
    # Monitoring
    "privatelink.monitor.azure.com",
    "privatelink.oms.opinsights.azure.com",
    "privatelink.ods.opinsights.azure.com",
    "privatelink.agentsvc.azure-automation.net",
    "privatelink.azure-automation.net",
    # Healthcare
    "privatelink.workspace.azurehealthcareapis.com",
    "privatelink.fhir.azurehealthcareapis.com",
    "privatelink.dicom.azurehealthcareapis.com",
    # Messaging
    "privatelink.servicebus.windows.net",
    "privatelink.eventgrid.azure.net",
    "privatelink.azure-devices.net",
    "privatelink.azure-devices-provisioning.net",
    # AI
    "privatelink.cognitiveservices.azure.com",
    "privatelink.openai.azure.com",
    "privatelink.search.windows.net",
    # Data
    "privatelink.datafactory.azure.net",
    "privatelink.adf.azure.com",
    "privatelink.purview.azure.com",
    "privatelink.purviewstudio.azure.com",
    # Media
    "privatelink.media.azure.net",
    "privatelink.azureedge.net",
    # Security
    "privatelink.azconfig.io",
    "privatelink.attest.azure.net",
    "privatelink.token.botframework.com",
    "privatelink.directline.botframework.com",
    # Backup
    "privatelink.siterecovery.windowsazure.com",
    "privatelink.australiaeast.backup.windowsazure.com",
    "privatelink.australiasoutheast.backup.windowsazure.com",
    # API
    "privatelink.azure-api.net",
    "privatelink.developer.azure-api.net",
    # ML
    "privatelink.api.azureml.ms",
    "privatelink.notebooks.azure.net",
    "privatelink.inference.ml.azure.com",
    # SignalR
    "privatelink.signalr.azure.net",
    "privatelink.webpubsub.azure.com",
    # Power Platform
    "privatelink.tip1.powerquery.microsoft.com",
    "privatelink.analysis.windows.net",
    "privatelink.pbidedicated.windows.net",
    # Arc
    "privatelink.his.arc.azure.com",
    "privatelink.guestconfiguration.azure.com",
    "privatelink.kubernetesconfiguration.azure.com",
    # Others
    "privatelink.digitaltwins.azure.net",
    "privatelink.atlas.microsoft.com",
    "privatelink.grafana.azure.com",
  ]

  # ---------------------------------------------------------------------------
  # CALCULATED: Zones to EXCLUDE
  # Everything NOT in private_dns_zones_needed gets excluded
  # ---------------------------------------------------------------------------
  private_dns_zones_excluded = [
    for zone in local.all_private_link_zones : zone
    if !contains(local.private_dns_zones_needed, zone)
  ]

  # ===========================================================================
  # MANAGEMENT LAYER - Remote State References
  # ===========================================================================
  # Retrieved from Management orchestrator via terraform_remote_state
  
  log_analytics_workspace_id = try(
    data.terraform_remote_state.management.outputs.m01_log_analytics_id,
    null
  )
  
  log_analytics_workspace_name = try(
    data.terraform_remote_state.management.outputs.m01_log_analytics_name,
    null
  )
  
  management_resource_group_name = try(
    data.terraform_remote_state.management.outputs.resource_group_name,
    null
  )
}