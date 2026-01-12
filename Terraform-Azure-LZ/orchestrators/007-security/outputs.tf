# =============================================================================
# OUTPUTS.TF - Security Orchestrator Outputs
# =============================================================================
# Orchestrator: 07-security
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
# KEY VAULT
# =============================================================================

output "key_vault_id" {
  description = "ID of the platform Key Vault."
  value       = var.deploy_key_vault ? azurerm_key_vault.platform[0].id : null
}

output "key_vault_name" {
  description = "Name of the platform Key Vault."
  value       = var.deploy_key_vault ? azurerm_key_vault.platform[0].name : null
}

output "key_vault_uri" {
  description = "URI of the platform Key Vault."
  value       = var.deploy_key_vault ? azurerm_key_vault.platform[0].vault_uri : null
}

output "key_vault_private_endpoint_id" {
  description = "ID of the Key Vault private endpoint."
  value       = var.deploy_key_vault && var.key_vault_enable_private_endpoint && local.private_endpoint_subnet_id != null ? azurerm_private_endpoint.key_vault[0].id : null
}

output "key_vault_private_endpoint_ip" {
  description = "Private IP address of the Key Vault private endpoint."
  value       = var.deploy_key_vault && var.key_vault_enable_private_endpoint && local.private_endpoint_subnet_id != null ? azurerm_private_endpoint.key_vault[0].private_service_connection[0].private_ip_address : null
}

# =============================================================================
# SENTINEL
# =============================================================================

output "sentinel_workspace_id" {
  description = "Log Analytics Workspace ID where Sentinel is onboarded."
  value       = var.deploy_sentinel ? local.log_analytics_workspace_id : null
}

output "sentinel_onboarding_id" {
  description = "ID of the Sentinel onboarding resource."
  value       = var.deploy_sentinel && local.log_analytics_workspace_id != null ? azurerm_sentinel_log_analytics_workspace_onboarding.sentinel[0].id : null
}

output "sentinel_data_connectors" {
  description = "List of enabled Sentinel data connectors."
  value = {
    azure_active_directory = var.deploy_sentinel && var.sentinel_data_connectors.azure_active_directory ? "enabled" : "disabled"
    defender_for_cloud     = var.deploy_sentinel && var.sentinel_data_connectors.defender_for_cloud ? "enabled" : "disabled"
    threat_intelligence    = var.deploy_sentinel && var.sentinel_data_connectors.threat_intelligence ? "enabled" : "disabled"
  }
}

# =============================================================================
# DEFENDER FOR CLOUD
# =============================================================================

output "defender_plans_enabled" {
  description = "Map of Defender plans enabled on each subscription."
  value = var.deploy_defender ? {
    management   = [for plan, config in local.enabled_defender_plans : plan]
    connectivity = [for plan, config in local.enabled_defender_plans : plan]
    identity     = [for plan, config in local.enabled_defender_plans : plan]
  } : {}
}

output "defender_security_contact" {
  description = "Security contact email for Defender alerts."
  value       = var.deploy_defender ? var.security_contact_email : null
}

# =============================================================================
# DEPLOYMENT STATUS
# =============================================================================

output "deployment_status" {
  description = "Status of each module deployment."
  value = {
    resource_group = var.deploy_resource_group ? "deployed" : "skipped"
    key_vault      = var.deploy_key_vault ? "deployed" : "skipped"
    sentinel       = var.deploy_sentinel ? "deployed" : "skipped"
    defender       = var.deploy_defender ? "deployed" : "skipped"
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

    key_vault = var.deploy_key_vault ? {
      name             = azurerm_key_vault.platform[0].name
      uri              = azurerm_key_vault.platform[0].vault_uri
      sku              = var.key_vault_sku
      private_endpoint = var.key_vault_enable_private_endpoint
      public_access    = var.key_vault_public_network_access
    } : null

    sentinel = var.deploy_sentinel ? {
      workspace_id = local.log_analytics_workspace_id
      connectors   = var.sentinel_data_connectors
    } : null

    defender = var.deploy_defender ? {
      plans_enabled    = [for plan, config in local.enabled_defender_plans : plan]
      security_contact = var.security_contact_email
      subscriptions    = ["management", "connectivity", "identity"]
    } : null
  }
}
