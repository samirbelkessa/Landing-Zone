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
variable "resource_group_name_aue" {
  description = "Nom du Resource Group pour Australia East"
  type        = string
  default     = "rg-connectivity-aue-001"
}

variable "resource_group_name_ause" {
  description = "Nom du Resource Group pour Australia Southeast"
  type        = string
  default     = "rg-connectivity-ause-001"
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
