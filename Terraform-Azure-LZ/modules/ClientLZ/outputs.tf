output "additional_resource_group_ids" {
  description = "Map of additional resource group key -> ID."
  value       = { for k, v in azurerm_resource_group.additional : k => v.id }
}

output "additional_vnet_ids" {
  description = "Map of additional VNet key -> resource ID."
  value       = module.spoke.additional_vnet_ids
}

output "computed_names" {
  description = "All auto-generated resource names."
  value       = module.spoke.computed_names
}

output "dns_zone_link_ids" {
  description = "Map of DNS zone key -> VNet link resource ID."
  value       = module.spoke.dns_zone_link_ids
}

output "firewall_app_rule_collection_group_id" {
  description = "Firewall application rule collection group ID."
  value       = try(azurerm_firewall_policy_rule_collection_group.application[0].id, null)
}

output "firewall_network_rule_collection_group_id" {
  description = "Firewall network rule collection group ID."
  value       = try(azurerm_firewall_policy_rule_collection_group.network[0].id, null)
}

output "flow_log_id" {
  description = "Primary VNet flow log ID."
  value       = module.spoke.flow_log_id
}

output "managed_identity" {
  description = "User-Assigned Managed Identity details (null if disabled)."
  value = var.deploy_managed_identity ? {
    id           = azurerm_user_assigned_identity.this[0].id
    principal_id = azurerm_user_assigned_identity.this[0].principal_id
    client_id    = azurerm_user_assigned_identity.this[0].client_id
  } : null
}

output "nsg_ids" {
  description = "Map of NSG key -> NSG resource ID."
  value       = module.spoke.nsg_ids
}

output "peering_hub_to_spoke_id" {
  description = "Hub -> Spoke peering resource ID."
  value       = module.spoke.peering_hub_to_spoke_id
}

output "peering_spoke_to_hub_id" {
  description = "Spoke -> Hub peering resource ID."
  value       = module.spoke.peering_spoke_to_hub_id
}

output "resource_group_id" {
  description = "Spoke network Resource Group ID."
  value       = module.spoke.resource_group_id
}

output "resource_group_name" {
  description = "Spoke network Resource Group name."
  value       = module.spoke.resource_group_name
}

output "route_table_id" {
  description = "Route table resource ID."
  value       = module.spoke.route_table_id
}

output "subnet_address_prefixes" {
  description = "Map of subnet key -> address prefixes list."
  value       = module.spoke.subnet_address_prefixes
}

output "subnet_ids" {
  description = "Map of subnet key -> subnet resource ID."
  value       = module.spoke.subnet_ids
}

output "subnet_names" {
  description = "Map of subnet key -> subnet name."
  value       = module.spoke.subnet_names
}

output "uami_resource_group_id" {
  description = "UAMI Resource Group ID (null if UAMI disabled)."
  value       = try(azurerm_resource_group.uami[0].id, null)
}

output "vnet_address_space" {
  description = "Spoke VNet address space."
  value       = module.spoke.vnet_address_space
}

output "vnet_id" {
  description = "Spoke VNet resource ID."
  value       = module.spoke.vnet_id
}

output "vnet_name" {
  description = "Spoke VNet name."
  value       = module.spoke.vnet_name
}

