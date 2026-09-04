variable "Brainboard_IP_Range_List" {
  type    = list(string)
  default = ["3.18.12.57", "3.19.117.9", "3.12.21.31", "3.140.65.244", "18.223.219.168", "3.139.254.14", "3.109.176.247", "13.235.196.228", "3.108.102.235", "35.154.77.165"]
}

variable "additional_resource_groups" {
  description = "Additional resource groups to create in the spoke subscription."
  type = map(object({
    name     = string
    location = optional(string, null)
    tags     = optional(map(string), {})
  }))
  default = {}
}

variable "additional_routes" {
  description = "Additional UDR routes beyond the default 0.0.0.0/0 -> Firewall."
  type = map(object({
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string, null)
  }))
  default = {}
}

variable "additional_vnets" {
  description = "Additional VNets to create in the same Resource Group."
  type = map(object({
    address_space               = list(string)
    allow_gateway_transit       = optional(bool, false)
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
  description = "Primary VNet address space as a list of CIDRs."
  type        = list(string)
}

variable "allow_gateway_transit" {
  description = "Allow gateway transit on hub side."
  type        = bool
  default     = true
}

variable "base_nsg_rules" {
  description = "Base NSG rules applied to all environments before client-specific rules."
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

variable "bastion_subnet_prefix" {
  description = "Azure Bastion subnet CIDR from hub."
  type        = string
  default     = ""
}

variable "bastion_target_subnet_keys" {
  description = "Subnet keys that need Bastion SSH/RDP access."
  type        = list(string)
  default     = ["aks", "jmp"]
}

variable "client_name" {
  description = "Human-readable client name for display names and descriptions (e.g. 'CluedIn')."
  type        = string
}

variable "client_prefix" {
  description = "Short prefix for naming (e.g. 'cln'). Used in resource names via L02-Spoke workload parameter."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,9}$", var.client_prefix))
    error_message = "variable value does not match the validator"
  }
}

variable "custom_default_route_name" {
  description = "Override auto-generated default route name."
  type        = string
  default     = null
}

variable "custom_nsg_names" {
  description = "Override NSG names per subnet key."
  type        = map(string)
  default     = {}
}

variable "custom_peering_name_hub_to_spoke" {
  description = "Override auto-generated hub-to-spoke peering name."
  type        = string
  default     = null
}

variable "custom_peering_name_spoke_to_hub" {
  description = "Override auto-generated spoke-to-hub peering name."
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

variable "deploy_additional_vnet_monitor_diagnostics" {
  description = "Deploy diagnostic settings for additional VNets to monitoring LAW."
  type        = bool
  default     = false
}

variable "deploy_firewall_rules" {
  description = "Deploy firewall rule collection groups for this client environment."
  type        = bool
  default     = true
}

variable "deploy_managed_identity" {
  description = "Deploy a User-Assigned Managed Identity for this environment."
  type        = bool
  default     = false
}

variable "deploy_policy_exemptions" {
  description = "Deploy policy exemptions for VNet diagnostic settings managed by Terraform."
  type        = bool
  default     = false
}

variable "deploy_shared_firewall_app_rules" {
  description = "Deploy shared application firewall rules. Set true for ONLY ONE environment per client."
  type        = bool
  default     = false
}

variable "deploy_vnet_monitor_diagnostics" {
  description = "Deploy VNet diagnostic settings to monitoring LAW."
  type        = bool
  default     = false
}

variable "disable_bgp_route_propagation" {
  description = "Disable BGP route propagation on the route table."
  type        = bool
  default     = true
}

variable "enable_baseline_nsg_rules" {
  description = "Deploy baseline NSG rules (Bastion inbound, deny-all, etc.) from L02-Spoke."
  type        = bool
  default     = false
}

variable "enable_delete_lock" {
  description = "Create a CanNotDelete management lock on the VNet."
  type        = bool
  default     = true
}

variable "enable_hub_peering" {
  description = "Enable hub-spoke peering and firewall routing. Set to false when deploying without hub connectivity."
  type        = bool
  default     = true
}

variable "enable_nsg_diagnostics" {
  description = "Enable diagnostic settings on NSGs (inside L02-Spoke)."
  type        = bool
  default     = false
}

variable "enable_resource_provider_registration" {
  description = "Register required Azure resource providers in the spoke subscription before deploying resources."
  type        = bool
  default     = false
}

variable "enable_traffic_analytics" {
  description = "Enable Traffic Analytics integration with Log Analytics."
  type        = bool
  default     = true
}

variable "enable_vnet_diagnostics" {
  description = "Enable diagnostic settings on the VNet (inside L02-Spoke)."
  type        = bool
  default     = false
}

variable "enable_vnet_flow_logs" {
  description = "Enable VNet Flow Logs on primary and additional VNets."
  type        = bool
  default     = false
}

variable "environment_key" {
  description = "Short environment identifier (e.g. 'dev', 'prod', 'staging'). Used in resource naming."
  type        = string
}

variable "environment_name" {
  description = "Full environment name for L02-Spoke: Development, Test, Staging, Production."
  type        = string

  validation {
    condition     = contains(["Development", "Test", "Staging", "Production"], var.environment_name)
    error_message = "variable value does not match the validator"
  }
}

variable "firewall_app_collection_name" {
  description = "Override name for the application rule collection group. Auto: {ClientName}ApplicationRuleCollectionGroup."
  type        = string
  default     = null
}

variable "firewall_app_rule_priority" {
  description = "Priority for the application rule collection group."
  type        = number
  default     = 400
}

variable "firewall_app_rules" {
  description = "Application firewall rules (shared across all environments for this client)."
  type = list(object({
    name              = string
    source_addresses  = list(string)
    destination_fqdns = list(string)
    protocols = list(object({
      type = string
      port = number
    }))
  }))
  default = []
}

variable "firewall_network_collection_name" {
  description = "Override name for the network rule collection group. Auto: {ENV}NetworkRuleCollectionGroup."
  type        = string
  default     = null
}

variable "firewall_network_rule_priority" {
  description = "Priority for the per-environment network rule collection group."
  type        = number
  default     = 401
}

variable "firewall_network_rules" {
  description = "Network firewall rules specific to this environment."
  type = list(object({
    name                  = string
    source_addresses      = list(string)
    destination_addresses = list(string)
    destination_ports     = list(string)
    protocols             = list(string)
  }))
  default = []
}

variable "firewall_policy_id" {
  description = "Firewall global policy ID for creating client-specific rule collection groups."
  type        = string
  default     = ""
}

variable "firewall_private_ip" {
  description = "Azure Firewall private IP for default UDR and VNet DNS. Empty string when hub is disabled."
  type        = string
  default     = ""
}

variable "flow_logs_retention_days" {
  description = "Number of days to retain flow log data."
  type        = number
  default     = 90
}

variable "flow_logs_storage_account_id" {
  description = "Resource ID of the storage account for flow log data."
  type        = string
  default     = ""
}

variable "hub_resource_group_name" {
  description = "Hub VNet Resource Group name from connectivity module."
  type        = string
}

variable "hub_vnet_id" {
  description = "Hub VNet resource ID from connectivity module."
  type        = string
}

variable "hub_vnet_name" {
  description = "Hub VNet name from connectivity module."
  type        = string
}

variable "instance" {
  description = "Instance number, 2-digit zero-padded (e.g. '01')."
  type        = string
  default     = "01"
}

variable "location" {
  description = "Azure region for resource deployment (e.g. 'australiaeast')."
  type        = string
}

variable "log_analytics_workspace_guid" {
  description = "Log Analytics Workspace ID (GUID) for Traffic Analytics."
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace resource ID (ARM ID) for spoke diagnostics and Traffic Analytics."
  type        = string
  default     = ""
}

variable "log_analytics_workspace_region" {
  description = "Azure region of the Log Analytics workspace."
  type        = string
  default     = null
}

variable "monitor_log_analytics_workspace_id" {
  description = "Monitoring LAW resource ID for VNet diagnostic settings (separate from spoke LAW)."
  type        = string
  default     = ""
}

variable "nsg_rules" {
  description = "Custom NSG rules specific to this client environment."
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

variable "policy_assignment_id" {
  description = "Policy assignment ID to create exemptions against."
  type        = string
  default     = ""
}

variable "private_dns_zone_links" {
  description = "Map of Private DNS zones to link to this spoke VNet."
  type = map(object({
    zone_name           = string
    resource_group_name = string
  }))
  default = {}
}

variable "resource_providers" {
  description = "Set of Azure resource provider namespaces to register in the spoke subscription."
  type        = set(string)
  default     = ["Microsoft.Cache", "Microsoft.Capacity", "Microsoft.Compute", "Microsoft.ContainerService", "Microsoft.EventHub", "Microsoft.KeyVault", "Microsoft.ManagedIdentity", "Microsoft.Network", "Microsoft.OperationalInsights", "Microsoft.OperationsManagement", "Microsoft.Resources", "Microsoft.Sql", "Microsoft.Storage"]
}

variable "root_id" {
  description = "Root Management Group ID used as naming prefix (e.g. 'isv')."
  type        = string
}

variable "subnets" {
  description = "Subnet definitions keyed by logical function (e.g. 'aks', 'pep', 'jmp', 'pls')."
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
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "uami_dns_zone_names" {
  description = "Set of Private DNS Zone names for automatic Private DNS Zone Contributor role assignment. Set to [] to skip."
  type        = set(string)
  default     = ["privatelink.blob.core.windows.net", "privatelink.database.windows.net", "privatelink.eventgrid.azure.net", "privatelink.fabric.microsoft.com", "privatelink.file.core.windows.net", "privatelink.queue.core.windows.net", "privatelink.servicebus.windows.net", "privatelink.table.core.windows.net", "privatelink.vaultcore.azure.net"]
}

variable "uami_dns_zone_resource_group_name" {
  description = "Resource Group name where Private DNS Zones are deployed (hub/connectivity). Required when deploy_managed_identity = true and uami_dns_zone_names is non-empty."
  type        = string
  default     = null
}

variable "uami_dns_zone_scopes" {
  description = "Additional DNS zone scopes (zone name -> full ARM resource ID). Merged with auto-computed scopes from uami_dns_zone_names."
  type        = map(string)
  default     = {}
}

variable "uami_name" {
  description = "Override name for the UAMI. Auto: {prefix}idtyc{client}{instance}."
  type        = string
  default     = null
}

variable "uami_network_contributor_subnet_key" {
  description = "Subnet key to assign Network Contributor role to the UAMI. Null to skip."
  type        = string
  default     = "aks"
}

variable "uami_resource_group_name" {
  description = "Override name for the UAMI resource group. Auto: {prefix}rgc{client}aksnodes{instance}."
  type        = string
  default     = null
}

variable "udr_subnet_keys" {
  description = "Subnet keys receiving the UDR association."
  type        = list(string)
  default     = ["aks", "jmp"]
}

variable "use_remote_gateways" {
  description = "Use remote gateways on spoke side."
  type        = bool
  default     = true
}

