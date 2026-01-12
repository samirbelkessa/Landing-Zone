# =============================================================================
# VARIABLES - CONNECTIVITY AUSTRALIA
# =============================================================================

# -----------------------------------------------------------------------------
# SUBSCRIPTION & TENANT
# -----------------------------------------------------------------------------
variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "connectivity_subscription_id" {
  description = "Subscription ID pour la Connectivity (Hub networks)"
  type        = string
}

# -----------------------------------------------------------------------------
# GENERAL SETTINGS
# -----------------------------------------------------------------------------
variable "environment" {
  description = "Environnement de déploiement"
  type        = string
  default     = "Production"

  validation {
    condition     = contains(["Production", "NonProduction", "Sandbox"], var.environment)
    error_message = "L'environnement doit être Production, NonProduction ou Sandbox."
  }
}

variable "project_name" {
  description = "Nom du projet pour le tagging"
  type        = string
  default     = "ALZ-Australia"
}

variable "owner" {
  description = "Propriétaire des ressources"
  type        = string
  default     = "Platform Team"
}

variable "cost_center" {
  description = "Centre de coût pour la facturation"
  type        = string
  default     = "IT-Infrastructure"
}

# -----------------------------------------------------------------------------
# RESOURCE GROUPS
# -----------------------------------------------------------------------------
# Network RGs (VNet, Route Tables, Bastion)
variable "resource_group_name_network_aue" {
  description = "Nom du Resource Group Network pour Australia East"
  type        = string
  default     = "rg-connectivity-network-aue-001"
}

variable "resource_group_name_network_ause" {
  description = "Nom du Resource Group Network pour Australia Southeast"
  type        = string
  default     = "rg-connectivity-network-ause-001"
}


# DNS RGs
variable "resource_group_name_dns_aue" {
  description = "Nom du Resource Group DNS pour Australia East"
  type        = string
  default     = "rg-connectivity-dns-aue-001"
}

variable "resource_group_name_dns_ause" {
  description = "Nom du Resource Group DNS pour Australia Southeast"
  type        = string
  default     = "rg-connectivity-dns-ause-001"
}

# -----------------------------------------------------------------------------
# NETWORKING - AUSTRALIA EAST (PRIMARY)
# -----------------------------------------------------------------------------
variable "hub_vnet_address_space_aue" {
  description = "Address space du Hub VNet Australia East"
  type        = list(string)
  default     = ["10.0.0.0/22"]
}

variable "hub_subnets_aue" {
  description = "Configuration des subnets pour Hub Australia East"
  type = object({
    gateway_subnet                     = string
    firewall_subnet                    = string
    firewall_management_subnet         = string
    bastion_subnet                     = string
    dns_resolver_inbound_subnet        = string
    dns_resolver_outbound_subnet       = string
    management_subnet                  = string
    shared_services_subnet             = string
    private_endpoints_subnet           = string
  })
  default = {
    gateway_subnet                     = "10.0.0.0/26"
    firewall_subnet                    = "10.0.0.64/26"
    firewall_management_subnet         = "10.0.0.128/26"
    bastion_subnet                     = "10.0.0.192/26"
    dns_resolver_inbound_subnet        = "10.0.1.0/27"
    dns_resolver_outbound_subnet       = "10.0.1.32/27"
    management_subnet                  = "10.0.1.64/26"
    shared_services_subnet             = "10.0.2.0/24"
    private_endpoints_subnet           = "10.0.3.0/24"
  }
}

# -----------------------------------------------------------------------------
# NETWORKING - AUSTRALIA SOUTHEAST (DR)
# -----------------------------------------------------------------------------
variable "hub_vnet_address_space_ause" {
  description = "Address space du Hub VNet Australia Southeast"
  type        = list(string)
  default     = ["10.1.0.0/22"]
}

variable "hub_subnets_ause" {
  description = "Configuration des subnets pour Hub Australia Southeast"
  type = object({
    gateway_subnet                     = string
    firewall_subnet                    = string
    firewall_management_subnet         = string
    bastion_subnet                     = string
    dns_resolver_inbound_subnet        = string
    dns_resolver_outbound_subnet       = string
    management_subnet                  = string
    shared_services_subnet             = string
    private_endpoints_subnet           = string
  })
  default = {
    gateway_subnet                     = "10.1.0.0/26"
    firewall_subnet                    = "10.1.0.64/26"
    firewall_management_subnet         = "10.1.0.128/26"
    bastion_subnet                     = "10.1.0.192/26"
    dns_resolver_inbound_subnet        = "10.1.1.0/27"
    dns_resolver_outbound_subnet       = "10.1.1.32/27"
    management_subnet                  = "10.1.1.64/26"
    shared_services_subnet             = "10.1.2.0/24"
    private_endpoints_subnet           = "10.1.3.0/24"
  }
}

# -----------------------------------------------------------------------------
# ROUTING
# -----------------------------------------------------------------------------
variable "routing_address_space" {
  description = "Espaces d'adresses à router via le hub (RFC1918 + spokes)"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

# -----------------------------------------------------------------------------
# VPN GATEWAY
# -----------------------------------------------------------------------------
variable "enable_vpn_gateway" {
  description = "Activer le VPN Gateway"
  type        = bool
  default     = true
}

variable "vpn_gateway_sku" {
  description = "SKU du VPN Gateway"
  type        = string
  default     = "VpnGw2AZ"

  validation {
    condition     = contains(["VpnGw1", "VpnGw2", "VpnGw3", "VpnGw1AZ", "VpnGw2AZ", "VpnGw3AZ"], var.vpn_gateway_sku)
    error_message = "Le SKU doit être un SKU VPN Gateway valide."
  }
}

variable "vpn_connections" {
  description = "Configuration des connexions VPN Site-to-Site"
  type = map(object({
    name            = string
    gateway_address = string
    address_space   = list(string)
    shared_key      = string
    bgp_enabled     = optional(bool, false)
    bgp_asn         = optional(number, null)
    bgp_peering_address = optional(string, null)
    ipsec_policy = optional(object({
      dh_group         = string
      ike_encryption   = string
      ike_integrity    = string
      ipsec_encryption = string
      ipsec_integrity  = string
      pfs_group        = string
    }), null)
  }))
  default   = {}
  sensitive = false
}

# -----------------------------------------------------------------------------
# EXPRESSROUTE GATEWAY
# -----------------------------------------------------------------------------
variable "enable_expressroute_gateway" {
  description = "Activer le ExpressRoute Gateway"
  type        = bool
  default     = false
}

variable "expressroute_gateway_sku" {
  description = "SKU du ExpressRoute Gateway"
  type        = string
  default     = "ErGw1AZ"

  validation {
    condition     = contains(["Standard", "HighPerformance", "UltraPerformance", "ErGw1AZ", "ErGw2AZ", "ErGw3AZ"], var.expressroute_gateway_sku)
    error_message = "Le SKU doit être un SKU ExpressRoute Gateway valide."
  }
}

# -----------------------------------------------------------------------------
# FIREWALL
# -----------------------------------------------------------------------------
variable "firewall_sku_tier" {
  description = "Tier du SKU Azure Firewall"
  type        = string
  default     = "Premium"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.firewall_sku_tier)
    error_message = "Le tier doit être Basic, Standard ou Premium."
  }
}

variable "firewall_zones" {
  description = "Zones de disponibilité pour le Firewall"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "firewall_threat_intel_mode" {
  description = "Mode Threat Intelligence du Firewall"
  type        = string
  default     = "Alert"

  validation {
    condition     = contains(["Alert", "Deny", "Off"], var.firewall_threat_intel_mode)
    error_message = "Le mode doit être Alert, Deny ou Off."
  }
}

# -----------------------------------------------------------------------------
# BASTION
# -----------------------------------------------------------------------------
variable "bastion_sku" {
  description = "SKU Azure Bastion"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.bastion_sku)
    error_message = "Le SKU doit être Basic, Standard ou Premium."
  }
}

variable "bastion_scale_units" {
  description = "Nombre de scale units pour Bastion"
  type        = number
  default     = 2

  validation {
    condition     = var.bastion_scale_units >= 2 && var.bastion_scale_units <= 50
    error_message = "Le nombre de scale units doit être entre 2 et 50."
  }
}

# -----------------------------------------------------------------------------
# DNS
# -----------------------------------------------------------------------------
variable "dns_servers_onprem" {
  description = "Serveurs DNS on-premises pour le forwarding"
  type        = list(string)
  default     = []
}

variable "dns_forward_zones" {
  description = "Zones DNS à forwarder vers on-premises"
  type = map(object({
    domain_name              = string
    destination_ip_addresses = map(string)
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# DDOS - DÉSACTIVÉ (Cloudflare)
# -----------------------------------------------------------------------------
variable "enable_ddos_protection" {
  description = "Activer DDoS Protection Plan (désactivé car utilisation de Cloudflare)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# TAGS
# -----------------------------------------------------------------------------
variable "tags" {
  description = "Tags additionnels à appliquer aux ressources"
  type        = map(string)
  default     = {}
}

# =============================================================================
# APPLICATION GATEWAY (C13) VARIABLES
# =============================================================================

variable "enable_application_gateway" {
  description = "Enable Application Gateway deployment"
  type        = bool
  default     = false
}

variable "application_gateway_name" {
  description = "Name of the Application Gateway"
  type        = string
  default     = "agw-hub-aue-001"
}

variable "application_gateway_sku" {
  description = "SKU configuration for Application Gateway"
  type = object({
    name     = string
    tier     = string
    capacity = optional(number, null)
  })
  default = {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = null  # Use autoscale instead
  }

  validation {
    condition     = contains(["Standard_v2", "WAF_v2"], var.application_gateway_sku.name)
    error_message = "SKU name must be Standard_v2 or WAF_v2 for zone-redundant deployments."
  }
}

variable "application_gateway_autoscale" {
  description = "Autoscale configuration for Application Gateway"
  type = object({
    min_capacity = number
    max_capacity = number
  })
  default = {
    min_capacity = 1
    max_capacity = 10
  }
}

variable "application_gateway_zones" {
  description = "Availability zones for Application Gateway"
  type        = set(string)
  default     = ["1", "2", "3"]
}

variable "application_gateway_subnet_address_prefix" {
  description = "Address prefix for Application Gateway subnet (minimum /26)"
  type        = string
  default     = "10.0.1.192/26"
}

variable "enable_waf" {
  description = "Enable Web Application Firewall (requires WAF_v2 SKU)"
  type        = bool
  default     = true
}

variable "waf_mode" {
  description = "WAF mode: Detection or Prevention"
  type        = string
  default     = "Prevention"

  validation {
    condition     = contains(["Detection", "Prevention"], var.waf_mode)
    error_message = "WAF mode must be Detection or Prevention."
  }
}

variable "waf_rule_set_version" {
  description = "OWASP rule set version for WAF"
  type        = string
  default     = "3.2"
}

variable "application_gateway_ssl_policy" {
  description = "SSL policy configuration for Application Gateway"
  type = object({
    policy_type          = string
    min_protocol_version = string
    cipher_suites        = optional(list(string))
  })
  default = {
    policy_type          = "Predefined"
    min_protocol_version = "TLSv1_2"
    cipher_suites        = null
  }
}

variable "application_gateway_backend_pools" {
  description = "Backend address pools configuration"
  type = map(object({
    name         = string
    fqdns        = optional(set(string))
    ip_addresses = optional(set(string))
  }))
  default = {
    default = {
      name         = "default-backend-pool"
      fqdns        = null
      ip_addresses = null
    }
  }
}

variable "application_gateway_backend_http_settings" {
  description = "Backend HTTP settings configuration"
  type = map(object({
    name                                = string
    port                                = number
    protocol                            = string
    cookie_based_affinity               = optional(string, "Disabled")
    request_timeout                     = optional(number, 30)
    probe_name                          = optional(string)
    pick_host_name_from_backend_address = optional(bool, false)
    host_name                           = optional(string)
    path                                = optional(string)
    trusted_root_certificate_names      = optional(list(string))
  }))
  default = {
    default = {
      name                  = "default-http-settings"
      port                  = 80
      protocol              = "Http"
      cookie_based_affinity = "Disabled"
      request_timeout       = 30
    }
  }
}

variable "application_gateway_frontend_ports" {
  description = "Frontend ports configuration"
  type = map(object({
    name = string
    port = number
  }))
  default = {
    http = {
      name = "port-80"
      port = 80
    }
    https = {
      name = "port-443"
      port = 443
    }
  }
}

variable "application_gateway_http_listeners" {
  description = "HTTP listeners configuration"
  type = map(object({
    name                           = string
    frontend_port_name             = string
    frontend_ip_configuration_name = optional(string)
    host_name                      = optional(string)
    host_names                     = optional(list(string))
    ssl_certificate_name           = optional(string)
    require_sni                    = optional(bool, false)
    firewall_policy_id             = optional(string)
  }))
  default = {
    default = {
      name               = "default-http-listener"
      frontend_port_name = "port-80"
    }
  }
}

variable "application_gateway_request_routing_rules" {
  description = "Request routing rules configuration"
  type = map(object({
    name                        = string
    rule_type                   = string
    http_listener_name          = string
    backend_address_pool_name   = string
    backend_http_settings_name  = string
    priority                    = number
    url_path_map_name           = optional(string)
    redirect_configuration_name = optional(string)
    rewrite_rule_set_name       = optional(string)
  }))
  default = {
    default = {
      name                       = "default-routing-rule"
      rule_type                  = "Basic"
      http_listener_name         = "default-http-listener"
      backend_address_pool_name  = "default-backend-pool"
      backend_http_settings_name = "default-http-settings"
      priority                   = 100
    }
  }
}

variable "application_gateway_health_probes" {
  description = "Health probe configurations"
  type = map(object({
    name                                      = string
    protocol                                  = string
    path                                      = string
    interval                                  = number
    timeout                                   = number
    unhealthy_threshold                       = number
    host                                      = optional(string, "127.0.0.1")
    port                                      = optional(number)
    pick_host_name_from_backend_http_settings = optional(bool, false)
    minimum_servers                           = optional(number, 0)
    match = optional(object({
      body        = optional(string)
      status_code = list(string)
    }))
  }))
  default = {}
}

variable "application_gateway_ssl_certificates" {
  description = "SSL certificates configuration (Key Vault integration)"
  type = map(object({
    name                = string
    key_vault_secret_id = optional(string)
    data                = optional(string)
    password            = optional(string)
  }))
  default   = {}
  sensitive = true
}

variable "application_gateway_private_ip_address" {
  description = "Private IP address for Application Gateway (optional, uses dynamic if not set)"
  type        = string
  default     = null
}

variable "application_gateway_enable_private_frontend" {
  description = "Enable private frontend IP configuration"
  type        = bool
  default     = false
}

# Log Analytics Workspace ID from Management Layer (for diagnostics)
variable "log_analytics_workspace_id" {
  description = "Resource ID of Log Analytics Workspace from Management layer for diagnostics"
  type        = string
  default     = ""
}