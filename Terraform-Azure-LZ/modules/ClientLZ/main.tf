resource "azurerm_resource_provider_registration" "spoke" {
  provider = azurerm.spoke

  name     = each.value
  for_each = var.enable_resource_provider_registration ? var.resource_providers : toset([])
}

resource "azurerm_resource_group" "additional" {
  provider = azurerm.spoke

  tags     = merge(local.all_tags, each.value.tags)
  name     = each.value.name
  location = coalesce(each.value.location, var.location)
  for_each = var.additional_resource_groups
}

resource "azurerm_firewall_policy_rule_collection_group" "application" {
  provider = azurerm.hub

  priority           = var.firewall_app_rule_priority
  name               = local.fw_app_collection_name
  firewall_policy_id = var.firewall_policy_id
  count              = var.enable_hub_peering && var.deploy_firewall_rules && var.deploy_shared_firewall_app_rules ? 1 : 0

  dynamic "application_rule_collection" {
    for_each = length(var.firewall_app_rules) > 0 ? [1] : []
    content {
      priority = 100
      name     = "${var.client_name}ApplicationRuleCollection"
      action   = "Allow"

      dynamic "rule" {
        for_each = var.firewall_app_rules
        content {
          name              = rule.value.name
          source_addresses  = rule.value.source_addresses
          destination_fqdns = rule.value.destination_fqdns

          dynamic "protocols" {
            for_each = rule.value.protocols
            content {
              type = protocols.value.type
              port = protocols.value.port
            }
          }
        }
      }
    }
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "network" {
  provider = azurerm.hub

  priority           = var.firewall_network_rule_priority
  name               = local.fw_net_collection_name
  firewall_policy_id = var.firewall_policy_id
  count              = var.enable_hub_peering && var.deploy_firewall_rules && length(var.firewall_network_rules) > 0 ? 1 : 0

  network_rule_collection {
    priority = 100
    name     = "${upper(var.environment_key)}NetworkRuleCollection"
    action   = "Allow"

    dynamic "rule" {
      for_each = var.firewall_network_rules
      content {
        name                  = rule.value.name
        source_addresses      = rule.value.source_addresses
        destination_addresses = rule.value.destination_addresses
        destination_ports     = rule.value.destination_ports
        protocols             = rule.value.protocols
      }
    }
  }
}

resource "azurerm_resource_group" "uami" {
  provider = azurerm.spoke

  tags     = local.all_tags
  name     = local.uami_rg_name
  location = var.location
  count    = var.deploy_managed_identity ? 1 : 0
}

resource "azurerm_user_assigned_identity" "this" {
  provider = azurerm.spoke

  tags                = local.all_tags
  resource_group_name = azurerm_resource_group.uami[0].name
  name                = local.uami_name
  location            = var.location
  count               = var.deploy_managed_identity ? 1 : 0
}

resource "azurerm_role_assignment" "uami_network_contributor" {
  provider = azurerm.spoke

  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.this[0].principal_id
  count                = var.deploy_managed_identity && var.uami_network_contributor_subnet_key != null ? 1 : 0
  scope                = module.spoke.subnet_ids[var.uami_network_contributor_subnet_key]

  depends_on = [
    module.spoke,
  ]
}

resource "azurerm_role_assignment" "uami_dns_zone_contributor" {
  provider = azurerm.hub

  scope                = each.value
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.this[0].principal_id
  for_each             = var.deploy_managed_identity ? local.merged_dns_zone_scopes : {}
}

resource "azurerm_monitor_diagnostic_setting" "vnet_primary" {
  provider = azurerm.spoke

  target_resource_id         = module.spoke.vnet_id
  name                       = "vNetLogsToLogAnalytics"
  log_analytics_workspace_id = var.monitor_log_analytics_workspace_id
  count                      = var.deploy_vnet_monitor_diagnostics ? 1 : 0

  depends_on = [
    module.spoke,
  ]

  enabled_log {
    category = "VMProtectionAlerts"
  }

  enabled_metric {
    category = "AllMetrics"
  }

  lifecycle {
    ignore_changes = [
      log_analytics_destination_type,
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "vnet_additional" {
  provider = azurerm.spoke

  target_resource_id         = module.spoke.additional_vnet_ids[each.key]
  name                       = "vNetLogsToLogAnalytics"
  log_analytics_workspace_id = var.monitor_log_analytics_workspace_id
  for_each                   = var.deploy_additional_vnet_monitor_diagnostics ? var.additional_vnets : {}

  depends_on = [
    module.spoke,
  ]

  enabled_log {
    category = "VMProtectionAlerts"
  }

  enabled_metric {
    category = "AllMetrics"
  }

  lifecycle {
    ignore_changes = [
      log_analytics_destination_type,
    ]
  }
}

resource "azurerm_resource_policy_exemption" "vnet_primary" {
  resource_id          = module.spoke.vnet_id
  policy_assignment_id = var.policy_assignment_id
  name                 = "exempt-vnet-${var.environment_key}-${var.client_prefix}-diag-terraform"
  exemption_category   = "Mitigated"
  display_name         = "VNet Spoke ${title(var.environment_key)} ${upper(var.client_prefix)} diag managed by Terraform"
  description          = "Client requires name vNetLogsToLogAnalytics."
  count                = var.deploy_policy_exemptions ? 1 : 0

  depends_on = [
    module.spoke,
  ]
}

resource "azurerm_resource_policy_exemption" "vnet_additional" {
  resource_id          = module.spoke.additional_vnet_ids[each.key]
  policy_assignment_id = var.policy_assignment_id
  name                 = "exempt-vnet-${var.environment_key}-${each.key}-diag-terraform"
  for_each             = var.deploy_policy_exemptions ? var.additional_vnets : {}
  exemption_category   = "Mitigated"
  display_name         = "VNet Spoke ${title(var.environment_key)} ${upper(each.key)} diag managed by Terraform"
  description          = "Client requires name vNetLogsToLogAnalytics."

  depends_on = [
    module.spoke,
  ]
}

data "azurerm_client_config" "hub" {
  provider = azurerm.hub

  count = var.deploy_managed_identity && var.uami_dns_zone_resource_group_name != null ? 1 : 0
}

module "spoke" {
  source = "git::https://github.com/Experteq-MSP/terraform-modules//L02-Spoke?ref=main"


  workload                         = var.client_prefix
  use_remote_gateways              = var.use_remote_gateways
  udr_subnet_keys                  = var.udr_subnet_keys
  tags                             = local.all_tags
  subnets                          = var.subnets
  root_id                          = var.root_id
  private_dns_zone_links           = var.private_dns_zone_links
  nsg_rules                        = local.merged_nsg_rules
  log_analytics_workspace_region   = var.log_analytics_workspace_region
  log_analytics_workspace_id       = var.log_analytics_workspace_id
  log_analytics_workspace_guid     = var.log_analytics_workspace_guid
  location                         = var.location
  instance                         = var.instance
  hub_vnet_name                    = var.hub_vnet_name
  hub_vnet_id                      = var.hub_vnet_id
  hub_resource_group_name          = var.hub_resource_group_name
  flow_logs_storage_account_id     = var.flow_logs_storage_account_id
  flow_logs_retention_days         = var.flow_logs_retention_days
  firewall_private_ip              = var.firewall_private_ip
  environment                      = var.environment_name
  enable_vnet_flow_logs            = var.enable_vnet_flow_logs
  enable_vnet_diagnostics          = var.enable_vnet_diagnostics
  enable_traffic_analytics         = var.enable_traffic_analytics
  enable_nsg_diagnostics           = var.enable_nsg_diagnostics
  enable_delete_lock               = var.enable_delete_lock
  enable_baseline_nsg_rules        = var.enable_baseline_nsg_rules
  disable_bgp_route_propagation    = var.disable_bgp_route_propagation
  custom_vnet_name                 = var.custom_vnet_name
  custom_route_table_name          = var.custom_route_table_name
  custom_resource_group_name       = var.custom_resource_group_name
  custom_peering_name_spoke_to_hub = var.custom_peering_name_spoke_to_hub
  custom_peering_name_hub_to_spoke = var.custom_peering_name_hub_to_spoke
  custom_nsg_names                 = var.custom_nsg_names
  custom_default_route_name        = var.custom_default_route_name
  bastion_target_subnet_keys       = var.bastion_target_subnet_keys
  bastion_subnet_prefix            = var.bastion_subnet_prefix
  allow_gateway_transit            = var.allow_gateway_transit
  address_space                    = var.address_space
  additional_vnets                 = var.additional_vnets
  additional_routes                = var.additional_routes
  enable_hub_peering               = var.enable_hub_peering
  depends_on = [
    azurerm_resource_provider_registration.spoke,
  ]

  providers = {
    azurerm.spoke = azurerm.spoke
    azurerm.hub   = azurerm.hub
  }

}

