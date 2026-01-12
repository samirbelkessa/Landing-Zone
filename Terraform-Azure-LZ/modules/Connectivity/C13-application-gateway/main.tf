# -----------------------------------------------------------------------------
# C13 - APPLICATION GATEWAY MODULE
# Azure Resources - Application Gateway with WAF v2
# -----------------------------------------------------------------------------

# =============================================================================
# PUBLIC IP ADDRESS
# Required for Application Gateway frontend (internet-facing)
# =============================================================================

resource "azurerm_public_ip" "this" {
  count = var.create_public_ip ? 1 : 0

  name                = local.public_ip_name
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = var.public_ip_allocation_method
  sku                 = var.public_ip_sku
  zones               = var.zones

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# WEB APPLICATION FIREWALL POLICY
# WAF v2 policy with OWASP rules (created if no external policy provided)
# =============================================================================

resource "azurerm_web_application_firewall_policy" "this" {
  count = local.is_waf_sku && var.waf_enabled && var.firewall_policy_id == null ? 1 : 0

  name                = local.waf_policy_name
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = local.tags

  # Policy Settings
  policy_settings {
    enabled                     = true
    mode                        = var.waf_mode
    file_upload_limit_in_mb     = var.waf_file_upload_limit_mb
    max_request_body_size_in_kb = var.waf_max_request_body_size_kb
    request_body_check          = true
  }

  # Managed Rule Set (OWASP)
  managed_rules {
    managed_rule_set {
      type    = var.waf_rule_set_type
      version = var.waf_rule_set_version

      # Disabled rule groups (if any)
      dynamic "rule_group_override" {
        for_each = var.waf_disabled_rule_groups
        content {
          rule_group_name = rule_group_override.value.rule_group_name

          dynamic "rule" {
            for_each = rule_group_override.value.rules
            content {
              id      = rule.value
              enabled = false
            }
          }
        }
      }
    }
  }

  # Exclusions (if any)
  dynamic "managed_rules" {
    for_each = length(var.waf_exclusions) > 0 ? [1] : []
    content {
      dynamic "exclusion" {
        for_each = var.waf_exclusions
        content {
          match_variable          = exclusion.value.match_variable
          selector                = exclusion.value.selector
          selector_match_operator = exclusion.value.selector_match_operator
        }
      }

      managed_rule_set {
        type    = var.waf_rule_set_type
        version = var.waf_rule_set_version
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# APPLICATION GATEWAY
# Main Application Gateway resource with WAF v2
# =============================================================================

resource "azurerm_application_gateway" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  zones               = var.zones
  enable_http2        = var.enable_http2
  fips_enabled        = var.fips_enabled
  firewall_policy_id  = local.is_waf_sku && var.waf_enabled ? (var.firewall_policy_id != null ? var.firewall_policy_id : azurerm_web_application_firewall_policy.this[0].id) : null

  force_firewall_policy_association = var.force_firewall_policy_association

  tags = local.tags

  # ---------------------------------------------------------------------------
  # SKU Configuration
  # ---------------------------------------------------------------------------
  sku {
    name = local.sku_config.name
    tier = local.sku_config.tier
  }

  # ---------------------------------------------------------------------------
  # Capacity - Fixed or Autoscale
  # ---------------------------------------------------------------------------
  dynamic "autoscale_configuration" {
    for_each = local.autoscale_config != null ? [local.autoscale_config] : []
    content {
      min_capacity = autoscale_configuration.value.min_capacity
      max_capacity = autoscale_configuration.value.max_capacity
    }
  }

  # ---------------------------------------------------------------------------
  # Gateway IP Configuration (Subnet)
  # ---------------------------------------------------------------------------
  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = var.subnet_id
  }

  # ---------------------------------------------------------------------------
  # Frontend IP Configuration (Public)
  # ---------------------------------------------------------------------------
  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = local.public_ip_id
  }

  # ---------------------------------------------------------------------------
  # Frontend Ports
  # ---------------------------------------------------------------------------
  dynamic "frontend_port" {
    for_each = local.frontend_ports_map
    content {
      name = frontend_port.value.name
      port = frontend_port.value.port
    }
  }

  # ---------------------------------------------------------------------------
  # Backend Address Pools
  # ---------------------------------------------------------------------------
  dynamic "backend_address_pool" {
    for_each = local.backend_pools_map
    content {
      name         = backend_address_pool.value.name
      fqdns        = backend_address_pool.value.fqdns
      ip_addresses = backend_address_pool.value.ip_addresses
    }
  }

  # ---------------------------------------------------------------------------
  # Backend HTTP Settings
  # ---------------------------------------------------------------------------
  dynamic "backend_http_settings" {
    for_each = local.backend_http_settings_map
    content {
      name                                = backend_http_settings.value.name
      port                                = backend_http_settings.value.port
      protocol                            = backend_http_settings.value.protocol
      cookie_based_affinity               = backend_http_settings.value.cookie_based_affinity
      affinity_cookie_name                = backend_http_settings.value.affinity_cookie_name
      path                                = backend_http_settings.value.path
      probe_name                          = backend_http_settings.value.probe_name
      request_timeout                     = backend_http_settings.value.request_timeout
      host_name                           = backend_http_settings.value.host_name
      pick_host_name_from_backend_address = backend_http_settings.value.pick_host_name_from_backend_address
      trusted_root_certificate_names      = backend_http_settings.value.trusted_root_certificate_names

      dynamic "connection_draining" {
        for_each = backend_http_settings.value.connection_draining != null ? [backend_http_settings.value.connection_draining] : []
        content {
          enabled           = connection_draining.value.enabled
          drain_timeout_sec = connection_draining.value.drain_timeout_sec
        }
      }
    }
  }

  # ---------------------------------------------------------------------------
  # HTTP Listeners
  # ---------------------------------------------------------------------------
  dynamic "http_listener" {
    for_each = local.http_listeners_map
    content {
      name                           = http_listener.value.name
      frontend_ip_configuration_name = coalesce(http_listener.value.frontend_ip_configuration_name, local.frontend_ip_configuration_name)
      frontend_port_name             = http_listener.value.frontend_port_name
      protocol                       = http_listener.value.protocol
      host_name                      = http_listener.value.host_name
      host_names                     = http_listener.value.host_names
      ssl_certificate_name           = http_listener.value.ssl_certificate_name
      require_sni                    = http_listener.value.require_sni
      firewall_policy_id             = http_listener.value.firewall_policy_id

      dynamic "custom_error_configuration" {
        for_each = http_listener.value.custom_error_configuration
        content {
          status_code           = custom_error_configuration.value.status_code
          custom_error_page_url = custom_error_configuration.value.custom_error_page_url
        }
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Request Routing Rules
  # ---------------------------------------------------------------------------
  dynamic "request_routing_rule" {
    for_each = local.routing_rules_map
    content {
      name                        = request_routing_rule.value.name
      rule_type                   = request_routing_rule.value.rule_type
      http_listener_name          = request_routing_rule.value.http_listener_name
      backend_address_pool_name   = request_routing_rule.value.backend_address_pool_name
      backend_http_settings_name  = request_routing_rule.value.backend_http_settings_name
      redirect_configuration_name = request_routing_rule.value.redirect_configuration_name
      rewrite_rule_set_name       = request_routing_rule.value.rewrite_rule_set_name
      url_path_map_name           = request_routing_rule.value.url_path_map_name
      priority                    = request_routing_rule.value.priority
    }
  }

  # ---------------------------------------------------------------------------
  # Health Probes (Custom)
  # ---------------------------------------------------------------------------
  dynamic "probe" {
    for_each = local.health_probes_map
    content {
      name                                      = probe.value.name
      protocol                                  = probe.value.protocol
      path                                      = probe.value.path
      host                                      = probe.value.host
      port                                      = probe.value.port
      interval                                  = probe.value.interval
      timeout                                   = probe.value.timeout
      unhealthy_threshold                       = probe.value.unhealthy_threshold
      pick_host_name_from_backend_http_settings = probe.value.pick_host_name_from_backend_http_settings
      minimum_servers                           = probe.value.minimum_servers

      dynamic "match" {
        for_each = probe.value.match != null ? [probe.value.match] : []
        content {
          body        = match.value.body
          status_code = match.value.status_code
        }
      }
    }
  }

  # ---------------------------------------------------------------------------
  # SSL Certificates
  # ---------------------------------------------------------------------------
  dynamic "ssl_certificate" {
    for_each = local.ssl_certificates_map
    content {
      name                = ssl_certificate.value.name
      key_vault_secret_id = ssl_certificate.value.key_vault_secret_id
      data                = ssl_certificate.value.data
      password            = ssl_certificate.value.password
    }
  }

  # ---------------------------------------------------------------------------
  # SSL Policy
  # ---------------------------------------------------------------------------
  ssl_policy {
    policy_type = local.ssl_policy.policy_type
    policy_name = local.ssl_policy.policy_name
  }

  # ---------------------------------------------------------------------------
  # Identity (for Key Vault integration)
  # ---------------------------------------------------------------------------
  dynamic "identity" {
    for_each = local.identity_config != null ? [local.identity_config] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  # ---------------------------------------------------------------------------
  # Private Link Configurations (if any)
  # ---------------------------------------------------------------------------
  dynamic "private_link_configuration" {
    for_each = var.private_link_configurations
    content {
      name = private_link_configuration.value.name

      dynamic "ip_configuration" {
        for_each = private_link_configuration.value.ip_configuration
        content {
          name                          = ip_configuration.value.name
          subnet_id                     = ip_configuration.value.subnet_id
          private_ip_address_allocation = ip_configuration.value.private_ip_address_allocation
          primary                       = ip_configuration.value.primary
          private_ip_address            = ip_configuration.value.private_ip_address
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      # Ignore changes that are managed externally
      tags["CreatedDate"],
    ]
  }
}

# =============================================================================
# DIAGNOSTIC SETTINGS
# Send logs and metrics to Log Analytics Workspace
# =============================================================================

resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.enable_diagnostic_settings && var.log_analytics_workspace_id != null ? 1 : 0

  name                       = local.diagnostic_settings_name
  target_resource_id         = azurerm_application_gateway.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Access Logs
  dynamic "enabled_log" {
    for_each = var.diagnostic_logs_categories
    content {
      category = enabled_log.value
    }
  }

  # Metrics
  dynamic "metric" {
    for_each = var.diagnostic_metrics_categories
    content {
      category = metric.value
      enabled  = true
    }
  }
}

# =============================================================================
# PUBLIC IP DIAGNOSTIC SETTINGS
# Send Public IP logs to Log Analytics
# =============================================================================

resource "azurerm_monitor_diagnostic_setting" "public_ip" {
  count = var.create_public_ip && var.enable_diagnostic_settings && var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "diag-${local.public_ip_name}"
  target_resource_id         = azurerm_public_ip.this[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "DDoSProtectionNotifications"
  }

  enabled_log {
    category = "DDoSMitigationFlowLogs"
  }

  enabled_log {
    category = "DDoSMitigationReports"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
