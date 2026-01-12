# -----------------------------------------------------------------------------
# C13 - APPLICATION GATEWAY MODULE
# Local Values - Tags, computed values, and transformations
# -----------------------------------------------------------------------------

locals {
  # ===========================================================================
  # Default Tags (merged with user-provided tags)
  # ===========================================================================
  default_tags = {
    ManagedBy = "Terraform"
    Module    = "C13-application-gateway"
  }

  tags = merge(local.default_tags, var.tags)

  # ===========================================================================
  # Naming Conventions
  # ===========================================================================
  # Public IP name derived from Application Gateway name
  public_ip_name = replace(var.name, "agw-", "pip-agw-")

  # WAF Policy name derived from Application Gateway name
  waf_policy_name = replace(var.name, "agw-", "waf-")

  # Diagnostic settings name
  diagnostic_settings_name = "diag-${var.name}"

  # ===========================================================================
  # Frontend IP Configuration
  # ===========================================================================
  frontend_ip_configuration_name = "public-frontend-ip"

  # ===========================================================================
  # SKU Configuration
  # ===========================================================================
  # Determine if WAF is being used
  is_waf_sku = var.sku_name == "WAF_v2"

  # SKU configuration block
  sku_config = {
    name = var.sku_name
    tier = var.sku_tier
  }

  # ===========================================================================
  # Capacity Configuration
  # ===========================================================================
  # Autoscale configuration (if enabled)
  autoscale_config = var.autoscale_enabled ? {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  } : null

  # Fixed capacity (if autoscaling disabled)
  fixed_capacity = var.autoscale_enabled ? null : var.capacity

  # ===========================================================================
  # WAF Configuration
  # ===========================================================================
  # WAF configuration block (only if WAF SKU and WAF enabled)
  waf_config = local.is_waf_sku && var.waf_enabled ? {
    enabled                  = true
    firewall_mode            = var.waf_mode
    rule_set_type            = var.waf_rule_set_type
    rule_set_version         = var.waf_rule_set_version
    file_upload_limit_mb     = var.waf_file_upload_limit_mb
    max_request_body_size_kb = var.waf_max_request_body_size_kb
  } : null

  # ===========================================================================
  # SSL Policy
  # ===========================================================================
  ssl_policy = {
    policy_type = var.ssl_policy_type
    policy_name = var.ssl_policy_type == "Predefined" ? var.ssl_policy_name : null
  }

  # ===========================================================================
  # Identity Configuration
  # ===========================================================================
  # Identity block (if identity IDs provided or User Assigned requested)
  identity_config = length(var.identity_ids) > 0 || var.identity_type != "UserAssigned" ? {
    type         = var.identity_type
    identity_ids = var.identity_type == "SystemAssigned" ? [] : var.identity_ids
  } : null

  # ===========================================================================
  # Public IP Configuration
  # ===========================================================================
  # Determine the Public IP ID to use
  public_ip_id = var.create_public_ip ? azurerm_public_ip.this[0].id : var.existing_public_ip_id

  # ===========================================================================
  # Diagnostic Settings
  # ===========================================================================
  # Log categories for diagnostic settings
  enabled_logs = var.enable_diagnostic_settings ? [
    for category in var.diagnostic_logs_categories : {
      category = category
      enabled  = true
    }
  ] : []

  # Metric categories for diagnostic settings
  enabled_metrics = var.enable_diagnostic_settings ? [
    for category in var.diagnostic_metrics_categories : {
      category = category
      enabled  = true
    }
  ] : []

  # ===========================================================================
  # Backend Pools - Convert to map for for_each
  # ===========================================================================
  backend_pools_map = { for pool in var.backend_address_pools : pool.name => pool }

  # ===========================================================================
  # Backend HTTP Settings - Convert to map for for_each
  # ===========================================================================
  backend_http_settings_map = { for setting in var.backend_http_settings : setting.name => setting }

  # ===========================================================================
  # Frontend Ports - Convert to map for for_each
  # ===========================================================================
  frontend_ports_map = { for port in var.frontend_port_settings : port.name => port }

  # ===========================================================================
  # HTTP Listeners - Convert to map for for_each
  # ===========================================================================
  http_listeners_map = { for listener in var.http_listeners : listener.name => listener }

  # ===========================================================================
  # Request Routing Rules - Convert to map for for_each
  # ===========================================================================
  routing_rules_map = { for rule in var.request_routing_rules : rule.name => rule }

  # ===========================================================================
  # Health Probes - Convert to map for for_each
  # ===========================================================================
  health_probes_map = { for probe in var.health_probes : probe.name => probe }

  # ===========================================================================
  # SSL Certificates - Convert to map for for_each
  # ===========================================================================
  ssl_certificates_map = { for cert in var.ssl_certificates : cert.name => cert }
}
