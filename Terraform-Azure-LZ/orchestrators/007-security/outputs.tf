# =============================================================================
# OUTPUTS.TF - Orchestrator Outputs
# =============================================================================
# Orchestrator: 007-security
# Purpose: Expose security resources for downstream consumption
# =============================================================================

# =============================================================================
# RESOURCE GROUP
# =============================================================================

output "resource_group_name" {
  description = "Name of the security resource group."
  value       = var.deploy_resource_group ? azurerm_resource_group.security[0].name : null
}

output "resource_group_id" {
  description = "ID of the security resource group."
  value       = var.deploy_resource_group ? azurerm_resource_group.security[0].id : null
}

# =============================================================================
# S01 - DEFENDER FOR CLOUD
# =============================================================================

output "defender_plans_status" {
  description = "Status of each Defender plan."
  value       = var.deploy_defender ? module.defender[0].defender_plans_status : null
}

output "defender_enabled_plans" {
  description = "List of enabled Defender plans."
  value       = var.deploy_defender ? module.defender[0].enabled_plans : []
}

output "defender_security_contact" {
  description = "Security contact email for Defender alerts."
  value       = var.deploy_defender ? module.defender[0].security_contact_email : null
}

# =============================================================================
# S02 - SENTINEL
# =============================================================================

output "sentinel_onboarding_id" {
  description = "ID of the Sentinel onboarding resource."
  value       = var.deploy_sentinel && local.log_analytics_workspace_id != null ? module.sentinel[0].sentinel_onboarding_id : null
}

output "sentinel_workspace_id" {
  description = "Log Analytics Workspace ID where Sentinel is onboarded."
  value       = var.deploy_sentinel && local.log_analytics_workspace_id != null ? module.sentinel[0].workspace_id : null
}

output "sentinel_data_connectors_status" {
  description = "Status of Sentinel data connectors."
  value       = var.deploy_sentinel && local.log_analytics_workspace_id != null ? module.sentinel[0].data_connectors_status : null
}

output "sentinel_enabled_connectors" {
  description = "List of enabled Sentinel data connectors."
  value       = var.deploy_sentinel && local.log_analytics_workspace_id != null ? module.sentinel[0].enabled_connectors : []
}

# =============================================================================
# S03 - KEY VAULT
# =============================================================================

output "key_vault_id" {
  description = "ID of the platform Key Vault."
  value       = var.deploy_key_vault ? module.key_vault[0].resource_id : null
}

output "key_vault_name" {
  description = "Name of the platform Key Vault."
  value       = var.deploy_key_vault ? module.key_vault[0].name : null
}

output "key_vault_uri" {
  description = "URI of the platform Key Vault."
  value       = var.deploy_key_vault ? module.key_vault[0].uri : null
}

output "key_vault_private_endpoints" {
  description = "Private endpoints created for Key Vault."
  value       = var.deploy_key_vault ? module.key_vault[0].private_endpoints : null
}

# =============================================================================
# S05 - NSG
# =============================================================================

output "nsg_id" {
  description = "ID of the shared services NSG."
  value       = var.deploy_nsg_baseline ? module.nsg_shared_services[0].resource_id : null
}

output "nsg_name" {
  description = "Name of the shared services NSG."
  value       = var.deploy_nsg_baseline ? module.nsg_shared_services[0].name : null
}

output "nsg_security_rules" {
  description = "Security rules applied to the NSG."
  value       = var.deploy_nsg_baseline ? module.nsg_shared_services[0].security_rules : null
}

output "nsg_baseline_rules_applied" {
  description = "Indicates if baseline rules were applied."
  value       = var.enable_nsg_baseline_rules
}

# =============================================================================
# DEPLOYMENT STATUS
# =============================================================================

output "deployment_status" {
  description = "Status of each component deployment."
  value = {
    resource_group = var.deploy_resource_group ? "deployed" : "skipped"
    defender       = var.deploy_defender ? "deployed" : "skipped"
    sentinel       = var.deploy_sentinel && local.log_analytics_workspace_id != null ? "deployed" : "skipped"
    key_vault      = var.deploy_key_vault ? "deployed" : "skipped"
    nsg_baseline   = var.deploy_nsg_baseline ? "deployed" : "skipped"
  }
}

# =============================================================================
# TAGS
# =============================================================================

output "tags" {
  description = "Tags applied to security resources."
  value       = local.tags
}

# =============================================================================
# CONFIGURATION SUMMARY
# =============================================================================

output "security_config" {
  description = "Complete security configuration for documentation."
  value = {
    location    = var.location
    environment = var.environment

    defender = var.deploy_defender ? {
      enabled_plans    = module.defender[0].enabled_plans
      security_contact = var.security_contact_email
    } : null

    sentinel = var.deploy_sentinel && local.log_analytics_workspace_id != null ? {
      workspace_id        = local.log_analytics_workspace_id
      enabled_connectors  = module.sentinel[0].enabled_connectors
    } : null

    key_vault = var.deploy_key_vault ? {
      name             = module.key_vault[0].name
      uri              = module.key_vault[0].uri
      sku              = var.key_vault_sku
      private_endpoint = var.key_vault_enable_private_endpoint
      public_access    = var.key_vault_public_network_access
    } : null

    nsg = var.deploy_nsg_baseline ? {
      name           = module.nsg_shared_services[0].name
      rules_count    = length(local.all_nsg_rules)
      baseline_rules = var.enable_nsg_baseline_rules
    } : null
  }
}

# =============================================================================
# REMOTE STATE REFERENCES (For Debugging)
# =============================================================================

output "remote_state_dependencies" {
  description = "Values retrieved from remote state (for debugging)."
  value = {
    management = {
      log_analytics_workspace_id   = local.log_analytics_workspace_id
      log_analytics_workspace_name = local.log_analytics_workspace_name
      resource_group_name          = local.management_resource_group
    }
    connectivity = {
      hub_vnet_id             = local.hub_vnet_id
      hub_resource_group_name = local.hub_resource_group_name
      private_endpoint_subnet = local.private_endpoint_subnet_id != null ? "found" : "not_found"
      keyvault_dns_zone       = local.keyvault_dns_zone_id != null ? "found" : "not_found"
    }
  }
  sensitive = false
}
