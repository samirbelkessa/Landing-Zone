# =============================================================================
# OUTPUTS.TF - Orchestrator Outputs
# =============================================================================
# Orchestrator: 06-landing-zones
# Purpose: Expose Landing Zone resources for downstream consumption
# Modes: Greenfield (create subscriptions) or Brownfield (existing subscriptions)
# =============================================================================

# =============================================================================
# DEPLOYMENT SUMMARY
# =============================================================================

output "deployment_summary" {
  description = "Summary of Landing Zones deployment."
  value = {
    total_landing_zones  = local.total_landing_zones
    greenfield_count     = local.greenfield_count
    brownfield_count     = local.brownfield_count
    total_subnets        = local.total_subnets
    total_dns_zone_links = local.total_dns_zone_links
  }
}

# =============================================================================
# LANDING ZONE SUMMARY
# =============================================================================

output "landing_zones" {
  description = "Summary of all deployed Landing Zones with key attributes."
  value = {
    for lz_key, lz in local.landing_zones_processed : lz_key => {
      mode                = lz.is_greenfield ? "Greenfield" : "Brownfield"
      subscription_id     = lz.is_greenfield ? try(module.lz_vending[lz_key].subscription_id, "pending") : lz.subscription_id
      management_group_id = lz.management_group_id
      archetype           = lz.archetype
      location            = lz.location
      vnet_name           = lz.vnet_name
      address_space       = lz.address_space
    }
  }
}

# =============================================================================
# SUBSCRIPTION OUTPUTS
# =============================================================================

output "subscription_ids" {
  description = "Map of Landing Zone names to their subscription IDs (includes newly created for Greenfield)."
  value = {
    for lz_key, lz in local.landing_zones_processed : lz_key => (
      lz.is_greenfield
      ? try(module.lz_vending[lz_key].subscription_id, null)
      : lz.subscription_id
    )
  }
}

output "greenfield_subscriptions" {
  description = "Details of newly created subscriptions (Greenfield mode only)."
  value = {
    for lz_key, lz in local.landing_zones_processed : lz_key => {
      subscription_id           = try(module.lz_vending[lz_key].subscription_id, null)
      subscription_resource_id  = try(module.lz_vending[lz_key].subscription_resource_id, null)
      subscription_alias        = lz.subscription_alias
      subscription_display_name = lz.subscription_display_name
      subscription_workload     = lz.subscription_workload
      management_group_id       = lz.management_group_id
    } if lz.is_greenfield
  }
}

output "brownfield_subscriptions" {
  description = "Details of existing subscriptions used (Brownfield mode only)."
  value = {
    for lz_key, lz in local.landing_zones_processed : lz_key => {
      subscription_id     = lz.subscription_id
      management_group_id = lz.management_group_id
      archetype           = lz.archetype
    } if !lz.is_greenfield
  }
}

output "subscription_management_groups" {
  description = "Map of Landing Zone names to their Management Group placement."
  value = {
    for lz_key, lz in local.landing_zones_processed : lz_key => {
      subscription_id     = lz.is_greenfield ? try(module.lz_vending[lz_key].subscription_id, null) : lz.subscription_id
      management_group_id = lz.management_group_id
      archetype           = lz.archetype
      mode                = lz.is_greenfield ? "Greenfield" : "Brownfield"
    }
  }
}

# =============================================================================
# NETWORKING OUTPUTS
# =============================================================================

output "virtual_network_ids" {
  description = "Map of Landing Zone names to their VNet resource IDs."
  value = {
    for lz_key, module_output in module.lz_vending : lz_key => try(
      module_output.virtual_network_resource_ids["primary"],
      null
    )
  }
}

output "virtual_network_names" {
  description = "Map of Landing Zone names to their VNet names."
  value = {
    for lz_key, lz in local.landing_zones_processed : lz_key => lz.vnet_name
  }
}

output "virtual_network_address_spaces" {
  description = "Map of Landing Zone names to their VNet address spaces."
  value = {
    for lz_key, lz in local.landing_zones_processed : lz_key => lz.address_space
  }
}

output "subnet_ids" {
  description = "Map of Landing Zone names to their subnet resource IDs."
  value = {
    for lz_key, module_output in module.lz_vending : lz_key => try(
      module_output.virtual_network_subnet_resource_ids["primary"],
      {}
    )
  }
}

output "spoke_network_config" {
  description = "Detailed network configuration for each Spoke VNet (for workload deployment)."
  value = {
    for lz_key, lz in local.landing_zones_processed : lz_key => {
      vnet_id             = try(module.lz_vending[lz_key].virtual_network_resource_ids["primary"], null)
      vnet_name           = lz.vnet_name
      address_space       = lz.address_space
      location            = lz.location
      resource_group_name = lz.network_resource_group
      dns_servers         = lz.dns_servers
      hub_peering_enabled = lz.enable_hub_peering
      hub_vnet_id         = lz.hub_vnet_id
      subnets = {
        for subnet_key, subnet in lz.subnets : subnet_key => {
          id             = try(module.lz_vending[lz_key].virtual_network_subnet_resource_ids["primary"][subnet_key], null)
          name           = subnet.name
          address_prefix = subnet.address_prefixes[0]
          route_table_id = subnet.route_table_id
        }
      }
    }
  }
}

# =============================================================================
# RESOURCE GROUP OUTPUTS
# =============================================================================

output "resource_group_ids" {
  description = "Map of Landing Zone names to their Resource Group IDs."
  value = {
    for lz_key, module_output in module.lz_vending : lz_key => try(
      module_output.resource_group_resource_ids,
      {}
    )
  }
}

output "network_resource_groups" {
  description = "Map of Landing Zone names to their network Resource Group names."
  value = {
    for lz_key, lz in local.landing_zones_processed : lz_key => lz.network_resource_group
  }
}

# =============================================================================
# PRIVATE DNS ZONE LINKS
# =============================================================================

output "private_dns_zone_link_ids" {
  description = "Map of Private DNS Zone VNet link resource IDs."
  value = {
    for link_key, link in azurerm_private_dns_zone_virtual_network_link.spoke_links : link_key => link.id
  }
}

output "private_dns_zones_linked" {
  description = "List of Private DNS Zone names linked to Spoke VNets."
  value       = local.private_dns_zones_to_link
}

# =============================================================================
# RBAC & IDENTITY OUTPUTS
# =============================================================================

output "role_assignment_ids" {
  description = "Map of Landing Zone names to their role assignment IDs."
  value = {
    for lz_key, module_output in module.lz_vending : lz_key => try(
      module_output.role_assignment_resource_ids,
      {}
    )
  }
}

# =============================================================================
# BUDGET OUTPUTS
# =============================================================================

output "budget_ids" {
  description = "Map of Landing Zone names to their budget resource IDs."
  value = {
    for lz_key, module_output in module.lz_vending : lz_key => try(
      module_output.budget_resource_ids,
      {}
    )
  }
}

# =============================================================================
# CONSUMPTION OUTPUTS (For Workload Teams)
# =============================================================================

output "workload_deployment_info" {
  description = <<-EOT
    Information needed by workload teams to deploy resources in their Landing Zone.
    Provides subscription, networking, and configuration details.
  EOT
  value = {
    for lz_key, lz in local.landing_zones_processed : lz_key => {
      # Provisioning mode
      mode = lz.is_greenfield ? "Greenfield" : "Brownfield"

      # Subscription info
      subscription_id = lz.is_greenfield ? try(module.lz_vending[lz_key].subscription_id, null) : lz.subscription_id
      tenant_id       = var.tenant_id

      # Primary VNet
      vnet = {
        id            = try(module.lz_vending[lz_key].virtual_network_resource_ids["primary"], null)
        name          = lz.vnet_name
        address_space = lz.address_space
      }

      # Subnets
      subnets = {
        for subnet_key, subnet in lz.subnets : subnet_key => {
          id     = try(module.lz_vending[lz_key].virtual_network_subnet_resource_ids["primary"][subnet_key], null)
          name   = subnet.name
          prefix = subnet.address_prefixes[0]
        }
      }

      # Resource Groups
      resource_groups = {
        for rg_key, rg in lz.resource_groups : rg_key => rg.name
      }

      # DNS Configuration
      dns_servers = lz.dns_servers

      # Diagnostics
      log_analytics_workspace_id = local.log_analytics_workspace_id

      # Location
      location = lz.location

      # Archetype (determines inherited policies)
      archetype = lz.archetype

      # Tags to apply
      required_tags = {
        Environment = lz.tags["Environment"]
        Application = lookup(lz.tags, "Application", null)
        Owner       = lookup(lz.tags, "Owner", null)
        CostCenter  = lookup(lz.tags, "CostCenter", null)
      }
    }
  }
}

# =============================================================================
# DEBUG OUTPUTS (Uncomment for troubleshooting)
# =============================================================================

# output "debug_landing_zones_processed" {
#   description = "DEBUG: Full processed Landing Zones configuration."
#   value       = local.landing_zones_processed
#   sensitive   = true
# }

# output "debug_hub_config" {
#   description = "DEBUG: Hub configuration per region."
#   value       = local.hub_config
# }

# output "debug_dns_zone_links" {
#   description = "DEBUG: Private DNS Zone link map."
#   value       = local.dns_zone_links
# }

# output "debug_greenfield_landing_zones" {
#   description = "DEBUG: Greenfield Landing Zones."
#   value       = local.greenfield_landing_zones
# }

# output "debug_brownfield_landing_zones" {
#   description = "DEBUG: Brownfield Landing Zones."
#   value       = local.brownfield_landing_zones
# }
