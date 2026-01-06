################################################################################
# Root Management Group Outputs
################################################################################

output "root_mg_id" {
  description = "Resource ID of the root intermediate management group."
  value       = azurerm_management_group.root.id
}

output "root_mg_name" {
  description = "Name of the root intermediate management group."
  value       = azurerm_management_group.root.name
}

################################################################################
# Platform Management Group Outputs
################################################################################

output "platform_mg_id" {
  description = "Resource ID of the Platform management group."
  value       = var.deploy_platform_mg ? azurerm_management_group.platform[0].id : null
}

output "platform_mg_name" {
  description = "Name of the Platform management group."
  value       = var.deploy_platform_mg ? azurerm_management_group.platform[0].name : null
}

output "management_mg_id" {
  description = "Resource ID of the Management management group."
  value       = local.deploy_management ? azurerm_management_group.management[0].id : null
}

output "management_mg_name" {
  description = "Name of the Management management group."
  value       = local.deploy_management ? azurerm_management_group.management[0].name : null
}

output "connectivity_mg_id" {
  description = "Resource ID of the Connectivity management group."
  value       = local.deploy_connectivity ? azurerm_management_group.connectivity[0].id : null
}

output "connectivity_mg_name" {
  description = "Name of the Connectivity management group."
  value       = local.deploy_connectivity ? azurerm_management_group.connectivity[0].name : null
}

output "identity_mg_id" {
  description = "Resource ID of the Identity management group."
  value       = local.deploy_identity ? azurerm_management_group.identity[0].id : null
}

output "identity_mg_name" {
  description = "Name of the Identity management group."
  value       = local.deploy_identity ? azurerm_management_group.identity[0].name : null
}

################################################################################
# Landing Zones Management Group Outputs
################################################################################

output "landing_zones_mg_id" {
  description = "Resource ID of the Landing Zones management group."
  value       = var.deploy_landing_zones_mg ? azurerm_management_group.landing_zones[0].id : null
}

output "landing_zones_mg_name" {
  description = "Name of the Landing Zones management group."
  value       = var.deploy_landing_zones_mg ? azurerm_management_group.landing_zones[0].name : null
}

################################################################################
# Corp Landing Zone Outputs
################################################################################

output "corp_prod_mg_id" {
  description = "Resource ID of the Corp-Prod management group."
  value       = local.deploy_corp_prod ? azurerm_management_group.corp_prod[0].id : null
}

output "corp_prod_mg_name" {
  description = "Name of the Corp-Prod management group."
  value       = local.deploy_corp_prod ? azurerm_management_group.corp_prod[0].name : null
}

output "corp_nonprod_mg_id" {
  description = "Resource ID of the Corp-NonProd management group."
  value       = local.deploy_corp_nonprod ? azurerm_management_group.corp_nonprod[0].id : null
}

output "corp_nonprod_mg_name" {
  description = "Name of the Corp-NonProd management group."
  value       = local.deploy_corp_nonprod ? azurerm_management_group.corp_nonprod[0].name : null
}

output "corp_mg_id" {
  description = "Resource ID of the Corp management group (when prod/nonprod separation is disabled)."
  value       = local.deploy_corp_single ? azurerm_management_group.corp[0].id : null
}

output "corp_mg_name" {
  description = "Name of the Corp management group (when prod/nonprod separation is disabled)."
  value       = local.deploy_corp_single ? azurerm_management_group.corp[0].name : null
}

################################################################################
# Online Landing Zone Outputs
################################################################################

output "online_prod_mg_id" {
  description = "Resource ID of the Online-Prod management group."
  value       = local.deploy_online_prod ? azurerm_management_group.online_prod[0].id : null
}

output "online_prod_mg_name" {
  description = "Name of the Online-Prod management group."
  value       = local.deploy_online_prod ? azurerm_management_group.online_prod[0].name : null
}

output "online_nonprod_mg_id" {
  description = "Resource ID of the Online-NonProd management group."
  value       = local.deploy_online_nonprod ? azurerm_management_group.online_nonprod[0].id : null
}

output "online_nonprod_mg_name" {
  description = "Name of the Online-NonProd management group."
  value       = local.deploy_online_nonprod ? azurerm_management_group.online_nonprod[0].name : null
}

output "online_mg_id" {
  description = "Resource ID of the Online management group (when prod/nonprod separation is disabled)."
  value       = local.deploy_online_single ? azurerm_management_group.online[0].id : null
}

output "online_mg_name" {
  description = "Name of the Online management group (when prod/nonprod separation is disabled)."
  value       = local.deploy_online_single ? azurerm_management_group.online[0].name : null
}

################################################################################
# Sandbox Management Group Outputs
################################################################################

output "sandbox_mg_id" {
  description = "Resource ID of the Sandbox management group."
  value       = local.deploy_sandbox ? azurerm_management_group.sandbox[0].id : null
}

output "sandbox_mg_name" {
  description = "Name of the Sandbox management group."
  value       = local.deploy_sandbox ? azurerm_management_group.sandbox[0].name : null
}

################################################################################
# Decommissioned Management Group Outputs
################################################################################

output "decommissioned_mg_id" {
  description = "Resource ID of the Decommissioned management group."
  value       = var.deploy_decommissioned_mg ? azurerm_management_group.decommissioned[0].id : null
}

output "decommissioned_mg_name" {
  description = "Name of the Decommissioned management group."
  value       = var.deploy_decommissioned_mg ? azurerm_management_group.decommissioned[0].name : null
}

################################################################################
# Custom Management Group Outputs
################################################################################

output "custom_platform_mg_ids" {
  description = "Map of custom Platform child management group IDs."
  value = {
    for k, v in azurerm_management_group.custom_platform : k => v.id
  }
}

output "custom_landing_zone_mg_ids" {
  description = "Map of custom Landing Zone child management group IDs."
  value = {
    for k, v in azurerm_management_group.custom_landing_zone : k => v.id
  }
}

################################################################################
# Aggregated Outputs - For Easy Reference
################################################################################

output "all_mg_ids" {
  description = "Map of all management group names to their resource IDs."
  value = {
    root           = azurerm_management_group.root.id
    platform       = var.deploy_platform_mg ? azurerm_management_group.platform[0].id : null
    management     = local.deploy_management ? azurerm_management_group.management[0].id : null
    connectivity   = local.deploy_connectivity ? azurerm_management_group.connectivity[0].id : null
    identity       = local.deploy_identity ? azurerm_management_group.identity[0].id : null
    landing_zones  = var.deploy_landing_zones_mg ? azurerm_management_group.landing_zones[0].id : null
    corp_prod      = local.deploy_corp_prod ? azurerm_management_group.corp_prod[0].id : null
    corp_nonprod   = local.deploy_corp_nonprod ? azurerm_management_group.corp_nonprod[0].id : null
    corp           = local.deploy_corp_single ? azurerm_management_group.corp[0].id : null
    online_prod    = local.deploy_online_prod ? azurerm_management_group.online_prod[0].id : null
    online_nonprod = local.deploy_online_nonprod ? azurerm_management_group.online_nonprod[0].id : null
    online         = local.deploy_online_single ? azurerm_management_group.online[0].id : null
    sandbox        = local.deploy_sandbox ? azurerm_management_group.sandbox[0].id : null
    decommissioned = var.deploy_decommissioned_mg ? azurerm_management_group.decommissioned[0].id : null
  }
}

output "all_mg_names" {
  description = "Map of all management group logical names to their Azure names."
  value = {
    root           = azurerm_management_group.root.name
    platform       = var.deploy_platform_mg ? azurerm_management_group.platform[0].name : null
    management     = local.deploy_management ? azurerm_management_group.management[0].name : null
    connectivity   = local.deploy_connectivity ? azurerm_management_group.connectivity[0].name : null
    identity       = local.deploy_identity ? azurerm_management_group.identity[0].name : null
    landing_zones  = var.deploy_landing_zones_mg ? azurerm_management_group.landing_zones[0].name : null
    corp_prod      = local.deploy_corp_prod ? azurerm_management_group.corp_prod[0].name : null
    corp_nonprod   = local.deploy_corp_nonprod ? azurerm_management_group.corp_nonprod[0].name : null
    corp           = local.deploy_corp_single ? azurerm_management_group.corp[0].name : null
    online_prod    = local.deploy_online_prod ? azurerm_management_group.online_prod[0].name : null
    online_nonprod = local.deploy_online_nonprod ? azurerm_management_group.online_nonprod[0].name : null
    online         = local.deploy_online_single ? azurerm_management_group.online[0].name : null
    sandbox        = local.deploy_sandbox ? azurerm_management_group.sandbox[0].name : null
    decommissioned = var.deploy_decommissioned_mg ? azurerm_management_group.decommissioned[0].name : null
  }
}

################################################################################
# Landing Zone Archetype Outputs - For Policy Assignment
################################################################################

output "archetype_mg_ids" {
  description = "Map of landing zone archetypes to their management group IDs for policy assignment."
  value = {
    corp_prod      = local.deploy_corp_prod ? azurerm_management_group.corp_prod[0].id : null
    corp_nonprod   = local.deploy_corp_nonprod ? azurerm_management_group.corp_nonprod[0].id : null
    online_prod    = local.deploy_online_prod ? azurerm_management_group.online_prod[0].id : null
    online_nonprod = local.deploy_online_nonprod ? azurerm_management_group.online_nonprod[0].id : null
    sandbox        = local.deploy_sandbox ? azurerm_management_group.sandbox[0].id : null
  }
}

################################################################################
# Hierarchy Output - Full Structure Visualization
################################################################################

output "hierarchy" {
  description = "Full management group hierarchy structure for documentation."
  value = {
    "${var.root_name} (${local.mg_names.root})" = {
      "Platform (${local.mg_names.platform})" = var.deploy_platform_mg ? {
        "Management (${local.mg_names.management})"   = local.deploy_management ? {} : null
        "Connectivity (${local.mg_names.connectivity})" = local.deploy_connectivity ? {} : null
        "Identity (${local.mg_names.identity})"       = local.deploy_identity ? {} : null
      } : null
      "Landing Zones (${local.mg_names.landing_zones})" = var.deploy_landing_zones_mg ? {
        "Corp-Prod (${local.mg_names.corp_prod})"         = local.deploy_corp_prod ? {} : null
        "Corp-NonProd (${local.mg_names.corp_nonprod})"   = local.deploy_corp_nonprod ? {} : null
        "Corp (${local.mg_names.corp})"                   = local.deploy_corp_single ? {} : null
        "Online-Prod (${local.mg_names.online_prod})"     = local.deploy_online_prod ? {} : null
        "Online-NonProd (${local.mg_names.online_nonprod})" = local.deploy_online_nonprod ? {} : null
        "Online (${local.mg_names.online})"               = local.deploy_online_single ? {} : null
        "Sandbox (${local.mg_names.sandbox})"             = local.deploy_sandbox ? {} : null
      } : null
      "Decommissioned (${local.mg_names.decommissioned})" = var.deploy_decommissioned_mg ? {} : null
    }
  }
}
