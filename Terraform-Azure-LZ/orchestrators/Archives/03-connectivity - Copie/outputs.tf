# =============================================================================
# OUTPUTS.TF - CONNECTIVITY LAYER (CORRIGÉ)
# =============================================================================
# Outputs compatibles avec le module AVM avm-ptn-alz-connectivity-hub-and-spoke-vnet
# Basé sur la documentation officielle du module
# =============================================================================

# -----------------------------------------------------------------------------
# RESOURCE GROUPS
# -----------------------------------------------------------------------------
output "resource_group_ids" {
  description = "IDs des Resource Groups créés"
  value = {
    australiaeast      = azurerm_resource_group.connectivity_aue.id
    australiasoutheast = azurerm_resource_group.connectivity_ause.id
  }
}

output "resource_group_names" {
  description = "Noms des Resource Groups créés"
  value = {
    australiaeast      = azurerm_resource_group.connectivity_aue.name
    australiasoutheast = azurerm_resource_group.connectivity_ause.name
  }
}

# -----------------------------------------------------------------------------
# VIRTUAL NETWORKS
# -----------------------------------------------------------------------------
output "virtual_network_resource_ids" {
  description = "Resource IDs des Hub VNets par région"
  value       = module.alz_connectivity.virtual_network_resource_ids
}

output "virtual_network_resource_names" {
  description = "Noms des Hub VNets par région"
  value       = module.alz_connectivity.virtual_network_resource_names
}

# -----------------------------------------------------------------------------
# AZURE FIREWALL
# -----------------------------------------------------------------------------
output "firewall_resource_ids" {
  description = "Resource IDs des Azure Firewalls par région"
  value       = module.alz_connectivity.firewall_resource_ids
}

output "firewall_resource_names" {
  description = "Noms des Azure Firewalls par région"
  value       = module.alz_connectivity.firewall_resource_names
}

output "firewall_private_ip_addresses" {
  description = "Adresses IP privées des Azure Firewalls par région"
  value       = module.alz_connectivity.firewall_private_ip_addresses
}

output "firewall_public_ip_addresses" {
  description = "Adresses IP publiques des Azure Firewalls par région"
  value       = module.alz_connectivity.firewall_public_ip_addresses
}

output "firewall_policy_ids" {
  description = "Resource IDs des Firewall Policies par région"
  value       = module.alz_connectivity.firewall_policies
}

# -----------------------------------------------------------------------------
# ROUTE TABLES
# -----------------------------------------------------------------------------
output "route_tables_firewall" {
  description = "Route Tables associées au Firewall par région"
  value       = module.alz_connectivity.route_tables_firewall
}

output "route_tables_user_subnets" {
  description = "Route Tables pour les subnets utilisateur par région"
  value       = module.alz_connectivity.route_tables_user_subnets
}

# -----------------------------------------------------------------------------
# DNS
# -----------------------------------------------------------------------------
output "dns_server_private_ip_addresses" {
  description = "Adresses IP privées des serveurs DNS par région"
  value       = module.alz_connectivity.dns_server_ip_addresses
}

# -----------------------------------------------------------------------------
# CONFIGURATION POUR LES SPOKES (Simplifié)
# -----------------------------------------------------------------------------
output "spoke_peering_config" {
  description = "Configuration nécessaire pour le peering des Spoke VNets"
  value = {
    australiaeast = {
      hub_vnet_id         = try(module.alz_connectivity.virtual_network_resource_ids["australiaeast"], null)
      hub_vnet_name       = try(module.alz_connectivity.virtual_network_resource_names["australiaeast"], null)
      resource_group_name = azurerm_resource_group.connectivity_aue.name
      firewall_private_ip = try(module.alz_connectivity.firewall_private_ip_addresses["australiaeast"], null)
      route_table_id      = try(module.alz_connectivity.route_tables_user_subnets["australiaeast"], null)
      dns_server_ip       = try(module.alz_connectivity.dns_server_private_ip_addresses["australiaeast"], null)
    }
    australiasoutheast = {
      hub_vnet_id         = try(module.alz_connectivity.virtual_network_resource_ids["australiasoutheast"], null)
      hub_vnet_name       = try(module.alz_connectivity.virtual_network_resource_names["australiasoutheast"], null)
      resource_group_name = azurerm_resource_group.connectivity_ause.name
      firewall_private_ip = try(module.alz_connectivity.firewall_private_ip_addresses["australiasoutheast"], null)
      route_table_id      = try(module.alz_connectivity.route_tables_user_subnets["australiasoutheast"], null)
      dns_server_ip       = try(module.alz_connectivity.dns_server_private_ip_addresses["australiasoutheast"], null)
    }
  }
}

# =============================================================================
# APPLICATION GATEWAY OUTPUTS
# =============================================================================

# =============================================================================
# APPLICATION GATEWAY OUTPUTS
# =============================================================================

output "application_gateway_id" {
  description = "Resource ID of the Application Gateway"
  value       = var.enable_application_gateway ? module.application_gateway[0].application_gateway_id : null
}

output "application_gateway_name" {
  description = "Name of the Application Gateway"
  value       = var.enable_application_gateway ? module.application_gateway[0].application_gateway_name : null
}

output "application_gateway_public_ip_address" {
  description = "Public IP address of the Application Gateway"
  value       = var.enable_application_gateway ? module.application_gateway[0].new_public_ip_address : null
}

output "application_gateway_public_ip_id" {
  description = "Resource ID of the Application Gateway public IP"
  value       = var.enable_application_gateway ? module.application_gateway[0].public_ip_id : null
}

output "application_gateway_backend_address_pools" {
  description = "Backend address pools configuration"
  value       = var.enable_application_gateway ? module.application_gateway[0].backend_address_pools : null
}

output "application_gateway_backend_http_settings" {
  description = "Backend HTTP settings configuration"
  value       = var.enable_application_gateway ? module.application_gateway[0].backend_http_settings : null
}

output "application_gateway_http_listeners" {
  description = "HTTP listeners configuration"
  value       = var.enable_application_gateway ? module.application_gateway[0].http_listeners : null
}

output "application_gateway_frontend_ports" {
  description = "Frontend ports configuration"
  value       = var.enable_application_gateway ? module.application_gateway[0].frontend_port : null
}

output "application_gateway_request_routing_rules" {
  description = "Request routing rules configuration"
  value       = var.enable_application_gateway ? module.application_gateway[0].request_routing_rules : null
}

output "application_gateway_waf_configuration" {
  description = "WAF configuration (if enabled)"
  value       = var.enable_application_gateway ? module.application_gateway[0].waf_configuration : null
}

output "application_gateway_subnet_id" {
  description = "Resource ID of the Application Gateway subnet"
  value       = var.enable_application_gateway ? "${module.alz_connectivity.virtual_network_resource_ids["australiaeast"]}/subnets/ApplicationGatewaySubnet" : null
}

output "application_gateway_managed_identity_id" {
  description = "Resource ID of the Application Gateway managed identity"
  value       = var.enable_application_gateway ? azurerm_user_assigned_identity.appgw[0].id : null
}

output "application_gateway_managed_identity_principal_id" {
  description = "Principal ID of the Application Gateway managed identity (for Key Vault access)"
  value       = var.enable_application_gateway ? azurerm_user_assigned_identity.appgw[0].principal_id : null
}

# Output for spoke orchestrators
output "application_gateway_config" {
  description = "Complete Application Gateway configuration for downstream consumers"
  value = var.enable_application_gateway ? {
    id                            = module.application_gateway[0].application_gateway_id
    name                          = module.application_gateway[0].application_gateway_name
    resource_group_name           = azurerm_resource_group.connectivity_aue.name
    public_ip_address             = module.application_gateway[0].new_public_ip_address
    public_ip_id                  = module.application_gateway[0].public_ip_id
    subnet_id                     = "${module.alz_connectivity.virtual_network_resource_ids["australiaeast"]}/subnets/ApplicationGatewaySubnet"
    managed_identity_id           = azurerm_user_assigned_identity.appgw[0].id
    managed_identity_principal_id = azurerm_user_assigned_identity.appgw[0].principal_id
    waf_enabled                   = var.enable_waf
  } : null
}

# -----------------------------------------------------------------------------
# DEBUG - Module complet (décommenter si besoin)
# -----------------------------------------------------------------------------
# output "alz_connectivity_all_outputs" {
#   description = "Tous les outputs du module AVM (debug)"
#   value       = module.alz_connectivity
#   sensitive   = true
# }
