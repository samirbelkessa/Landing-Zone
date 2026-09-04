output "additional_flow_log_ids" {
  description = "Map of additional VNet key to flow log ID."
  value       = { for k, v in azurerm_network_watcher_flow_log.additional : k => v.id }
}

output "additional_vnet_ids" {
  description = "IDs of additional VNets created in the spoke."
  value       = { for k, v in azurerm_virtual_network.additional : k => v.id }
}

output "computed_names" {
  description = "All auto-generated resource names (for validation and debugging)."
  value = {
    resource_group = local.resource_group_name
    vnet           = local.vnet_name
    route_table    = local.route_table_name
    subnets        = local.subnet_names
    nsgs           = local.nsg_names
    peering_s2h    = local.peering_name_spoke_to_hub
    peering_h2s    = local.peering_name_hub_to_spoke
  }
}

output "dns_zone_link_ids" {
  description = "Map of DNS zone key → VNet link resource ID."
  value       = { for k, v in azurerm_private_dns_zone_virtual_network_link.this : k => v.id }
}

output "flow_log_id" {
  description = "Primary VNet flow log ID (null if disabled)."
  value       = try(azurerm_network_watcher_flow_log.primary[0].id, null)
}

output "lock_id" {
  description = "VNet delete lock ID (null if disabled)."
  value       = try(azurerm_management_lock.vnet[0].id, null)
}

output "nsg_diagnostic_setting_ids" {
  description = "Map of NSG key → diagnostic setting ID."
  value       = { for k, v in azurerm_monitor_diagnostic_setting.nsg : k => v.id }
}

output "nsg_ids" {
  description = "Map of NSG key → NSG resource ID."
  value       = { for k, v in azurerm_network_security_group.this : k => v.id }
}

output "nsg_names" {
  description = "Map of NSG key → NSG name."
  value       = { for k, v in azurerm_network_security_group.this : k => v.name }
}

output "peering_hub_to_spoke_id" {
  description = "Hub → Spoke peering resource ID."
  value       = try(azurerm_virtual_network_peering.hub_to_spoke[0].id, null)
}

output "peering_spoke_to_hub_id" {
  description = "Spoke → Hub peering resource ID."
  value       = try(azurerm_virtual_network_peering.spoke_to_hub[0].id, null)
}

output "resource_group_id" {
  description = "Spoke network Resource Group ID."
  value       = azurerm_resource_group.this.id
}

output "resource_group_name" {
  description = "Spoke network Resource Group name."
  value       = azurerm_resource_group.this.name
}

output "route_table_id" {
  description = "Route table resource ID."
  value       = azurerm_route_table.this.id
}

output "route_table_name" {
  description = "Route table name."
  value       = azurerm_route_table.this.name
}

output "subnet_address_prefixes" {
  description = "Map of subnet key → address prefixes."
  value       = { for k, v in azurerm_subnet.this : k => v.address_prefixes }
}

output "subnet_ids" {
  description = "Map of subnet key → subnet resource ID."
  value       = { for k, v in azurerm_subnet.this : k => v.id }
}

output "subnet_names" {
  description = "Map of subnet key → subnet name."
  value       = { for k, v in azurerm_subnet.this : k => v.name }
}

output "vnet_address_space" {
  description = "Spoke VNet address space."
  value       = azurerm_virtual_network.this.address_space
}

output "vnet_diagnostic_setting_id" {
  description = "VNet diagnostic setting ID (null if disabled)."
  value       = try(azurerm_monitor_diagnostic_setting.vnet[0].id, null)
}

output "vnet_id" {
  description = "Spoke VNet resource ID."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Spoke VNet name."
  value       = azurerm_virtual_network.this.name
}

