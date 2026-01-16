# =============================================================================
# LOCALS.TF - Local Values and Computations
# =============================================================================
# Orchestrator: 007-security
# Purpose: Security components deployment (Defender, Sentinel, Key Vault, NSG)
# =============================================================================

locals {
  # ---------------------------------------------------------------------------
  # Location Abbreviations
  # ---------------------------------------------------------------------------
  location_abbreviations = {
    "australiaeast"      = "aue"
    "australiasoutheast" = "ause"
    "eastus"             = "eus"
    "westus"             = "wus"
    "westeurope"         = "weu"
    "northeurope"        = "neu"
  }

  location_short = lookup(local.location_abbreviations, var.location, substr(var.location, 0, 4))

  # ---------------------------------------------------------------------------
  # Resource Naming
  # ---------------------------------------------------------------------------
  resource_group_name = "rg-security-${local.location_short}-001"
  key_vault_name      = var.key_vault_name != null ? var.key_vault_name : "kv-${var.organization}-platform-${local.location_short}"
  nsg_name            = "nsg-shared-services-${var.environment}-${local.location_short}"

  # ---------------------------------------------------------------------------
  # Tags
  # ---------------------------------------------------------------------------
  default_tags = {
    ManagedBy    = "Terraform"
    Orchestrator = "007-security"
    Environment  = var.environment
    Owner        = var.owner
    CostCenter   = var.cost_center
    Application  = "Platform Security"
  }

  tags = merge(local.default_tags, var.tags)

  # ---------------------------------------------------------------------------
  # Remote State - Management (Dynamic Output Mapping)
  # ---------------------------------------------------------------------------
  log_analytics_workspace_id = try(
    data.terraform_remote_state.management.outputs[var.remote_state_outputs.management.log_analytics_workspace_id],
    null
  )

  log_analytics_workspace_name = try(
    data.terraform_remote_state.management.outputs[var.remote_state_outputs.management.log_analytics_workspace_name],
    null
  )

  log_analytics_workspace_guid = try(
    data.terraform_remote_state.management.outputs[var.remote_state_outputs.management.log_analytics_workspace_guid],
    null
  )

  management_resource_group = try(
    data.terraform_remote_state.management.outputs[var.remote_state_outputs.management.resource_group_name],
    null
  )

  # ---------------------------------------------------------------------------
  # Remote State - Connectivity (Dynamic Output Mapping)
  # ---------------------------------------------------------------------------
  hub_vnet_id = try(
    data.terraform_remote_state.connectivity.outputs[var.remote_state_outputs.connectivity.hub_vnet_id],
    null
  )

  hub_resource_group_name = try(
    data.terraform_remote_state.connectivity.outputs[var.remote_state_outputs.connectivity.hub_resource_group_name],
    null
  )

  hub_subnet_ids = try(
    data.terraform_remote_state.connectivity.outputs[var.remote_state_outputs.connectivity.hub_subnet_ids],
    {}
  )

  private_dns_zone_ids = try(
    data.terraform_remote_state.connectivity.outputs[var.remote_state_outputs.connectivity.private_dns_zone_ids],
    {}
  )

  # ---------------------------------------------------------------------------
  # Private Endpoint Configuration
  # ---------------------------------------------------------------------------
  # Get SharedServices subnet for Private Endpoint
  private_endpoint_subnet_id = try(local.hub_subnet_ids[var.private_endpoint_subnet_key], null)

  # Key Vault DNS zone
  keyvault_dns_zone_id = try(local.private_dns_zone_ids[var.keyvault_dns_zone_key], null)

  # ---------------------------------------------------------------------------
  # NSG Rules - Merge Baseline + Custom
  # ---------------------------------------------------------------------------
  all_nsg_rules = merge(
    var.enable_nsg_baseline_rules ? local.nsg_baseline_rules : {},
    var.custom_nsg_rules
  )

  nsg_baseline_rules = {

    # =========================================================================
    # INBOUND RULES
    # =========================================================================

    # -------------------------------------------------------------------------
    # Azure Load Balancer - Allow health probes and traffic
    # -------------------------------------------------------------------------
    azure_loadbalancer_inbound = {
      name                       = "Azure_LoadBalancer_InBound"
      description                = "Allow inbound access to Azure Load Balancer. This rule is required to overwrite the rule DefaultDenyInbound."
      priority                   = 1001
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_address_prefix      = "AzureLoadBalancer"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_ranges    = toset(["80", "443", "8080"])
    }

    # -------------------------------------------------------------------------
    # Azure Service Fabric - Allow cluster communication
    # -------------------------------------------------------------------------
    azure_servicefabric_inbound = {
      name                       = "Azure_ServiceFabric_InBound"
      description                = "Allow inbound access to Azure Service Fabric."
      priority                   = 1002
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_address_prefix      = "ServiceFabric"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "*"
    }

    # -------------------------------------------------------------------------
    # On-Premises Infrastructure - Allow DC and Shared Services
    # -------------------------------------------------------------------------
    expdc_infrastructure_inbound = {
      name                        = "EXPDC_Infrastructure_DC_Shared_InBound"
      description                 = "Allow inbound access to Azure Virtual Network resources from onPrem EXP Infrastructure and Shared Services"
      priority                    = 1010
      direction                   = "Inbound"
      access                      = "Allow"
      protocol                    = "*"
      source_address_prefixes     = toset(["10.254.150.64/26", "168.217.20.0/24", "168.217.30.160/28", "168.217.38.0/24"])
      source_port_range           = "*"
      destination_address_prefix  = "VirtualNetwork"
      destination_port_range      = "*"
    }

    # -------------------------------------------------------------------------
    # Default Deny Inbound - Override Azure default AllowVnetInBound
    # -------------------------------------------------------------------------
    default_deny_inbound = {
      name                       = "Default_Deny_InBound_Override"
      description                = "Required to override default rule AllowVnetInBound."
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_address_prefix      = "*"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "*"
    }

    # =========================================================================
    # OUTBOUND RULES
    # =========================================================================

    # -------------------------------------------------------------------------
    # Qualys Security Scanner - Allow vulnerability scanning
    # -------------------------------------------------------------------------
    qualys_datacenter_outbound = {
      name                        = "Qualys_Datacenter_OutBound"
      description                 = "Access to Outbound_Qualys_Datacenter"
      priority                    = 880
      direction                   = "Outbound"
      access                      = "Allow"
      protocol                    = "*"
      source_address_prefix       = "VirtualNetwork"
      source_port_range           = "*"
      destination_address_prefixes = toset(["64.39.104.113", "154.59.121.74"])
      destination_port_range      = "443"
    }

    # -------------------------------------------------------------------------
    # Azure Storage - Australia East (Primary Region)
    # -------------------------------------------------------------------------
    azure_storage_australiaeast_outbound = {
      name                       = "Azure_Storage_AustraliaEast_OutBound"
      description                = "Allow outbound access to Azure storage."
      priority                   = 1000
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "VirtualNetwork"
      source_port_range          = "*"
      destination_address_prefix = "Storage.AustraliaEast"
      destination_port_ranges    = toset(["80", "443", "445"])
    }

    # -------------------------------------------------------------------------
    # Azure Storage - Australia Southeast (DR Region)
    # -------------------------------------------------------------------------
    azure_storage_australiasoutheast_outbound = {
      name                       = "Azure_Storage_AustraliaSouthEast_OutBound"
      description                = "Allow outbound access to Azure storage."
      priority                   = 1001
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "VirtualNetwork"
      source_port_range          = "*"
      destination_address_prefix = "Storage.AustraliaSouthEast"
      destination_port_ranges    = toset(["80", "443", "445"])
    }

    # -------------------------------------------------------------------------
    # Azure Active Directory - Authentication and LDAP
    # -------------------------------------------------------------------------
    azure_activedirectory_outbound = {
      name                       = "Azure_ActiveDirectory_OutBound"
      description                = "Allow Access to Azure Active Directory MS Authentication, LDAP and required AD protocols"
      priority                   = 1002
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "VirtualNetwork"
      source_port_range          = "*"
      destination_address_prefix = "AzureActiveDirectory"
      destination_port_ranges    = toset(["443", "636", "389", "5986"])
    }

    # -------------------------------------------------------------------------
    # Azure Storage - Global (Fallback)
    # -------------------------------------------------------------------------
    azure_storage_outbound = {
      name                       = "Azure_Storage_OutBound"
      description                = "Allow outbound access to Azure storage."
      priority                   = 1008
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "VirtualNetwork"
      source_port_range          = "*"
      destination_address_prefix = "Storage"
      destination_port_ranges    = toset(["80", "443", "445"])
    }

    # -------------------------------------------------------------------------
    # Azure Site Recovery - DR replication
    # -------------------------------------------------------------------------
    azure_siterecovery_outbound = {
      name                       = "Azure_SiteRecovery_OutBound"
      description                = "Allow outbound access to Azure Site Recovery."
      priority                   = 1009
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "VirtualNetwork"
      source_port_range          = "*"
      destination_address_prefix = "AzureSiteRecovery"
      destination_port_range     = "443"
    }

    # -------------------------------------------------------------------------
    # Azure Event Hub - Australia East (Diagnostics, Logs)
    # -------------------------------------------------------------------------
    azure_eventhub_australiaeast_outbound = {
      name                       = "Azure_EventHub_AustraliaEast_OutBound"
      description                = "Allow outbound access to Azure Event Hub."
      priority                   = 1010
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "VirtualNetwork"
      source_port_range          = "*"
      destination_address_prefix = "EventHub.AustraliaEast"
      destination_port_range     = "443"
    }

    # -------------------------------------------------------------------------
    # Azure Event Hub - Australia Southeast (DR)
    # -------------------------------------------------------------------------
    azure_eventhub_australiasoutheast_outbound = {
      name                       = "Azure_EventHub_AustraliaSouthEast_OutBound"
      description                = "Allow outbound access to Azure Event Hub."
      priority                   = 1011
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "VirtualNetwork"
      source_port_range          = "*"
      destination_address_prefix = "EventHub.AustraliaSouthEast"
      destination_port_range     = "443"
    }

    # -------------------------------------------------------------------------
    # On-Premises Infrastructure - Allow to DC and Shared Services
    # -------------------------------------------------------------------------
    expdc_infrastructure_outbound = {
      name                         = "EXPDC_Infrastructure_DC_Shared_OutBound"
      description                  = "Allow OutBound access from Azure Virtual Network resources to onPrem EXP Infrastructure and Shared Services"
      priority                     = 1040
      direction                    = "Outbound"
      access                       = "Allow"
      protocol                     = "*"
      source_address_prefix        = "VirtualNetwork"
      source_port_range            = "*"
      destination_address_prefixes = toset(["10.254.150.64/26", "168.217.20.0/24", "168.217.30.160/28", "168.217.38.0/24"])
      destination_port_range       = "*"
    }

    # -------------------------------------------------------------------------
    # Default Deny Outbound - Override Azure default rules
    # -------------------------------------------------------------------------
    default_deny_outbound = {
      name                       = "Default_Deny_OutBound_Override"
      description                = "Required to override default rules 65000"
      priority                   = 4096
      direction                  = "Outbound"
      access                     = "Deny"
      protocol                   = "*"
      source_address_prefix      = "*"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "*"
    }
  }
}
