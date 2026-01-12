# =============================================================================
# MAIN.TF - CONNECTIVITY LAYER WITH AVM MODULE
# =============================================================================
# Ce fichier configure le module AVM pour déployer :
# - Hub VNet Australia East (Primary)
# - Hub VNet Australia Southeast (DR)
# - Azure Firewall Premium (les deux régions)
# - Azure Bastion Standard (les deux régions)
# - VPN Gateway (Australia East uniquement)
# - Private DNS Zones (toutes les zones Private Link)
# - Private DNS Resolver (les deux régions)
# =============================================================================

# =============================================================================
# RESOURCE GROUPS
# =============================================================================
# Les Resource Groups doivent être créés AVANT le module AVM
# car le module attend un parent_id existant
# -----------------------------------------------------------------------------
# NETWORK RGs (VNet + Firewall + Gateway + Bastion + Route Tables)
# -----------------------------------------------------------------------------
resource "azurerm_resource_group" "network_aue" {
  name     = var.resource_group_name_network_aue
  location = "australiaeast"
  tags = merge(local.common_tags, {
    Function = "Network-Hub"
    NetworkType = "Hub"
  })
}

resource "azurerm_resource_group" "network_ause" {
  name     = var.resource_group_name_network_ause
  location = "australiasoutheast"
  tags = merge(local.common_tags, {
    Function = "Network-Hub"
    NetworkType = "Hub"
  })
}

# -----------------------------------------------------------------------------
# DNS RGs (Private DNS Zones + DNS Resolver)
# -----------------------------------------------------------------------------
resource "azurerm_resource_group" "dns_aue" {
  name     = var.resource_group_name_dns_aue
  location = "australiaeast"
  tags = merge(local.common_tags, {
    Function = "DNS"
    NetworkType = "Hub"
  })
}

resource "azurerm_resource_group" "dns_ause" {
  name     = var.resource_group_name_dns_ause
  location = "australiasoutheast"
  tags = merge(local.common_tags, {
    Function = "DNS"
    NetworkType = "Hub"
  })
}

# =============================================================================
# MODULE AVM - HUB AND SPOKE CONNECTIVITY
# =============================================================================
module "alz_connectivity" {
  source  = "Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm"
  version = "0.16.2"

  # Désactiver la télémétrie Microsoft (optionnel)
  enable_telemetry = false

  # ===========================================================================
  # SHARED SETTINGS (paramètres partagés entre tous les hubs)
  # ===========================================================================
  hub_and_spoke_networks_settings = {
    # IMPORTANT: DDoS Protection désactivé car tu utilises Cloudflare
    enabled_resources = {
      ddos_protection_plan = var.enable_ddos_protection  # false par défaut
    }

    # Si DDoS était activé, tu configurerais ici :
    # ddos_protection_plan = {
    #   name     = "ddos-plan-australia"
    #   location = "australiaeast"
    # }
  }

  # ===========================================================================
  # HUB VIRTUAL NETWORKS
  # ===========================================================================
  hub_virtual_networks = {

    # =========================================================================
    # HUB AUSTRALIA EAST (PRIMARY)
    # =========================================================================
    australiaeast = {
      location          = "australiaeast"
      default_parent_id = azurerm_resource_group.network_aue.id

      # -----------------------------------------------------------------------
      # Contrôle des ressources à déployer
      # -----------------------------------------------------------------------
      enabled_resources = {
        firewall                              = true
        firewall_policy                       = true   # Policy de base (ou false si custom)
        bastion                               = true
        virtual_network_gateway_express_route = var.enable_expressroute_gateway
        virtual_network_gateway_vpn           = var.enable_vpn_gateway
        private_dns_zones                     = true
        private_dns_resolver                  = true
      }

      # -----------------------------------------------------------------------
      # HUB VIRTUAL NETWORK
      # -----------------------------------------------------------------------
      hub_virtual_network = {
        name          = local.naming.hub_vnet_aue
        address_space = var.hub_vnet_address_space_aue

        # Peering mesh avec l'autre hub (DR)
        mesh_peering_enabled = true

        # Adresses à router via ce hub
        #routing_address_space = var.routing_address_space

        # Subnets custom (hors subnets gérés automatiquement)
        subnets = local.all_custom_subnets_aue

        # Routes custom additionnelles pour les user subnets
        /*
        route_table_entries_user_subnets = [
          {
            name                = "to-internet-via-firewall-auel"
            address_prefix      = "0.0.0.0/0"
            next_hop_type       = "VirtualAppliance"
            next_hop_ip_address = "10.0.0.68"  # IP du Firewall (première IP disponible dans /26)
          }
        ]*/

        tags = local.common_tags
      }

      # -----------------------------------------------------------------------
      # AZURE FIREWALL
      # -----------------------------------------------------------------------
      firewall = {
        name                      = local.naming.firewall_aue
        sku_name                  = "AZFW_VNet"
        sku_tier                  = var.firewall_sku_tier
        Zones = null
        #zones                     = var.firewall_zones
        subnet_address_prefix     = var.hub_subnets_aue.firewall_subnet

        # Management IP pour Forced Tunneling
        management_ip_enabled            = true
        management_subnet_address_prefix = var.hub_subnets_aue.firewall_management_subnet

        # Option: Si tu veux utiliser une Firewall Policy externe (module custom C03)
        # firewall_policy_id = module.firewall_policy_aue.id

        tags = local.common_tags
      }

      # -----------------------------------------------------------------------
      # FIREWALL POLICY (configuration de base)
      # -----------------------------------------------------------------------
      # Note: Pour tes ~70 règles Fortinet, tu devras créer un module custom
      # et utiliser firewall_policy_id dans la section firewall ci-dessus
      firewall_policy = {
        name                              = local.naming.firewall_policy_aue
        sku                               = var.firewall_sku_tier
        threat_intelligence_mode          = var.firewall_threat_intel_mode
        auto_learn_private_ranges_enabled = true

        # DNS Proxy
        dns = {
          proxy_enabled = true
          # Les serveurs DNS seront configurés automatiquement avec le DNS Resolver
        }

        # Intrusion Detection (Premium uniquement)
        intrusion_detection = var.firewall_sku_tier == "Premium" ? {
          mode = "Alert"
        } : null
      }

      # -----------------------------------------------------------------------
      # AZURE BASTION
      # -----------------------------------------------------------------------
      bastion = {
        name                  = local.naming.bastion_aue
        subnet_address_prefix = var.hub_subnets_aue.bastion_subnet
        sku                   = var.bastion_sku
        scale_units           = var.bastion_scale_units
        zones                 = var.firewall_zones
        # Fonctionnalités Standard/Premium
        tunneling_enabled     = var.bastion_sku != "Basic"
        file_copy_enabled     = var.bastion_sku != "Basic"
        ip_connect_enabled    = var.bastion_sku != "Basic"
        copy_paste_enabled    = true
        shareable_link_enabled = false
        kerberos_enabled      = false
        
        bastion_public_ip = {
          allocation_method = "Static"
          sku               = "Standard"
          zones             = ["1", "2", "3"]  # Doit correspondre aux zones du Bastion
        }
        tags = local.common_tags
      }

      # -----------------------------------------------------------------------
      # VIRTUAL NETWORK GATEWAYS
      # -----------------------------------------------------------------------
      virtual_network_gateways = {
        subnet_address_prefix            = var.hub_subnets_aue.gateway_subnet
        route_table_creation_enabled     = true
        route_table_bgp_route_propagation_enabled = true

        # VPN Gateway
        vpn = var.enable_vpn_gateway ? {
          name                      = local.naming.vpn_gateway_aue
          sku                       = var.vpn_gateway_sku
          vpn_active_active_enabled = true
          vpn_bgp_enabled           = length([for k, v in var.vpn_connections : v if v.bgp_enabled]) > 0
          vpn_bgp_settings = {
            asn = 65515
          }
          local_network_gateways = local.vpn_local_network_gateways
          tags = local.common_tags
        } : null
      }
      # -----------------------------------------------------------------------
      # PRIVATE DNS ZONES
      # -----------------------------------------------------------------------
      private_dns_zones = {
        parent_id                      = azurerm_resource_group.dns_aue.id
        # Zone d'auto-registration pour les VMs du Hub
        auto_registration_zone_enabled = true
        auto_registration_zone_name    = "hub-aue.azure.internal"
        
        # Exclure certaines zones Private Link si non nécessaires
        private_link_excluded_zones = toset(local.private_dns_zones_excluded)

        tags = local.common_tags
      }

      # -----------------------------------------------------------------------
      # PRIVATE DNS RESOLVER
      # -----------------------------------------------------------------------
      private_dns_resolver = {
        name                             = local.naming.dns_resolver_aue
        resource_group_name              = azurerm_resource_group.dns_aue.name
        subnet_address_prefix            = var.hub_subnets_aue.dns_resolver_inbound_subnet
        default_inbound_endpoint_enabled = true

        # Outbound endpoints pour forwarding vers on-premises
        outbound_endpoints = length(var.dns_forward_zones) > 0 ? {
          onprem = {
            subnet_name = "snet-hub-dns-out"

            forwarding_ruleset = {
              corp = {
                name                                      = "frs-onprem-${local.naming.dns_resolver_aue}"
                link_with_outbound_endpoint_virtual_network = true
                rules                                     = local.dns_forwarding_rules
              }
            }
          }
        } : {}

        tags = local.common_tags
      }
    }

    # =========================================================================
    # HUB AUSTRALIA SOUTHEAST (DR)
    # =========================================================================
    australiasoutheast = {
      location          = "australiasoutheast"
      default_parent_id = azurerm_resource_group.network_ause.id

      # -----------------------------------------------------------------------
      # Contrôle des ressources à déployer (DR = moins de ressources)
      # -----------------------------------------------------------------------
      enabled_resources = {
        firewall                              = true
        firewall_policy                       = true
        bastion                               = true
        virtual_network_gateway_express_route = false  # Pas de gateway en DR (ou activer si besoin)
        virtual_network_gateway_vpn           = false  # Pas de VPN en DR (failover via peering)
        private_dns_zones                     = false  # Partagées depuis AUE via VNet links
        private_dns_resolver                  = true   # DNS Resolver local pour performance
      }

      # -----------------------------------------------------------------------
      # HUB VIRTUAL NETWORK
      # -----------------------------------------------------------------------
      hub_virtual_network = {
        name          = local.naming.hub_vnet_ause
        address_space = var.hub_vnet_address_space_ause

        # Peering mesh avec l'autre hub (Primary)
        mesh_peering_enabled = true

        # Adresses à router via ce hub
        #routing_address_space = var.routing_address_space

        # Subnets custom
        subnets = local.custom_subnets_ause

        # Routes custom
        /*
        route_table_entries_user_subnets = [
          {
            name                = "to-internet-via-firewall-ause"
            address_prefix      = "0.0.0.0/0"
            next_hop_type       = "VirtualAppliance"
            next_hop_ip_address = "10.1.0.68"  # IP du Firewall DR
          }
        ]*/

        tags = local.common_tags
      }

      # -----------------------------------------------------------------------
      # AZURE FIREWALL (DR)
      # -----------------------------------------------------------------------
      firewall = {
        name                      = local.naming.firewall_ause
        sku_name                  = "AZFW_VNet"
        sku_tier                  = var.firewall_sku_tier
        #zones                     = var.firewall_zones
        Zones = null
        subnet_address_prefix     = var.hub_subnets_ause.firewall_subnet

        management_ip_enabled            = true
        management_subnet_address_prefix = var.hub_subnets_ause.firewall_management_subnet

        tags = local.common_tags
      }

      # -----------------------------------------------------------------------
      # FIREWALL POLICY (DR)
      # -----------------------------------------------------------------------
      firewall_policy = {
        name                              = local.naming.firewall_policy_ause
        sku                               = var.firewall_sku_tier
        threat_intelligence_mode          = var.firewall_threat_intel_mode
        auto_learn_private_ranges_enabled = true

        # Hériter de la policy AUE (base_policy_id)
        # Si tu veux des règles identiques :
        # base_policy_id = module.alz_connectivity.firewall_policies["australiaeast"].id

        dns = {
          proxy_enabled = true
        }

        intrusion_detection = var.firewall_sku_tier == "Premium" ? {
          mode = "Alert"
        } : null
      }

      # -----------------------------------------------------------------------
      # AZURE BASTION (DR)
      # -----------------------------------------------------------------------
      bastion = {
        name                  = local.naming.bastion_ause
        subnet_address_prefix = var.hub_subnets_ause.bastion_subnet
        sku                   = var.bastion_sku
        scale_units           = var.bastion_scale_units
        #zones                 = var.firewall_zones
        zones = null
        tunneling_enabled  = var.bastion_sku != "Basic"
        file_copy_enabled  = var.bastion_sku != "Basic"
        ip_connect_enabled = var.bastion_sku != "Basic"
        copy_paste_enabled = true
        bastion_public_ip = {
          allocation_method = "Static"
          sku               = "Standard"
          zones             = null  # Pas de zones
        }
        tags = local.common_tags
      }

      # -----------------------------------------------------------------------
      # VIRTUAL NETWORK GATEWAYS (DR - Disabled)
      # -----------------------------------------------------------------------
      virtual_network_gateways = {
        subnet_address_prefix = var.hub_subnets_ause.gateway_subnet
        # Pas de gateway en DR par défaut - activer si nécessaire
      }

      # -----------------------------------------------------------------------
      # PRIVATE DNS RESOLVER (DR)
      # -----------------------------------------------------------------------
      private_dns_resolver = {
        name                             = local.naming.dns_resolver_ause
        resource_group_name              = azurerm_resource_group.dns_ause.name
        subnet_address_prefix            = var.hub_subnets_ause.dns_resolver_inbound_subnet
        default_inbound_endpoint_enabled = true

        tags = local.common_tags
      }
    }
  }
}

# =============================================================================
# APPLICATION GATEWAY (C13) - USING AVM MODULE
# =============================================================================
# Documentation: https://github.com/Azure/terraform-azurerm-avm-res-network-applicationgateway
# Requires: WAF_v2 SKU for production with Web Application Firewall
# =============================================================================

# -----------------------------------------------------------------------------
# APPLICATION GATEWAY SUBNET
# Created separately to ensure proper dependencies
# -----------------------------------------------------------------------------
resource "azurerm_subnet" "application_gateway" {
  count = var.enable_application_gateway ? 1 : 0

  name                 = "ApplicationGatewaySubnet"
  resource_group_name  = azurerm_resource_group.network_aue.name
  virtual_network_name = module.alz_connectivity.virtual_network_resource_names["australiaeast"]
  address_prefixes     = [var.application_gateway_subnet_address_prefix]

  depends_on = [module.alz_connectivity]
}

# -----------------------------------------------------------------------------
# USER ASSIGNED MANAGED IDENTITY (for Key Vault SSL certificates)
# -----------------------------------------------------------------------------
resource "azurerm_user_assigned_identity" "appgw" {
  count = var.enable_application_gateway ? 1 : 0

  name                = "id-${var.application_gateway_name}"
  location            = "australiaeast"
  resource_group_name = azurerm_resource_group.network_aue.name
  tags                = local.appgw_tags
}

# -----------------------------------------------------------------------------
# APPLICATION GATEWAY MODULE (AVM)
# -----------------------------------------------------------------------------
module "application_gateway" {
  count   = var.enable_application_gateway ? 1 : 0
  source  = "Azure/avm-res-network-applicationgateway/azurerm"
  version = "0.4.3"

  # ---------------------------------------------------------------------------
  # BASIC CONFIGURATION
  # ---------------------------------------------------------------------------
  name                = var.application_gateway_name
  resource_group_name = azurerm_resource_group.network_aue.name
  location            = "australiaeast"

  # SKU Configuration
  sku = var.application_gateway_sku

  # Autoscale Configuration (recommended for production)
  autoscale_configuration = var.application_gateway_autoscale

  # Availability Zones
  zones = var.application_gateway_zones

  # Enable HTTP/2
  http2_enable = true

  # ---------------------------------------------------------------------------
  # NETWORKING
  # ---------------------------------------------------------------------------
  gateway_ip_configuration = {
    name      = "appGatewayIpConfig"
    subnet_id = azurerm_subnet.application_gateway[0].id
  }

  # Public IP (auto-created by module)
  create_public_ip = true
  public_ip_name   = local.application_gateway_naming.public_ip

  # Private Frontend (optional)
  frontend_ip_configuration_private = var.application_gateway_enable_private_frontend ? {
    name                          = "private-frontend"
    private_ip_address            = var.application_gateway_private_ip_address
    private_ip_address_allocation = var.application_gateway_private_ip_address != null ? "Static" : "Dynamic"
  } : {}

  # ---------------------------------------------------------------------------
  # BACKEND CONFIGURATION
  # ---------------------------------------------------------------------------
  backend_address_pools = var.application_gateway_backend_pools

  backend_http_settings = var.application_gateway_backend_http_settings

  # ---------------------------------------------------------------------------
  # FRONTEND CONFIGURATION
  # ---------------------------------------------------------------------------
  frontend_ports = var.application_gateway_frontend_ports

  http_listeners = var.application_gateway_http_listeners

  # ---------------------------------------------------------------------------
  # ROUTING
  # ---------------------------------------------------------------------------
  request_routing_rules = var.application_gateway_request_routing_rules

  # ---------------------------------------------------------------------------
  # HEALTH PROBES
  # ---------------------------------------------------------------------------
  probe_configurations = length(var.application_gateway_health_probes) > 0 ? var.application_gateway_health_probes : null

  # ---------------------------------------------------------------------------
  # SSL/TLS CONFIGURATION
  # ---------------------------------------------------------------------------
  ssl_policy = local.appgw_ssl_policy

  ssl_certificates = length(var.application_gateway_ssl_certificates) > 0 ? var.application_gateway_ssl_certificates : null

  # ---------------------------------------------------------------------------
  # WAF CONFIGURATION (if WAF_v2 SKU)
  # ---------------------------------------------------------------------------
  waf_configuration = local.waf_configuration

  # Force association with WAF policy (if custom policy is provided)
  force_firewall_policy_association = true

  # ---------------------------------------------------------------------------
  # MANAGED IDENTITY (for Key Vault integration)
  # ---------------------------------------------------------------------------
  managed_identities = {
    system_assigned            = false
    user_assigned_resource_ids = [azurerm_user_assigned_identity.appgw[0].id]
  }

  # ---------------------------------------------------------------------------
  # DIAGNOSTICS
  # ---------------------------------------------------------------------------
  diagnostic_settings = local.has_log_analytics ? {
    to_law = {
      name                  = "diag-${var.application_gateway_name}"
      workspace_resource_id = local.effective_log_analytics_workspace_id
      log_groups            = ["allLogs"]
      metric_categories     = ["AllMetrics"]
    }
  } : {}

  # ---------------------------------------------------------------------------
  # RESOURCE LOCK (optional for production)
  # ---------------------------------------------------------------------------
  lock = var.environment == "prod" ? {
    kind = "CanNotDelete"
    name = "lock-${var.application_gateway_name}"
  } : null

  # ---------------------------------------------------------------------------
  # TAGS
  # ---------------------------------------------------------------------------
  tags = local.appgw_tags

  # Disable telemetry
  enable_telemetry = false

  depends_on = [
    module.alz_connectivity,
    azurerm_subnet.application_gateway,
    azurerm_user_assigned_identity.appgw
  ]
}