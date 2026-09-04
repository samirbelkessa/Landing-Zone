resource "azurerm_resource_group" "this" {
  provider = azurerm.spoke

  tags     = local.tags
  name     = local.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "this" {
  provider = azurerm.spoke

  tags                = local.tags
  resource_group_name = azurerm_resource_group.this.name
  name                = local.vnet_name
  location            = var.location
  dns_servers         = local.dns_servers
  address_space       = var.address_space
}

resource "azurerm_subnet" "this" {
  provider = azurerm.spoke

  virtual_network_name                          = azurerm_virtual_network.this.name
  service_endpoints                             = length(each.value.service_endpoints) > 0 ? each.value.service_endpoints : null
  resource_group_name                           = azurerm_resource_group.this.name
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled
  private_endpoint_network_policies             = each.value.private_endpoint_network_policies
  name                                          = local.subnet_names[each.key]
  for_each                                      = var.subnets
  address_prefixes                              = each.value.address_prefixes

  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}

resource "azurerm_network_security_group" "this" {
  provider = azurerm.spoke

  tags                = local.tags
  resource_group_name = azurerm_resource_group.this.name
  name                = local.nsg_names[each.key]
  location            = var.location
  for_each            = toset(local.nsg_keys)
}

resource "azurerm_subnet_network_security_group_association" "this" {
  provider = azurerm.spoke

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
  for_each                  = toset(local.nsg_keys)
}

resource "azurerm_network_security_rule" "this" {
  provider = azurerm.spoke

  source_port_ranges           = each.value.source_port_ranges
  source_port_range            = each.value.source_port_ranges == null ? each.value.source_port_range : null
  source_address_prefixes      = each.value.source_address_prefixes
  source_address_prefix        = each.value.source_address_prefixes == null ? each.value.source_address_prefix : null
  resource_group_name          = azurerm_resource_group.this.name
  protocol                     = each.value.protocol
  priority                     = each.value.priority
  network_security_group_name  = azurerm_network_security_group.this[each.value.nsg_key].name
  name                         = each.value.rule_name
  for_each                     = local.all_nsg_rules
  direction                    = each.value.direction
  destination_port_ranges      = each.value.destination_port_ranges
  destination_port_range       = each.value.destination_port_ranges == null ? each.value.destination_port_range : null
  destination_address_prefixes = each.value.destination_address_prefixes
  destination_address_prefix   = each.value.destination_address_prefixes == null ? each.value.destination_address_prefix : null
  access                       = each.value.access
}

resource "azurerm_route_table" "this" {
  provider = azurerm.spoke

  tags                          = local.tags
  resource_group_name           = azurerm_resource_group.this.name
  name                          = local.route_table_name
  location                      = var.location
  bgp_route_propagation_enabled = !var.disable_bgp_route_propagation
}

resource "azurerm_route" "default_to_firewall" {
  provider = azurerm.spoke

  route_table_name       = azurerm_route_table.this.name
  resource_group_name    = azurerm_resource_group.this.name
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.firewall_private_ip
  name                   = coalesce(var.custom_default_route_name, "default-to-azfw")
  address_prefix         = "0.0.0.0/0"
  count                  = var.enable_hub_peering ? 1 : 0
}

resource "azurerm_route" "additional" {
  provider = azurerm.spoke

  route_table_name       = azurerm_route_table.this.name
  resource_group_name    = azurerm_resource_group.this.name
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_in_ip_address
  name                   = each.key
  for_each               = var.additional_routes
  address_prefix         = each.value.address_prefix
}

resource "azurerm_subnet_route_table_association" "this" {
  provider = azurerm.spoke

  subnet_id      = azurerm_subnet.this[each.key].id
  route_table_id = azurerm_route_table.this.id
  for_each       = local.udr_association_keys
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  provider = azurerm.spoke

  virtual_network_name         = azurerm_virtual_network.this.name
  use_remote_gateways          = var.use_remote_gateways
  resource_group_name          = azurerm_resource_group.this.name
  remote_virtual_network_id    = var.hub_vnet_id
  name                         = local.peering_name_spoke_to_hub
  allow_virtual_network_access = true
  allow_gateway_transit        = false
  allow_forwarded_traffic      = var.allow_forwarded_traffic
  count                        = var.enable_hub_peering ? 1 : 0

  depends_on = [
    azurerm_virtual_network_peering.hub_to_spoke,
  ]
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  provider = azurerm.hub

  virtual_network_name         = var.hub_vnet_name
  use_remote_gateways          = false
  resource_group_name          = var.hub_resource_group_name
  remote_virtual_network_id    = azurerm_virtual_network.this.id
  name                         = local.peering_name_hub_to_spoke
  allow_virtual_network_access = true
  allow_gateway_transit        = var.allow_gateway_transit
  allow_forwarded_traffic      = var.allow_forwarded_traffic
  count                        = var.enable_hub_peering ? 1 : 0
}

resource "azurerm_monitor_diagnostic_setting" "vnet" {
  provider = azurerm.spoke

  target_resource_id         = azurerm_virtual_network.this.id
  name                       = "vNetLogsToLogAnalytics"
  log_analytics_workspace_id = var.log_analytics_workspace_id
  count                      = var.enable_vnet_diagnostics ? 1 : 0

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "nsg" {
  provider = azurerm.spoke

  target_resource_id         = azurerm_network_security_group.this[each.key].id
  name                       = "NSGLogsToLogAnalytics"
  log_analytics_workspace_id = var.log_analytics_workspace_id
  for_each                   = var.enable_nsg_diagnostics ? toset(keys(var.subnets)) : toset([])

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  provider = azurerm.hub

  virtual_network_id    = azurerm_virtual_network.this.id
  tags                  = local.tags
  resource_group_name   = each.value.resource_group_name
  registration_enabled  = false
  private_dns_zone_name = each.value.zone_name
  name                  = "link-${local.vnet_name}-${each.key}"
  for_each              = var.enable_hub_peering ? var.private_dns_zone_links : {}
}

resource "azurerm_virtual_network" "additional" {
  provider = azurerm.spoke

  tags                = local.tags
  resource_group_name = azurerm_resource_group.this.name
  name                = "${local.prefix}vnetcspoke${each.key}01"
  location            = var.location
  for_each            = var.additional_vnets
  dns_servers         = var.enable_hub_peering && var.firewall_private_ip != "" ? [var.firewall_private_ip] : []
  address_space       = each.value.address_space
}

resource "azurerm_subnet" "additional" {
  provider = azurerm.spoke

  virtual_network_name              = azurerm_virtual_network.additional[each.value.vnet_key].name
  resource_group_name               = azurerm_resource_group.this.name
  private_endpoint_network_policies = each.value.pep
  name                              = each.value.name
  for_each = {
    for entry in flatten([
      for vnet_key, vnet in var.additional_vnets : [
        for subnet_key, subnet in vnet.subnets : {
          key      = "${vnet_key}-${subnet_key}"
          vnet_key = vnet_key
          name     = "${local.prefix}subc${vnet_key}${subnet_key}01"
          prefixes = subnet.address_prefixes
          pep      = subnet.private_endpoint_network_policies
        }
      ]
    ]) : entry.key => entry
  }
  address_prefixes = each.value.prefixes
}

resource "azurerm_virtual_network_peering" "additional_spoke_to_hub" {
  provider = azurerm.spoke

  virtual_network_name         = azurerm_virtual_network.additional[each.key].name
  use_remote_gateways          = each.value.use_remote_gateways
  resource_group_name          = azurerm_resource_group.this.name
  remote_virtual_network_id    = var.hub_vnet_id
  name                         = "${local.prefix}vnetcspoke${each.key}01-to-${var.hub_vnet_name}"
  for_each                     = var.enable_hub_peering ? var.additional_vnets : {}
  allow_virtual_network_access = true
  allow_gateway_transit        = false
  allow_forwarded_traffic      = true

  depends_on = [
    azurerm_virtual_network_peering.additional_hub_to_spoke,
  ]
}

resource "azurerm_virtual_network_peering" "additional_hub_to_spoke" {
  provider = azurerm.hub

  virtual_network_name         = var.hub_vnet_name
  use_remote_gateways          = false
  resource_group_name          = var.hub_resource_group_name
  remote_virtual_network_id    = azurerm_virtual_network.additional[each.key].id
  name                         = "${var.hub_vnet_name}-to-${local.prefix}vnetcspoke${each.key}01"
  for_each                     = var.enable_hub_peering ? var.additional_vnets : {}
  allow_virtual_network_access = true
  allow_gateway_transit        = each.value.allow_gateway_transit
  allow_forwarded_traffic      = each.value.hub_allow_forwarded_traffic
}

resource "azurerm_network_watcher_flow_log" "primary" {
  provider = azurerm.spoke

  target_resource_id   = azurerm_virtual_network.this.id
  tags                 = local.tags
  storage_account_id   = var.flow_logs_storage_account_id
  resource_group_name  = data.azurerm_network_watcher.this[0].resource_group_name
  network_watcher_name = data.azurerm_network_watcher.this[0].name
  name                 = local.flow_log_name_primary
  enabled              = true
  count                = local.deploy_flow_logs ? 1 : 0

  retention_policy {
    enabled = true
    days    = var.flow_logs_retention_days
  }

  dynamic "traffic_analytics" {
    for_each = var.enable_traffic_analytics ? [1] : []
    content {
      enabled               = true
      workspace_id          = var.log_analytics_workspace_guid
      workspace_region      = var.log_analytics_workspace_region
      workspace_resource_id = var.log_analytics_workspace_id
      interval_in_minutes   = 10
    }
  }
}

resource "azurerm_network_watcher_flow_log" "additional" {
  provider = azurerm.spoke

  target_resource_id   = azurerm_virtual_network.additional[each.key].id
  tags                 = local.tags
  storage_account_id   = var.flow_logs_storage_account_id
  resource_group_name  = data.azurerm_network_watcher.this[0].resource_group_name
  network_watcher_name = data.azurerm_network_watcher.this[0].name
  name                 = local.flow_log_names_additional[each.key]
  for_each             = local.deploy_flow_logs ? var.additional_vnets : {}
  enabled              = true

  retention_policy {
    enabled = true
    days    = var.flow_logs_retention_days
  }

  dynamic "traffic_analytics" {
    for_each = var.enable_traffic_analytics ? [1] : []
    content {
      enabled               = true
      workspace_id          = var.log_analytics_workspace_guid
      workspace_region      = var.log_analytics_workspace_region
      workspace_resource_id = var.log_analytics_workspace_id
      interval_in_minutes   = 10
    }
  }
}

data "azurerm_network_watcher" "this" {
  provider = azurerm.spoke

  resource_group_name = "NetworkWatcherRG"
  name                = "NetworkWatcher_${var.location}"
  count               = local.deploy_flow_logs ? 1 : 0

  depends_on = [
    azurerm_virtual_network.this,
  ]
}

