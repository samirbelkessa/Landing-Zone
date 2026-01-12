# =============================================================================
# DNS_LINKS.TF - Private DNS Zone VNet Links
# =============================================================================
# Orchestrator: 06-landing-zones
# Purpose: Link Spoke VNets to Private DNS Zones in Connectivity subscription
# =============================================================================

# =============================================================================
# PRIVATE DNS ZONE VNET LINKS
# =============================================================================
# Links each Spoke VNet to the Private DNS Zones hosted in the Connectivity
# subscription. This enables Private Endpoint DNS resolution for Spoke workloads.
#
# The links are created in the Connectivity subscription where the DNS zones
# are hosted, using the connectivity provider.
# =============================================================================

resource "azurerm_private_dns_zone_virtual_network_link" "spoke_links" {
  provider = azurerm.connectivity

  for_each = {
    for link_key, link in local.dns_zone_links : link_key => link
    if link.enabled
  }

  name                  = "link-${each.value.vnet_name}"
  resource_group_name   = local.connectivity_dns_resource_group
  private_dns_zone_name = each.value.dns_zone_name
  virtual_network_id    = module.lz_vending[each.value.landing_zone_key].virtual_network_resource_ids["primary"]
  registration_enabled  = false # Auto-registration disabled for spoke VNets

  tags = merge(
    var.default_tags,
    {
      LinkedVNet   = each.value.vnet_name
      LandingZone  = each.value.landing_zone_key
      DNSZone      = each.value.dns_zone_name
    }
  )

  depends_on = [
    module.lz_vending
  ]
}
