variable "Brainboard_IP_Range_List" {
  type    = list(string)
  default = ["3.18.12.57", "3.19.117.9", "3.12.21.31", "3.140.65.244", "18.223.219.168", "3.139.254.14", "3.109.176.247", "13.235.196.228", "3.108.102.235", "35.154.77.165"]
}

variable "additional_routes" {
  description = "Additional UDR routes beyond the default 0.0.0.0/0 → Firewall."
  type = map(object({
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string, null)
  }))
  default = {}
}

variable "additional_vnets" {
  description = "Additional VNets to create in the same Resource Group, each with optional subnets and hub peering."
  type = map(object({
    address_space               = list(string)
    allow_gateway_transit       = optional(bool, true)
    hub_allow_forwarded_traffic = optional(bool, true)
    use_remote_gateways         = optional(bool, true)
    subnets = optional(map(object({
      address_prefixes                  = list(string)
      private_endpoint_network_policies = optional(string, "Enabled")
    })), {})
  }))
  default = {}
}

variable "address_space" {
  description = "VNet address space as a list of CIDRs."
  type        = list(string)

  validation {
    condition     = length(var.address_space) >= 1
    error_message = "variable value does not match the validator"
  }
}

variable "allow_forwarded_traffic" {
  description = "Allow forwarded traffic on both peering sides."
  type        = bool
  default     = true
}

variable "allow_gateway_transit" {
  description = "Allow gateway transit on hub side (true for NonProd with VPN GW, false for Prod)."
  type        = bool
  default     = true
}

variable "bastion_subnet_prefix" {
  description = "Azure Bastion subnet CIDR from hub (e.g. '10.0.0.192/26'). Required when enable_baseline_nsg_rules = true. Passed from connectivity module output."
  type        = string
  default     = ""
}

variable "bastion_target_subnet_keys" {
  description = "Subnet keys that need Bastion SSH/RDP inbound access. Default: aks and jmp."
  type        = list(string)
  default     = ["aks", "jmp"]
}

variable "custom_default_route_name" {
  description = "Override default route name (default: 'default-to-azfw')."
  type        = string
  default     = null
}

variable "custom_nsg_names" {
  description = "Override auto-generated NSG names per subnet key. Only keys present here are overridden."
  type        = map(string)
  default     = {}
}

variable "custom_peering_name_hub_to_spoke" {
  description = "Override auto-generated hub→spoke peering name."
  type        = string
  default     = null
}

variable "custom_peering_name_spoke_to_hub" {
  description = "Override auto-generated spoke→hub peering name."
  type        = string
  default     = null
}

variable "custom_resource_group_name" {
  description = "Override auto-generated Resource Group name."
  type        = string
  default     = null
}

variable "custom_route_table_name" {
  description = "Override auto-generated Route Table name."
  type        = string
  default     = null
}

variable "custom_vnet_name" {
  description = "Override auto-generated VNet name."
  type        = string
  default     = null
}

variable "disable_bgp_route_propagation" {
  description = "Disable BGP route propagation on the route table."
  type        = bool
  default     = true
}

variable "dns_servers" {
  description = "Custom DNS servers for the VNet. Defaults to [firewall_private_ip] when null."
  type        = list(string)
  default     = null
}

variable "enable_baseline_nsg_rules" {
  description = "Deploy baseline NSG rules (Bastion inbound, deny-all outbound override, VNet outbound, ALB inbound)."
  type        = bool
  default     = true
}

variable "enable_delete_lock" {
  description = "Create a CanNotDelete management lock on the VNet."
  type        = bool
  default     = true
}

variable "enable_hub_peering" {
  description = "Enable hub-spoke peering, default route to firewall, and DNS via firewall. Set to false when deploying without hub connectivity."
  type        = bool
  default     = true
}

variable "enable_nsg_diagnostics" {
  description = <<EOT
Enable diagnostic settings on NSGs (NetworkSecurityGroupEvent + RuleCounter → LAW).
Set to false if NSG diagnostics are already managed by an Azure Policy
(e.g. setByPolicy-LogAnalytics) to avoid duplicate diagnostic settings.
EOT
  type        = bool
  default     = true
}

variable "enable_traffic_analytics" {
  description = "Enable Traffic Analytics integration with Log Analytics."
  type        = bool
  default     = true
}

variable "enable_vnet_diagnostics" {
  description = "Enable diagnostic settings on the VNet (AllMetrics → LAW)."
  type        = bool
  default     = true
}

variable "enable_vnet_flow_logs" {
  description = "Enable VNet Flow Logs on primary and additional VNets."
  type        = bool
  default     = false
}

variable "environment" {
  description = "Environment name: Development, Test, Staging, Production."
  type        = string

  validation {
    condition     = contains(["Development", "Test", "Staging", "Production"], var.environment)
    error_message = "variable value does not match the validator"
  }
}

variable "firewall_private_ip" {
  description = "Azure Firewall private IP for default UDR and VNet DNS. Empty string allowed when enable_hub_peering = false."
  type        = string
  default     = ""

  validation {
    condition     = var.firewall_private_ip == "" || can(cidrhost("${var.firewall_private_ip}/32", 0))
    error_message = "firewall_private_ip must be a valid IPv4 address or empty string."
  }
}

variable "flow_logs_retention_days" {
  description = "Number of days to retain flow log data."
  type        = number
  default     = 90
}

variable "flow_logs_storage_account_id" {
  description = "Resource ID of the storage account for flow log data (cross-subscription OK)."
  type        = string
  default     = ""
}

variable "hub_resource_group_name" {
  description = "Hub VNet Resource Group name."
  type        = string
}

variable "hub_vnet_id" {
  description = "Hub VNet resource ID."
  type        = string
}

variable "hub_vnet_name" {
  description = "Hub VNet name (for hub-side peering resource creation)."
  type        = string
}

variable "instance" {
  description = "Instance number, 2-digit zero-padded (e.g. '01', '02')."
  type        = string
  default     = "01"

  validation {
    condition     = can(regex("^[0-9]{2}$", var.instance))
    error_message = "variable value does not match the validator"
  }
}

variable "location" {
  description = "Azure region for resource deployment (e.g. 'australiaeast')."
  type        = string
}

variable "location_short" {
  description = "Short region code for naming (e.g. 'aea' for australiaeast). Auto-detected if null."
  type        = string
  default     = null
}

variable "log_analytics_workspace_guid" {
  description = "Workspace ID (GUID) for Traffic Analytics."
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace resource ID for diagnostics. Empty string disables diagnostics."
  type        = string
  default     = ""
}

variable "log_analytics_workspace_region" {
  description = "Azure region of the Log Analytics workspace."
  type        = string
  default     = null
}

variable "nsg_rules" {
  description = "Additional NSG security rules keyed by rule name. Merged with baseline rules."
  type = map(object({
    nsg_key                      = optional(string, null)
    priority                     = number
    direction                    = string
    access                       = string
    protocol                     = string
    source_port_range            = optional(string, "*")
    source_port_ranges           = optional(list(string), null)
    destination_port_range       = optional(string, null)
    destination_port_ranges      = optional(list(string), null)
    source_address_prefix        = optional(string, null)
    source_address_prefixes      = optional(list(string), null)
    destination_address_prefix   = optional(string, null)
    destination_address_prefixes = optional(list(string), null)
  }))
  default = {}
}

variable "nsg_subnet_keys" {
  description = "Subnet keys receiving an NSG. Null = all subnets get an NSG."
  type        = list(string)
  default     = null
}

variable "private_dns_zone_links" {
  description = <<EOT
Map of Private DNS zones to link to this spoke VNet. Enables Private Endpoint
FQDN resolution from the spoke. DNS zones are expected to live in the hub
(connectivity) subscription — links are created via the azurerm.hub provider.

Example:
  private_dns_zone_links = {
    database = { zone_name = "privatelink.database.windows.net",     resource_group_name = "rg-dns-aue-001" }
    blob     = { zone_name = "privatelink.blob.core.windows.net",    resource_group_name = "rg-dns-aue-001" }
    vault    = { zone_name = "privatelink.vaultcore.azure.net",      resource_group_name = "rg-dns-aue-001" }
    fabric   = { zone_name = "privatelink.fabric.microsoft.com",     resource_group_name = "rg-dns-aue-001" }
  }
EOT
  type = map(object({
    zone_name           = string
    resource_group_name = string
  }))
  default = {}
}

variable "root_id" {
  description = "Root Management Group ID used as naming prefix (e.g. 'asd', 'qpc', 'contoso')."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,9}$", var.root_id))
    error_message = "variable value does not match the validator"
  }
}

variable "subnets" {
  description = <<EOT
Subnet definitions keyed by logical function (e.g. 'aks', 'pep', 'jump', 'pls').
- custom_name: Override auto-generated subnet name.
- address_prefixes: CIDR(s) for the subnet.
- private_link_service_network_policies_enabled: false for PLS subnets.
- private_endpoint_network_policies: "Enabled" or "Disabled".
- service_endpoints: List of service endpoints.
- delegation: Optional subnet delegation.
EOT
  type = map(object({
    custom_name                                   = optional(string, null)
    address_prefixes                              = list(string)
    private_link_service_network_policies_enabled = optional(bool, true)
    private_endpoint_network_policies             = optional(string, "Enabled")
    service_endpoints                             = optional(list(string), [])
    delegation = optional(object({
      name = string
      service_delegation = object({
        name    = string
        actions = optional(list(string), [])
      })
    }), null)
  }))
}

variable "tags" {
  description = "Tags applied to all resources. Expected: Environment, Owner, CostCenter, Application."
  type        = map(string)
  default     = {}
}

variable "udr_subnet_keys" {
  description = "Subnet keys receiving the UDR association (default route → Firewall)."
  type        = list(string)
  default     = ["aks"]
}

variable "use_remote_gateways" {
  description = "Use remote gateways on spoke side (mirrors allow_gateway_transit)."
  type        = bool
  default     = true
}

variable "workload" {
  description = "Workload short name, 2-10 chars (e.g. 'app', 'web', 'data')."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,9}$", var.workload))
    error_message = "variable value does not match the validator"
  }
}

