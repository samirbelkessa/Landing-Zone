################################################################################
# Local Values - Naming and Structure
################################################################################

locals {
  # Root parent management group ID - normalize to full resource ID format
  root_parent_management_group_id = can(regex("^/providers/Microsoft.Management/managementGroups/", var.root_parent_id)) ? var.root_parent_id : "/providers/Microsoft.Management/managementGroups/${var.root_parent_id}"

  # Management Group naming convention following CAF
  mg_names = {
    root           = var.root_id
    platform       = "${var.root_id}-platform"
    management     = "${var.root_id}-management"
    connectivity   = "${var.root_id}-connectivity"
    identity       = "${var.root_id}-identity"
    landing_zones  = "${var.root_id}-landing-zones"
    corp           = "${var.root_id}-corp"
    corp_prod      = "${var.root_id}-corp-prod"
    corp_nonprod   = "${var.root_id}-corp-nonprod"
    online         = "${var.root_id}-online"
    online_prod    = "${var.root_id}-online-prod"
    online_nonprod = "${var.root_id}-online-nonprod"
    sandbox        = "${var.root_id}-sandbox"
    decommissioned = "${var.root_id}-decommissioned"
  }

  # Display names for each management group
  mg_display_names = {
    root           = var.root_name
    platform       = "Platform"
    management     = "Management"
    connectivity   = "Connectivity"
    identity       = "Identity"
    landing_zones  = "Landing Zones"
    corp           = "Corp"
    corp_prod      = "Corp-Prod"
    corp_nonprod   = "Corp-NonProd"
    online         = "Online"
    online_prod    = "Online-Prod"
    online_nonprod = "Online-NonProd"
    sandbox        = "Sandbox"
    decommissioned = "Decommissioned"
  }
}

################################################################################
# Local Values - Conditional Deployment Flags
################################################################################

locals {
  # Platform children deployment flags
  deploy_management   = var.deploy_platform_mg
  deploy_connectivity = var.deploy_platform_mg
  deploy_identity     = var.deploy_platform_mg

  # Landing zone deployment logic
  # If prod/nonprod separation is enabled, create Corp-Prod, Corp-NonProd, Online-Prod, Online-NonProd
  # If disabled, create just Corp and Online
  deploy_corp_prod      = var.deploy_landing_zones_mg && var.deploy_corp_landing_zones && var.deploy_prod_nonprod_separation
  deploy_corp_nonprod   = var.deploy_landing_zones_mg && var.deploy_corp_landing_zones && var.deploy_prod_nonprod_separation
  deploy_corp_single    = var.deploy_landing_zones_mg && var.deploy_corp_landing_zones && !var.deploy_prod_nonprod_separation
  deploy_online_prod    = var.deploy_landing_zones_mg && var.deploy_online_landing_zones && var.deploy_prod_nonprod_separation
  deploy_online_nonprod = var.deploy_landing_zones_mg && var.deploy_online_landing_zones && var.deploy_prod_nonprod_separation
  deploy_online_single  = var.deploy_landing_zones_mg && var.deploy_online_landing_zones && !var.deploy_prod_nonprod_separation
  deploy_sandbox        = var.deploy_landing_zones_mg && var.deploy_sandbox_mg
}

################################################################################
# Local Values - Subscription Associations
################################################################################

locals {
  # Flatten subscription associations for use with for_each
  subscription_associations = flatten([
    for mg_key, sub_ids in var.subscription_ids_by_mg : [
      for sub_id in sub_ids : {
        key             = "${mg_key}-${sub_id}"
        mg_key          = mg_key
        subscription_id = sub_id
      }
    ]
  ])

  subscription_associations_map = {
    for assoc in local.subscription_associations : assoc.key => assoc
  }

  # Map MG keys to their resource IDs for subscription placement
  mg_key_to_id = {
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
