locals {
  all_nsg_rules = merge(
    { for k, v in local.baseline_bastion_rules : k => merge(v, { rule_name = k }) },
    { for k, v in local.baseline_common_rules : k => merge(v, { rule_name = k }) },
    { for k, v in local.baseline_deny_outbound_rules : k => merge(v, { rule_name = k }) },
    local.expanded_nsg_rules
  )

  baseline_bastion_rules = {
    for k in local.bastion_keys : "Bastion-InBound-${k}" => {
      nsg_key                      = k
      priority                     = 1003
      direction                    = "Inbound"
      access                       = "Allow"
      protocol                     = "Tcp"
      source_port_range            = "*"
      source_port_ranges           = null
      destination_port_range       = null
      destination_port_ranges      = ["22", "3389"]
      source_address_prefix        = var.bastion_subnet_prefix != "" ? var.bastion_subnet_prefix : "VirtualNetwork"
      source_address_prefixes      = null
      destination_address_prefix   = "VirtualNetwork"
      destination_address_prefixes = null
    }
  }

  baseline_common_rules = var.enable_baseline_nsg_rules ? merge([
    for k in local.nsg_keys : {
      "Allow-AzureLoadBalancer-InBound-${k}" = {
        nsg_key                      = k
        priority                     = 4095
        direction                    = "Inbound"
        access                       = "Allow"
        protocol                     = "*"
        source_port_range            = "*"
        source_port_ranges           = null
        destination_port_range       = "*"
        destination_port_ranges      = null
        source_address_prefix        = "AzureLoadBalancer"
        source_address_prefixes      = null
        destination_address_prefix   = "*"
        destination_address_prefixes = null
      }
      "Allow-VNet-OutBound-${k}" = {
        nsg_key                      = k
        priority                     = 4000
        direction                    = "Outbound"
        access                       = "Allow"
        protocol                     = "*"
        source_port_range            = "*"
        source_port_ranges           = null
        destination_port_range       = "*"
        destination_port_ranges      = null
        source_address_prefix        = "VirtualNetwork"
        source_address_prefixes      = null
        destination_address_prefix   = "VirtualNetwork"
        destination_address_prefixes = null
      }
    }
  ]...) : {}

  baseline_deny_outbound_rules = var.enable_baseline_nsg_rules ? merge([
    for k in local.non_udr_nsg_keys : {
      "Deny-All-OutBound-Override-${k}" = {
        nsg_key                      = k
        priority                     = 4096
        direction                    = "Outbound"
        access                       = "Deny"
        protocol                     = "*"
        source_port_range            = "*"
        source_port_ranges           = null
        destination_port_range       = "*"
        destination_port_ranges      = null
        source_address_prefix        = "*"
        source_address_prefixes      = null
        destination_address_prefix   = "*"
        destination_address_prefixes = null
      }
    }
  ]...) : {}

  bastion_keys = var.enable_baseline_nsg_rules ? [
    for k in var.bastion_target_subnet_keys : k
    if contains(local.nsg_keys, k)
  ] : []

  default_tags = {
    ManagedBy = "Terraform"
    Module    = "L02-spoke-virtual-network"
  }

  deploy_flow_logs = var.enable_vnet_flow_logs

  deploy_nsg_diagnostics = var.enable_nsg_diagnostics && var.log_analytics_workspace_id != ""

  deploy_vnet_diagnostics = var.enable_vnet_diagnostics && var.log_analytics_workspace_id != ""

  dns_servers = var.dns_servers != null ? var.dns_servers : (
    var.enable_hub_peering && var.firewall_private_ip != "" ? [var.firewall_private_ip] : []
  )

  env_code = lookup(local.env_codes, var.environment, "x")

  env_codes = {
    "Development" = "n"
    "Test"        = "n"
    "Staging"     = "n"
    "Production"  = "p"
  }

  expanded_nsg_rules = merge(
    # Rules WITH explicit nsg_key — keep as-is
    {
      for k, v in var.nsg_rules : k => merge(v, { rule_name = k })
      if v.nsg_key != null
    },
    # Rules WITHOUT nsg_key — expand to all NSGs
    merge([
      for nsg_key in local.nsg_keys : {
        for k, v in var.nsg_rules : "${k}-${nsg_key}" => merge(v, {
          nsg_key   = nsg_key
          rule_name = k
        })
        if v.nsg_key == null
      }
    ]...)
  )

  flow_log_name_primary = "${local.prefix}nwfl${var.workload}${var.instance}"

  flow_log_names_additional = {
    for key, _ in var.additional_vnets : key => "${local.prefix}nwfl${key}${var.instance}"
  }

  non_udr_nsg_keys = [for k in local.nsg_keys : k if !contains(var.udr_subnet_keys, k)]

  nsg_keys = var.nsg_subnet_keys != null ? var.nsg_subnet_keys : keys(var.subnets)

  nsg_names = {
    for key in local.nsg_keys : key => lookup(
      var.custom_nsg_names,
      key,
      "${local.prefix}nsgc${var.workload}${key}${var.instance}"
    )
  }

  peering_name_hub_to_spoke = var.enable_hub_peering ? coalesce(
    var.custom_peering_name_hub_to_spoke,
    "${var.hub_vnet_name}-to-${local.vnet_name}"
  ) : "unused"

  peering_name_spoke_to_hub = var.enable_hub_peering ? coalesce(
    var.custom_peering_name_spoke_to_hub,
    "${local.vnet_name}-to-${var.hub_vnet_name}"
  ) : "unused"

  prefix = "${var.root_id}${local.env_code}${local.region_code}2"

  region_code = var.location_short != null ? var.location_short : lookup(local.region_codes, var.location, "xxx")

  region_codes = {
    "australiaeast"      = "aea"
    "australiasoutheast" = "asa"
    "eastus"             = "eus"
    "eastus2"            = "eu2"
    "westus"             = "wus"
    "westus2"            = "wu2"
    "westeurope"         = "weu"
    "northeurope"        = "neu"
    "uksouth"            = "uks"
    "ukwest"             = "ukw"
    "southeastasia"      = "sea"
    "centralus"          = "cus"
    "francecentral"      = "frc"
    "francesouth"        = "frs"
    "canadacentral"      = "cac"
    "canadaeast"         = "cae"
    "japaneast"          = "jpe"
    "japanwest"          = "jpw"
  }

  resource_group_name = coalesce(
    var.custom_resource_group_name,
    "${local.prefix}rgc${var.workload}network${var.instance}"
  )

  route_table_name = coalesce(
    var.custom_route_table_name,
    "${local.prefix}rtcspoke${var.workload}${var.instance}"
  )

  subnet_names = {
    for key, subnet in var.subnets : key => coalesce(
      subnet.custom_name,
      "${local.prefix}subc${var.workload}${key}${var.instance}"
    )
  }

  tags = merge(local.default_tags, var.tags)

  udr_association_keys = toset(var.udr_subnet_keys)

  vnet_name = coalesce(
    var.custom_vnet_name,
    "${local.prefix}vnetcspoke${var.workload}${var.instance}"
  )

}
