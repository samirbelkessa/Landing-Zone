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
  # PRIVATE DNS ZONES - Liste complète pour Private Link
  # ---------------------------------------------------------------------------
  # Le module crée automatiquement toutes les zones Private Link nécessaires
  # Tu peux exclure certaines zones si non nécessaires
  private_dns_zones_excluded = [
    # Ajouter ici les zones à exclure si nécessaire
    # "privatelink.postgres.database.azure.com",
  ]
}
