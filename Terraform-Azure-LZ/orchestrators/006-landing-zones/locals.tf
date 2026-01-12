# =============================================================================
# LOCALS.TF - Computed Values and Transformations
# =============================================================================
# Orchestrator: 06-landing-zones
# Purpose: Process inputs and remote state data for Landing Zone deployment
# Modes: Greenfield (create subscriptions) or Brownfield (existing subscriptions)
# =============================================================================

locals {
  # ===========================================================================
  # REMOTE STATE OUTPUTS
  # ===========================================================================

# ---------------------------------------------------------------------------
  # Foundation - Management Groups
  # ---------------------------------------------------------------------------
  # 100% dynamic - reads from foundation remote state
  # AVM module expects MG NAME (e.g., "intelly-online-prod"), not full resource ID
  # ---------------------------------------------------------------------------
  
  # Get archetype_mg_ids from foundation (contains full resource IDs)
  archetype_mg_ids_from_state = try(data.terraform_remote_state.foundation.outputs.archetype_mg_ids, {})

  # Dynamically extract MG name from full resource ID and convert key format
  # Input:  { "online_prod" = "/providers/Microsoft.Management/managementGroups/intelly-online-prod" }
  # Output: { "online-prod" = "intelly-online-prod" }
  archetype_to_management_group = {
    for key, value in local.archetype_mg_ids_from_state :
    replace(key, "_", "-") => try(
      regex("managementGroups/([^/]+)$", tostring(value))[0],
      null
    )
    if value != null
  }

  # ---------------------------------------------------------------------------
  # Management - Log Analytics
  # ---------------------------------------------------------------------------
  log_analytics_workspace_id = try(
    tostring(data.terraform_remote_state.management.outputs.log_analytics_workspace_id),
    null
  )

  # ---------------------------------------------------------------------------
  # Connectivity - Hub Configuration per Region
  # ---------------------------------------------------------------------------
  connectivity_outputs = try(data.terraform_remote_state.connectivity.outputs, {})

  # Spoke peering configuration from connectivity
  spoke_peering_config = try(local.connectivity_outputs.spoke_peering_config, {})

  # Hub configuration by region
  hub_config = {
    australiaeast = {
      hub_vnet_id         = try(tostring(local.spoke_peering_config["australiaeast"].hub_vnet_id), null)
      hub_vnet_name       = try(tostring(local.spoke_peering_config["australiaeast"].hub_vnet_name), null)
      resource_group_name = try(tostring(local.spoke_peering_config["australiaeast"].resource_group_name), null)
      firewall_private_ip = try(tostring(local.spoke_peering_config["australiaeast"].firewall_private_ip), null)
      route_table_id      = try(tostring(local.spoke_peering_config["australiaeast"].route_table_id), null)
      dns_server_ip       = try(tostring(local.spoke_peering_config["australiaeast"].dns_server_ip), null)
    }
    australiasoutheast = {
      hub_vnet_id         = try(tostring(local.spoke_peering_config["australiasoutheast"].hub_vnet_id), null)
      hub_vnet_name       = try(tostring(local.spoke_peering_config["australiasoutheast"].hub_vnet_name), null)
      resource_group_name = try(tostring(local.spoke_peering_config["australiasoutheast"].resource_group_name), null)
      firewall_private_ip = try(tostring(local.spoke_peering_config["australiasoutheast"].firewall_private_ip), null)
      route_table_id      = try(tostring(local.spoke_peering_config["australiasoutheast"].route_table_id), null)
      dns_server_ip       = try(tostring(local.spoke_peering_config["australiasoutheast"].dns_server_ip), null)
    }
  }

  # DNS Resource Group (for Private DNS Zone links)
  connectivity_dns_resource_group = try(
    tostring(local.connectivity_outputs.dns_resource_group_name),
    "rg-connectivity-dns-aue-001"
  )

  # Private DNS Zones from connectivity
  connectivity_private_dns_zones = try(
    local.connectivity_outputs.private_dns_zone_names,
    []
  )

  # ===========================================================================
  # PRIVATE DNS ZONES LINKING
  # ===========================================================================
  # Get DNS zones from connectivity remote state, or use custom list if provided
  # If no zones available, disable DNS zone linking
  # ===========================================================================
  
  # Get zones from connectivity output (if available)
  connectivity_dns_zones_from_state = try(
    data.terraform_remote_state.connectivity.outputs.private_dns_zone_names,
    []
  )

  # Determine which zones to link
  private_dns_zones_to_link = (
    # Option 1: Use custom list if provided
    length(var.private_dns_zones_to_link) > 0 ? var.private_dns_zones_to_link :
    # Option 2: Use all zones from connectivity state
    length(local.connectivity_dns_zones_from_state) > 0 ? local.connectivity_dns_zones_from_state :
    # Option 3: Empty list (no DNS zone linking)
    []
  )

  # ===========================================================================
  # LANDING ZONES CLASSIFICATION
  # ===========================================================================

  # Separate Greenfield and Brownfield Landing Zones
  greenfield_landing_zones = {
    for lz_key, lz in var.landing_zones : lz_key => lz
    if lz.create_subscription == true
  }

  brownfield_landing_zones = {
    for lz_key, lz in var.landing_zones : lz_key => lz
    if lz.create_subscription != true && lz.subscription_id != null
  }

  # ===========================================================================
  # LANDING ZONES PROCESSING
  # ===========================================================================

  # Location short codes
  location_short = {
    australiaeast      = "aue"
    australiasoutheast = "ause"
  }

  # Process each Landing Zone (unified processing for both modes)
  landing_zones_processed = {
    for lz_key, lz in var.landing_zones : lz_key => {
      # -----------------------------------------------------------------------
      # SUBSCRIPTION MODE
      # -----------------------------------------------------------------------
      is_greenfield              = lz.create_subscription == true
      subscription_id            = lz.subscription_id
      subscription_alias         = lz.subscription_alias
      subscription_display_name  = lz.subscription_display_name
      subscription_workload      = lz.subscription_workload
      subscription_billing_scope = lz.subscription_billing_scope != null ? lz.subscription_billing_scope : var.default_billing_scope

      # Management Group placement
      management_group_id = local.archetype_to_management_group[lz.archetype]
      archetype           = lz.archetype

      # -----------------------------------------------------------------------
      # LOCATION
      # -----------------------------------------------------------------------
      location       = lz.location
      location_short = lz.location_short != null ? lz.location_short : local.location_short[lz.location]

      # -----------------------------------------------------------------------
      # HUB CONFIGURATION (from remote state)
      # -----------------------------------------------------------------------
      hub_vnet_id    = try(tostring(local.hub_config[lz.location].hub_vnet_id), null)
      route_table_id = try(tostring(local.hub_config[lz.location].route_table_id), null)
      dns_servers = lz.dns_servers != null ? lz.dns_servers : (
        try(local.hub_config[lz.location].dns_server_ip, null) != null ? [local.hub_config[lz.location].dns_server_ip] : []
      )

      # -----------------------------------------------------------------------
      # VNET CONFIGURATION
      # -----------------------------------------------------------------------
      vnet_name = lz.vnet_name != null ? lz.vnet_name : "vnet-${lz_key}-${lz.location_short != null ? lz.location_short : local.location_short[lz.location]}-001"
      address_space = lz.address_space

      # Network Resource Group
      network_resource_group = "rg-${lz_key}-network-${lz.location_short != null ? lz.location_short : local.location_short[lz.location]}-001"

      # Subnets with defaults
      subnets = {
        for subnet_key, subnet in lz.subnets : subnet_key => {
          name             = "snet-${lz_key}-${subnet_key}"
          address_prefixes = [subnet.address_prefix]
          private_endpoint_network_policies = subnet.private_endpoint_network_policies
          service_endpoints = subnet.service_endpoints
          delegation        = subnet.delegation
          # Route table ID (user-specified only, Hub UDR applied via main.tf)
          route_table_id = subnet.route_table_id
          network_security_group_id = subnet.network_security_group_id
        }
      }

      # -----------------------------------------------------------------------
      # RESOURCE GROUPS
      # -----------------------------------------------------------------------
      resource_groups = merge(
        {
          network = {
            name     = "rg-${lz_key}-network-${lz.location_short != null ? lz.location_short : local.location_short[lz.location]}-001"
            location = lz.location
            tags     = {}
          }
        },
        {
          for rg_key, rg in lz.resource_groups : rg_key => {
            name     = rg.name
            location = rg.location != null ? rg.location : lz.location
            tags     = rg.tags != null ? rg.tags : {}
          }
        }
      )

      # -----------------------------------------------------------------------
      # RBAC ASSIGNMENTS
      # -----------------------------------------------------------------------
      role_assignments = lz.role_assignments

      # -----------------------------------------------------------------------
      # BUDGET (with default dates if not specified)
      # -----------------------------------------------------------------------
      budget = lz.budget != null ? {
        amount     = lz.budget.amount
        time_grain = lz.budget.time_grain
        start_date = lz.budget.start_date != null ? lz.budget.start_date : "${formatdate("YYYY-MM", timestamp())}-01T00:00:00Z"
        end_date   = lz.budget.end_date != null ? lz.budget.end_date : "${tonumber(formatdate("YYYY", timestamp())) + 3}-12-31T23:59:59Z"
        notifications = lz.budget.notifications
      } : null

      # -----------------------------------------------------------------------
      # TAGS
      # -----------------------------------------------------------------------
      tags = merge(
        var.default_tags,
        {
          Environment     = local.archetype_tags[lz.archetype].environment
          NetworkType     = "Spoke"
          Archetype       = lz.archetype
          LandingZone     = lz_key
          ProvisionedMode = lz.create_subscription == true ? "Greenfield" : "Brownfield"
        },
        lz.tags
      )

      # -----------------------------------------------------------------------
      # FEATURE FLAGS
      # -----------------------------------------------------------------------
      enable_private_dns_zone_links = lz.enable_private_dns_zone_links
      enable_hub_peering            = lz.enable_hub_peering
    }
  }

  # ===========================================================================
  # ARCHETYPE CONFIGURATIONS
  # ===========================================================================
  archetype_tags = {
    "online-prod" = {
      environment = "Production"
    }
    "online-nonprod" = {
      environment = "Non-Production"
    }
    "corp-prod" = {
      environment = "Production"
    }
    "corp-nonprod" = {
      environment = "Non-Production"
    }
    "sandbox" = {
      environment = "Sandbox"
    }
  }

  # ===========================================================================
  # PRIVATE DNS ZONE LINKS
  # ===========================================================================
  # Create a flat map of all DNS zone links needed
  dns_zone_links = merge([
    for lz_key, lz in local.landing_zones_processed : {
      for zone in local.private_dns_zones_to_link : "${lz_key}-${replace(zone, ".", "-")}" => {
        landing_zone_key = lz_key
        dns_zone_name    = zone
        vnet_name        = lz.vnet_name
        enabled          = lz.enable_private_dns_zone_links
      }
    } if lz.enable_private_dns_zone_links
  ]...)

  # ===========================================================================
  # SUMMARY COUNTS
  # ===========================================================================
  total_landing_zones      = length(var.landing_zones)
  greenfield_count         = length(local.greenfield_landing_zones)
  brownfield_count         = length(local.brownfield_landing_zones)
  total_subnets            = sum([for lz in var.landing_zones : length(lz.subnets)])
  total_dns_zone_links     = length(local.dns_zone_links)
}
