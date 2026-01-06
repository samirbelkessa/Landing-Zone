################################################################################
# Root Intermediate Management Group
# This sits under the Tenant Root Group and serves as the organization root
################################################################################

resource "azurerm_management_group" "root" {
  name                       = local.mg_names.root
  display_name               = local.mg_display_names.root
  parent_management_group_id = local.root_parent_management_group_id

  timeouts {
    create = var.timeouts.create
    read   = var.timeouts.read
    update = var.timeouts.update
    delete = var.timeouts.delete
  }

  lifecycle {
    prevent_destroy = false
  }
}

################################################################################
# Platform Management Group
# Contains all platform-related resources: Management, Connectivity, Identity
################################################################################

resource "azurerm_management_group" "platform" {
  count = var.deploy_platform_mg ? 1 : 0

  name                       = local.mg_names.platform
  display_name               = local.mg_display_names.platform
  parent_management_group_id = azurerm_management_group.root.id

  timeouts {
    create = var.timeouts.create
    read   = var.timeouts.read
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}

################################################################################
# Platform Children - Management Subscription
# Contains Log Analytics, Automation Account, Defender for Cloud, Sentinel
################################################################################

resource "azurerm_management_group" "management" {
  count = local.deploy_management ? 1 : 0

  name                       = local.mg_names.management
  display_name               = local.mg_display_names.management
  parent_management_group_id = azurerm_management_group.platform[0].id

  timeouts {
    create = var.timeouts.create
    read   = var.timeouts.read
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}

################################################################################
# Platform Children - Connectivity Subscription
# Contains Hub VNet, Azure Firewall, VPN/ExpressRoute Gateways, Bastion
################################################################################

resource "azurerm_management_group" "connectivity" {
  count = local.deploy_connectivity ? 1 : 0

  name                       = local.mg_names.connectivity
  display_name               = local.mg_display_names.connectivity
  parent_management_group_id = azurerm_management_group.platform[0].id

  timeouts {
    create = var.timeouts.create
    read   = var.timeouts.read
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}

################################################################################
# Platform Children - Identity Subscription
# Contains Domain Controllers, Azure AD DS, Identity-related services
################################################################################

resource "azurerm_management_group" "identity" {
  count = local.deploy_identity ? 1 : 0

  name                       = local.mg_names.identity
  display_name               = local.mg_display_names.identity
  parent_management_group_id = azurerm_management_group.platform[0].id

  timeouts {
    create = var.timeouts.create
    read   = var.timeouts.read
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}

################################################################################
# Custom Platform Children
# Additional platform-level management groups defined by user
################################################################################

resource "azurerm_management_group" "custom_platform" {
  for_each = var.deploy_platform_mg ? var.custom_platform_children : {}

  name                       = "${var.root_id}-${each.key}"
  display_name               = each.value.display_name
  parent_management_group_id = azurerm_management_group.platform[0].id

  timeouts {
    create = var.timeouts.create
    read   = var.timeouts.read
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}

################################################################################
# Landing Zones Management Group
# Parent for all application landing zones
################################################################################

resource "azurerm_management_group" "landing_zones" {
  count = var.deploy_landing_zones_mg ? 1 : 0

  name                       = local.mg_names.landing_zones
  display_name               = local.mg_display_names.landing_zones
  parent_management_group_id = azurerm_management_group.root.id

  timeouts {
    create = var.timeouts.create
    read   = var.timeouts.read
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}

################################################################################
# Corp Landing Zones - With Prod/NonProd Separation
# For internal/corporate workloads without public endpoints
# Policies: DENY public IPs, Private Endpoints mandatory
################################################################################

resource "azurerm_management_group" "corp_prod" {
  count = local.deploy_corp_prod ? 1 : 0

  name                       = local.mg_names.corp_prod
  display_name               = local.mg_display_names.corp_prod
  parent_management_group_id = azurerm_management_group.landing_zones[0].id

  timeouts {
    create = var.timeouts.create
    read   = var.timeouts.read
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}

resource "azurerm_management_group" "corp_nonprod" {
  count = local.deploy_corp_nonprod ? 1 : 0

  name                       = local.mg_names.corp_nonprod
  display_name               = local.mg_display_names.corp_nonprod
  parent_management_group_id = azurerm_management_group.landing_zones[0].id

  timeouts {
    create = var.timeouts.create
    read   = var.timeouts.read
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}

################################################################################
# Corp Landing Zone - Single (when prod/nonprod separation disabled)
################################################################################

resource "azurerm_management_group" "corp" {
  count = local.deploy_corp_single ? 1 : 0

  name                       = local.mg_names.corp
  display_name               = local.mg_display_names.corp
  parent_management_group_id = azurerm_management_group.landing_zones[0].id

  timeouts {
    create = var.timeouts.create
    read   = var.timeouts.read
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}

################################################################################
# Online Landing Zones - With Prod/NonProd Separation
# For internet-facing workloads
# Policies: WAF mandatory, HTTPS enforced, TLS 1.2 minimum
################################################################################

resource "azurerm_management_group" "online_prod" {
  count = local.deploy_online_prod ? 1 : 0

  name                       = local.mg_names.online_prod
  display_name               = local.mg_display_names.online_prod
  parent_management_group_id = azurerm_management_group.landing_zones[0].id

  timeouts {
    create = var.timeouts.create
    read   = var.timeouts.read
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}

resource "azurerm_management_group" "online_nonprod" {
  count = local.deploy_online_nonprod ? 1 : 0

  name                       = local.mg_names.online_nonprod
  display_name               = local.mg_display_names.online_nonprod
  parent_management_group_id = azurerm_management_group.landing_zones[0].id

  timeouts {
    create = var.timeouts.create
    read   = var.timeouts.read
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}

################################################################################
# Online Landing Zone - Single (when prod/nonprod separation disabled)
################################################################################

resource "azurerm_management_group" "online" {
  count = local.deploy_online_single ? 1 : 0

  name                       = local.mg_names.online
  display_name               = local.mg_display_names.online
  parent_management_group_id = azurerm_management_group.landing_zones[0].id

  timeouts {
    create = var.timeouts.create
    read   = var.timeouts.read
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}

################################################################################
# Sandbox Management Group
# For POC, experimentation, and learning
# Policies: Audit-only, limited SKUs, mandatory Expiration tag
################################################################################

resource "azurerm_management_group" "sandbox" {
  count = local.deploy_sandbox ? 1 : 0

  name                       = local.mg_names.sandbox
  display_name               = local.mg_display_names.sandbox
  parent_management_group_id = azurerm_management_group.landing_zones[0].id

  timeouts {
    create = var.timeouts.create
    read   = var.timeouts.read
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}

################################################################################
# Custom Landing Zone Children
# Additional landing zone management groups defined by user
################################################################################

resource "azurerm_management_group" "custom_landing_zone" {
  for_each = var.deploy_landing_zones_mg ? var.custom_landing_zone_children : {}

  name                       = "${var.root_id}-${each.key}"
  display_name               = each.value.display_name
  parent_management_group_id = azurerm_management_group.landing_zones[0].id

  timeouts {
    create = var.timeouts.create
    read   = var.timeouts.read
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}

################################################################################
# Decommissioned Management Group
# For subscriptions/resources pending deletion
# Typically has restrictive policies preventing new deployments
################################################################################

resource "azurerm_management_group" "decommissioned" {
  count = var.deploy_decommissioned_mg ? 1 : 0

  name                       = local.mg_names.decommissioned
  display_name               = local.mg_display_names.decommissioned
  parent_management_group_id = azurerm_management_group.root.id

  timeouts {
    create = var.timeouts.create
    read   = var.timeouts.read
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}

################################################################################
# Subscription Associations
# Places subscriptions into their designated management groups
################################################################################

resource "azurerm_management_group_subscription_association" "associations" {
  for_each = local.subscription_associations_map

  management_group_id = local.mg_key_to_id[each.value.mg_key]
  subscription_id     = "/subscriptions/${each.value.subscription_id}"
}
