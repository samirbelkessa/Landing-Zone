# =============================================================================
# LOCALS.TF - Data Transformations
# =============================================================================
# Orchestrator: 07-security
# Purpose: Transform inputs and extract values from remote states
# =============================================================================

locals {
  # ---------------------------------------------------------------------------
  # Tags (CAF Compliant)
  # ---------------------------------------------------------------------------
  default_tags = {
    Environment = var.environment
    Owner       = var.owner
    CostCenter  = var.cost_center
    Application = var.application
    ManagedBy   = "Terraform"
    Module      = "07-security"
  }
  tags = merge(local.default_tags, var.tags)

  # ---------------------------------------------------------------------------
  # Location short codes for naming
  # ---------------------------------------------------------------------------
  location_short_codes = {
    "australiaeast"      = "aue"
    "australiasoutheast" = "ause"
    "eastus"             = "eus"
    "westus"             = "wus"
    "westeurope"         = "weu"
    "northeurope"        = "neu"
  }
  location_short = try(local.location_short_codes[var.location], substr(var.location, 0, 4))

  # ---------------------------------------------------------------------------
  # Resource Names
  # ---------------------------------------------------------------------------
  resource_group_name = "rg-security-${local.location_short}-001"
  key_vault_name      = var.key_vault_name != null ? var.key_vault_name : "kv-intelly-platform-${local.location_short}"

  # ---------------------------------------------------------------------------
  # Remote State - Management (dynamic output mapping)
  # ---------------------------------------------------------------------------
  log_analytics_workspace_id   = try(data.terraform_remote_state.management.outputs[var.remote_state_outputs.management.log_analytics_workspace_id], null)
  log_analytics_workspace_guid = try(data.terraform_remote_state.management.outputs[var.remote_state_outputs.management.log_analytics_workspace_guid], null)
  log_analytics_workspace_name = try(data.terraform_remote_state.management.outputs[var.remote_state_outputs.management.log_analytics_workspace_name], null)
  management_resource_group    = try(data.terraform_remote_state.management.outputs[var.remote_state_outputs.management.resource_group_name], null)

  # ---------------------------------------------------------------------------
  # Remote State - Connectivity (dynamic output mapping)
  # ---------------------------------------------------------------------------
  hub_vnet_id = try(data.terraform_remote_state.connectivity.outputs[var.remote_state_outputs.connectivity.hub_vnet_id], null)
  
  hub_resource_group_name = try(
    data.terraform_remote_state.connectivity.outputs[var.remote_state_outputs.connectivity.hub_resource_group_name],
    null
  )
  
  hub_subnet_ids = try(
    data.terraform_remote_state.connectivity.outputs[var.remote_state_outputs.connectivity.hub_subnet_ids],
    {}
  )
  
  # Get SharedServices subnet for Private Endpoint (configurable via var.private_endpoint_subnet_key)
  private_endpoint_subnet_id = try(local.hub_subnet_ids[var.private_endpoint_subnet_key], null)

  # Private DNS Zone for Key Vault
  private_dns_zone_ids = try(
    data.terraform_remote_state.connectivity.outputs[var.remote_state_outputs.connectivity.private_dns_zone_ids],
    {}
  )
  
  # Key Vault DNS zone (configurable via var.keyvault_dns_zone_key)
  keyvault_dns_zone_id = try(local.private_dns_zone_ids[var.keyvault_dns_zone_key], null)

  # ---------------------------------------------------------------------------
  # Subscriptions for Defender
  # ---------------------------------------------------------------------------
  # If no specific subscriptions provided, use platform subscriptions
  defender_subscription_ids = length(var.defender_subscriptions) > 0 ? var.defender_subscriptions : [
    var.management_subscription_id,
    var.connectivity_subscription_id,
    var.identity_subscription_id
  ]

  # ---------------------------------------------------------------------------
  # Defender Plans Configuration
  # ---------------------------------------------------------------------------
  defender_plans_config = {
    VirtualMachines = {
      enabled = var.defender_plans.virtual_machines.enabled
      subplan = var.defender_plans.virtual_machines.subplan
    }
    StorageAccounts = {
      enabled = var.defender_plans.storage_accounts.enabled
      subplan = var.defender_plans.storage_accounts.subplan
    }
    SqlServers = {
      enabled = var.defender_plans.sql_servers.enabled
      subplan = null
    }
    AppServices = {
      enabled = var.defender_plans.app_services.enabled
      subplan = null
    }
    KeyVaults = {
      enabled = var.defender_plans.key_vaults.enabled
      subplan = var.defender_plans.key_vaults.subplan
    }
    Arm = {
      enabled = var.defender_plans.arm.enabled
      subplan = var.defender_plans.arm.subplan
    }
    Containers = {
      enabled = var.defender_plans.containers.enabled
      subplan = null
    }
    Dns = {
      enabled = var.defender_plans.dns.enabled
      subplan = null
    }
  }

  # Filter to only enabled plans
  enabled_defender_plans = {
    for plan, config in local.defender_plans_config :
    plan => config
    if config.enabled
  }
}
