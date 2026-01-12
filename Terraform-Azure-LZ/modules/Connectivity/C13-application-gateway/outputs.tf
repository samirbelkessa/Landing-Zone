# -----------------------------------------------------------------------------
# C13 - APPLICATION GATEWAY MODULE
# Outputs - All useful attributes exposed
# -----------------------------------------------------------------------------

# =============================================================================
# APPLICATION GATEWAY OUTPUTS
# =============================================================================

output "id" {
  description = "Resource ID of the Application Gateway."
  value       = azurerm_application_gateway.this.id
}

output "name" {
  description = "Name of the Application Gateway."
  value       = azurerm_application_gateway.this.name
}

output "resource_group_name" {
  description = "Name of the Resource Group containing the Application Gateway."
  value       = azurerm_application_gateway.this.resource_group_name
}

output "location" {
  description = "Azure region where the Application Gateway is deployed."
  value       = azurerm_application_gateway.this.location
}

# =============================================================================
# PUBLIC IP OUTPUTS
# =============================================================================

output "public_ip_id" {
  description = "Resource ID of the Public IP address."
  value       = var.create_public_ip ? azurerm_public_ip.this[0].id : var.existing_public_ip_id
}

output "public_ip_address" {
  description = "Public IP address assigned to the Application Gateway."
  value       = var.create_public_ip ? azurerm_public_ip.this[0].ip_address : null
}

output "public_ip_name" {
  description = "Name of the Public IP resource."
  value       = var.create_public_ip ? azurerm_public_ip.this[0].name : null
}

output "public_ip_fqdn" {
  description = "Fully Qualified Domain Name of the Public IP (if DNS label configured)."
  value       = var.create_public_ip ? azurerm_public_ip.this[0].fqdn : null
}

# =============================================================================
# WAF POLICY OUTPUTS
# =============================================================================

output "waf_policy_id" {
  description = "Resource ID of the WAF Policy (if created by this module)."
  value       = local.is_waf_sku && var.waf_enabled && var.firewall_policy_id == null ? azurerm_web_application_firewall_policy.this[0].id : var.firewall_policy_id
}

output "waf_policy_name" {
  description = "Name of the WAF Policy (if created by this module)."
  value       = local.is_waf_sku && var.waf_enabled && var.firewall_policy_id == null ? azurerm_web_application_firewall_policy.this[0].name : null
}

# =============================================================================
# FRONTEND CONFIGURATION OUTPUTS
# =============================================================================

output "frontend_ip_configuration_id" {
  description = "Resource ID of the frontend IP configuration."
  value       = [for config in azurerm_application_gateway.this.frontend_ip_configuration : config.id if config.name == local.frontend_ip_configuration_name][0]
}

output "frontend_ip_configuration_name" {
  description = "Name of the frontend IP configuration."
  value       = local.frontend_ip_configuration_name
}

output "frontend_port_ids" {
  description = "Map of frontend port names to their resource IDs."
  value       = { for port in azurerm_application_gateway.this.frontend_port : port.name => port.id }
}

# =============================================================================
# BACKEND POOL OUTPUTS
# =============================================================================

output "backend_address_pool_ids" {
  description = "Map of backend address pool names to their resource IDs."
  value       = { for pool in azurerm_application_gateway.this.backend_address_pool : pool.name => pool.id }
}

# =============================================================================
# HTTP SETTINGS OUTPUTS
# =============================================================================

output "backend_http_settings_ids" {
  description = "Map of backend HTTP settings names to their resource IDs."
  value       = { for settings in azurerm_application_gateway.this.backend_http_settings : settings.name => settings.id }
}

# =============================================================================
# LISTENER OUTPUTS
# =============================================================================

output "http_listener_ids" {
  description = "Map of HTTP listener names to their resource IDs."
  value       = { for listener in azurerm_application_gateway.this.http_listener : listener.name => listener.id }
}

# =============================================================================
# ROUTING RULE OUTPUTS
# =============================================================================

output "request_routing_rule_ids" {
  description = "Map of request routing rule names to their resource IDs."
  value       = { for rule in azurerm_application_gateway.this.request_routing_rule : rule.name => rule.id }
}

# =============================================================================
# HEALTH PROBE OUTPUTS
# =============================================================================

output "probe_ids" {
  description = "Map of probe names to their resource IDs."
  value       = { for probe in azurerm_application_gateway.this.probe : probe.name => probe.id }
}

# =============================================================================
# SSL CERTIFICATE OUTPUTS
# =============================================================================

output "ssl_certificate_ids" {
  description = "Map of SSL certificate names to their resource IDs."
  value       = { for cert in azurerm_application_gateway.this.ssl_certificate : cert.name => cert.id }
}

# =============================================================================
# IDENTITY OUTPUTS
# =============================================================================

output "identity_principal_id" {
  description = "Principal ID of the managed identity (if SystemAssigned)."
  value       = try(azurerm_application_gateway.this.identity[0].principal_id, null)
}

output "identity_tenant_id" {
  description = "Tenant ID of the managed identity (if SystemAssigned)."
  value       = try(azurerm_application_gateway.this.identity[0].tenant_id, null)
}

# =============================================================================
# DIAGNOSTIC SETTINGS OUTPUTS
# =============================================================================

output "diagnostic_settings_id" {
  description = "Resource ID of the diagnostic settings."
  value       = var.enable_diagnostic_settings && var.log_analytics_workspace_id != null ? azurerm_monitor_diagnostic_setting.this[0].id : null
}

# =============================================================================
# GATEWAY IP CONFIGURATION OUTPUTS
# =============================================================================

output "gateway_ip_configuration_id" {
  description = "Resource ID of the gateway IP configuration."
  value       = azurerm_application_gateway.this.gateway_ip_configuration[0].id
}

output "subnet_id" {
  description = "Resource ID of the subnet where the Application Gateway is deployed."
  value       = var.subnet_id
}

# =============================================================================
# COMPUTED VALUES OUTPUTS
# =============================================================================

output "is_waf_enabled" {
  description = "Boolean indicating if WAF is enabled on the Application Gateway."
  value       = local.is_waf_sku && var.waf_enabled
}

output "zones" {
  description = "List of availability zones where the Application Gateway is deployed."
  value       = var.zones
}

output "sku_name" {
  description = "SKU name of the Application Gateway."
  value       = var.sku_name
}

output "sku_tier" {
  description = "SKU tier of the Application Gateway."
  value       = var.sku_tier
}
