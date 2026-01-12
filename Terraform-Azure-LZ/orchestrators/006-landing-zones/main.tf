# =============================================================================
# MAIN.TF - Landing Zone Vending Module
# =============================================================================
# Orchestrator: 06-landing-zones
# Purpose: Deploy Landing Zones using Azure Verified Module (AVM)
# Module: Azure/avm-ptn-alz-sub-vending/azure
# Modes: Greenfield (create subscriptions) or Brownfield (existing subscriptions)
# =============================================================================

# =============================================================================
# LANDING ZONE VENDING
# =============================================================================
# Deploys for each Landing Zone:
# - [GREENFIELD] Create new subscription OR [BROWNFIELD] Use existing
# - Subscription placement in Management Group
# - Virtual Network with subnets
# - Hub VNet peering (bi-directional)
# - Resource Groups
# - RBAC assignments
# - Budget alerts
# =============================================================================

module "lz_vending" {
  source  = "Azure/avm-ptn-alz-sub-vending/azure"
  version = "~> 0.1"

  for_each = local.landing_zones_processed

  # ---------------------------------------------------------------------------
  # LOCATION (Required)
  # ---------------------------------------------------------------------------
  location = each.value.location

  # ---------------------------------------------------------------------------
  # SUBSCRIPTION CONFIGURATION - GREENFIELD OR BROWNFIELD
  # ---------------------------------------------------------------------------

  # GREENFIELD MODE: Create new subscription
  subscription_alias_enabled = each.value.is_greenfield
  subscription_alias_name    = each.value.is_greenfield ? each.value.subscription_alias : null
  subscription_display_name  = each.value.is_greenfield ? each.value.subscription_display_name : null
  subscription_workload      = each.value.is_greenfield ? each.value.subscription_workload : null
  subscription_billing_scope = each.value.is_greenfield ? each.value.subscription_billing_scope : null

  # BROWNFIELD MODE: Use existing subscription
  subscription_id = each.value.is_greenfield ? null : each.value.subscription_id

  # ---------------------------------------------------------------------------
  # MANAGEMENT GROUP PLACEMENT
  # ---------------------------------------------------------------------------
  # Place subscription in the correct Management Group based on archetype
  # ---------------------------------------------------------------------------

  subscription_management_group_association_enabled = true
  subscription_management_group_id                  = each.value.management_group_id

  # ---------------------------------------------------------------------------
  # RESOURCE PROVIDER REGISTRATION
  # ---------------------------------------------------------------------------

  subscription_register_resource_providers_enabled = var.enable_resource_providers_registration
  subscription_register_resource_providers_and_features = {
    for rp in var.resource_providers : rp => toset([])
  }

  # ---------------------------------------------------------------------------
  # SUBSCRIPTION TAGS
  # ---------------------------------------------------------------------------

  subscription_tags = each.value.tags

  # ---------------------------------------------------------------------------
  # RESOURCE GROUPS
  # ---------------------------------------------------------------------------
  # Create resource groups first, then reference them in virtual_networks
  # ---------------------------------------------------------------------------

  resource_group_creation_enabled = true

  resource_groups = {
    for rg_key, rg in each.value.resource_groups : rg_key => {
      name     = rg.name
      location = rg.location
      tags     = merge(each.value.tags, rg.tags)
    }
  }

  # ---------------------------------------------------------------------------
  # VIRTUAL NETWORK CONFIGURATION
  # ---------------------------------------------------------------------------
  # Creates spoke VNet with subnets and peering to Hub
  # Note: resource_group_key references a key in the resource_groups map above
  # ---------------------------------------------------------------------------

  virtual_network_enabled = true

  virtual_networks = {
    primary = {
      name          = each.value.vnet_name
      address_space = each.value.address_space
      location      = each.value.location

      # Reference to resource group created above (key must match)
      resource_group_key = "network"

      # Hub Peering Configuration
      hub_peering_enabled             = each.value.enable_hub_peering
      hub_peering_direction           = "both"
      hub_network_resource_id         = each.value.hub_vnet_id
      hub_peering_use_remote_gateways = false

      # DNS Configuration (use Hub DNS Resolver/Firewall DNS Proxy)
      dns_servers = each.value.dns_servers

      # Subnets
      subnets = {
        for subnet_key, subnet in each.value.subnets : subnet_key => {
          name             = subnet.name
          address_prefixes = subnet.address_prefixes

          # Private Endpoint policies
          private_endpoint_network_policies = subnet.private_endpoint_network_policies

          # Service Endpoints
          service_endpoints = subnet.service_endpoints

          # Route Table association (user-specified or Hub UDR)
          route_table = (
            subnet.route_table_id != null ? { id = subnet.route_table_id } :
            each.value.route_table_id != null ? { id = each.value.route_table_id } :
            null
          )

          # NSG association
          network_security_group = subnet.network_security_group_id != null ? {
            id = subnet.network_security_group_id
          } : null

          # Subnet delegation (e.g., for App Services, Container Instances)
          delegation = subnet.delegation != null ? [
            {
              name = subnet.delegation.name
              service_delegation = {
                name = subnet.delegation.service_name
              }
            }
          ] : []
        }
      }

      # Tags for VNet
      tags = each.value.tags
    }
  }

  # ---------------------------------------------------------------------------
  # RBAC ASSIGNMENTS
  # ---------------------------------------------------------------------------

  role_assignment_enabled = length(each.value.role_assignments) > 0

  role_assignments = {
    for ra_key, ra in each.value.role_assignments : ra_key => {
      principal_id   = ra.principal_id
      definition     = ra.role_definition_name != null ? ra.role_definition_name : "Contributor"
      relative_scope = ra.scope != null ? ra.scope : ""
    }
  }

  # ---------------------------------------------------------------------------
  # BUDGET ALERTS
  # ---------------------------------------------------------------------------

  budget_enabled = each.value.budget != null

  budgets = each.value.budget != null ? {
    default = {
      name              = "budget-${each.key}"
      amount            = each.value.budget.amount
      time_grain        = each.value.budget.time_grain
      time_period_start = each.value.budget.start_date
      time_period_end   = each.value.budget.end_date

      notifications = each.value.budget.notifications != null ? {
        for notif_key, notif in each.value.budget.notifications : notif_key => {
          enabled        = true
          threshold      = notif.threshold
          operator       = notif.operator
          contact_emails = notif.contact_emails
        }
      } : {}
    }
  } : {}

  # ---------------------------------------------------------------------------
  # DEPENDENCIES
  # ---------------------------------------------------------------------------
  depends_on = [
    data.terraform_remote_state.foundation,
    data.terraform_remote_state.connectivity
  ]
}

# =============================================================================
# DIAGNOSTIC SETTINGS FOR SPOKE VNETS
# =============================================================================
# Send VNet diagnostics to central Log Analytics workspace
# =============================================================================

resource "azurerm_monitor_diagnostic_setting" "spoke_vnet" {
  for_each = {
    for lz_key, lz in local.landing_zones_processed : lz_key => lz
    if local.log_analytics_workspace_id != null
  }

  name                       = "diag-${each.value.vnet_name}"
  target_resource_id         = module.lz_vending[each.key].virtual_network_resource_ids["primary"]
  log_analytics_workspace_id = local.log_analytics_workspace_id

  enabled_log {
    category = "VMProtectionAlerts"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
