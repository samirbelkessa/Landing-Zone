# =============================================================================
# MAIN.TF - Security Resources
# =============================================================================
# Orchestrator: 07-security
# Purpose: Deploy Defender for Cloud, Sentinel, and Key Vault
# =============================================================================

# =============================================================================
# RESOURCE GROUP
# =============================================================================

resource "azurerm_resource_group" "security" {
  count = var.deploy_resource_group ? 1 : 0

  name     = local.resource_group_name
  location = var.location

  tags = local.tags
}

# =============================================================================
# S03 - KEY VAULT (Platform Secrets)
# =============================================================================

resource "azurerm_key_vault" "platform" {
  count = var.deploy_key_vault ? 1 : 0

  name                = local.key_vault_name
  location            = var.location
  resource_group_name = var.deploy_resource_group ? azurerm_resource_group.security[0].name : local.management_resource_group
  tenant_id           = var.tenant_id

  sku_name = var.key_vault_sku

  # Security settings
  enabled_for_deployment          = false
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = false
  enable_rbac_authorization       = true
  purge_protection_enabled        = var.key_vault_enable_purge_protection
  soft_delete_retention_days      = var.key_vault_soft_delete_retention_days
  public_network_access_enabled   = var.key_vault_public_network_access

  # Network ACLs
  network_acls {
    bypass         = "AzureServices"
    default_action = var.key_vault_public_network_access ? "Allow" : "Deny"
  }

  tags = local.tags
}

# -----------------------------------------------------------------------------
# Key Vault Diagnostic Settings
# -----------------------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  count = var.deploy_key_vault && local.log_analytics_workspace_id != null ? 1 : 0

  name                       = "diag-${local.key_vault_name}-law"
  target_resource_id         = azurerm_key_vault.platform[0].id
  log_analytics_workspace_id = local.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# -----------------------------------------------------------------------------
# Key Vault Private Endpoint (in Hub VNet)
# -----------------------------------------------------------------------------
resource "azurerm_private_endpoint" "key_vault" {
  count = var.deploy_key_vault && var.key_vault_enable_private_endpoint && local.private_endpoint_subnet_id != null ? 1 : 0

  provider = azurerm.connectivity

  name                = "pe-${local.key_vault_name}"
  location            = var.location
  resource_group_name = coalesce(var.private_endpoint_resource_group, local.hub_resource_group_name)
  subnet_id           = local.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${local.key_vault_name}"
    private_connection_resource_id = azurerm_key_vault.platform[0].id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  dynamic "private_dns_zone_group" {
    for_each = local.keyvault_dns_zone_id != null ? [1] : []

    content {
      name                 = "default"
      private_dns_zone_ids = [local.keyvault_dns_zone_id]
    }
  }

  tags = local.tags
}

# =============================================================================
# S02 - MICROSOFT SENTINEL
# =============================================================================

# -----------------------------------------------------------------------------
# Sentinel Onboarding (on existing Log Analytics)
# -----------------------------------------------------------------------------
resource "azurerm_sentinel_log_analytics_workspace_onboarding" "sentinel" {
  count = var.deploy_sentinel && local.log_analytics_workspace_id != null ? 1 : 0

  workspace_id                 = local.log_analytics_workspace_id
  customer_managed_key_enabled = false
}

# -----------------------------------------------------------------------------
# Data Connector - Azure Active Directory (Entra ID)
# -----------------------------------------------------------------------------
resource "azurerm_sentinel_data_connector_azure_active_directory" "aad" {
  count = var.deploy_sentinel && var.sentinel_data_connectors.azure_active_directory && local.log_analytics_workspace_id != null ? 1 : 0

  name                       = "AzureActiveDirectory"
  log_analytics_workspace_id = local.log_analytics_workspace_id

  depends_on = [azurerm_sentinel_log_analytics_workspace_onboarding.sentinel]
}

# -----------------------------------------------------------------------------
# Data Connector - Azure Security Center (Defender for Cloud)
# -----------------------------------------------------------------------------
resource "azurerm_sentinel_data_connector_azure_security_center" "defender" {
  count = var.deploy_sentinel && var.sentinel_data_connectors.defender_for_cloud && local.log_analytics_workspace_id != null ? 1 : 0

  name                       = "AzureSecurityCenter"
  log_analytics_workspace_id = local.log_analytics_workspace_id
  subscription_id            = var.management_subscription_id

  depends_on = [azurerm_sentinel_log_analytics_workspace_onboarding.sentinel]
}

# -----------------------------------------------------------------------------
# Data Connector - Threat Intelligence
# -----------------------------------------------------------------------------
resource "azurerm_sentinel_data_connector_threat_intelligence" "ti" {
  count = var.deploy_sentinel && var.sentinel_data_connectors.threat_intelligence && local.log_analytics_workspace_id != null ? 1 : 0

  name                       = "ThreatIntelligence"
  log_analytics_workspace_id = local.log_analytics_workspace_id

  depends_on = [azurerm_sentinel_log_analytics_workspace_onboarding.sentinel]
}

# =============================================================================
# S01 - MICROSOFT DEFENDER FOR CLOUD
# =============================================================================

# -----------------------------------------------------------------------------
# Defender Plans - Management Subscription
# -----------------------------------------------------------------------------
resource "azurerm_security_center_subscription_pricing" "management" {
  for_each = var.deploy_defender ? local.enabled_defender_plans : {}

  tier          = "Standard"
  resource_type = each.key
  subplan       = each.value.subplan
}

# -----------------------------------------------------------------------------
# Time Sleep - Wait for Management plans to complete
# -----------------------------------------------------------------------------
resource "time_sleep" "wait_after_management_defender" {
  count = var.deploy_defender ? 1 : 0

  depends_on      = [azurerm_security_center_subscription_pricing.management]
  create_duration = "30s"
}

# -----------------------------------------------------------------------------
# Defender Plans - Connectivity Subscription
# -----------------------------------------------------------------------------
resource "azurerm_security_center_subscription_pricing" "connectivity" {
  for_each = var.deploy_defender ? local.enabled_defender_plans : {}

  provider = azurerm.connectivity

  tier          = "Standard"
  resource_type = each.key
  subplan       = each.value.subplan

  depends_on = [time_sleep.wait_after_management_defender]
}

# -----------------------------------------------------------------------------
# Time Sleep - Wait for Connectivity plans to complete
# -----------------------------------------------------------------------------
resource "time_sleep" "wait_after_connectivity_defender" {
  count = var.deploy_defender ? 1 : 0

  depends_on      = [azurerm_security_center_subscription_pricing.connectivity]
  create_duration = "30s"
}

# -----------------------------------------------------------------------------
# Defender Plans - Identity Subscription
# -----------------------------------------------------------------------------
resource "azurerm_security_center_subscription_pricing" "identity" {
  for_each = var.deploy_defender ? local.enabled_defender_plans : {}

  provider = azurerm.identity

  tier          = "Standard"
  resource_type = each.key
  subplan       = each.value.subplan

  depends_on = [time_sleep.wait_after_connectivity_defender]
}

# -----------------------------------------------------------------------------
# Security Contact - Management Subscription
# -----------------------------------------------------------------------------
resource "azurerm_security_center_contact" "management" {
  count = var.deploy_defender ? 1 : 0

  name                = "security-contact-management"
  email               = var.security_contact_email
  phone               = var.security_contact_phone
  alert_notifications = var.security_alert_notifications
  alerts_to_admins    = var.security_alerts_to_admins
}

# -----------------------------------------------------------------------------
# Security Contact - Connectivity Subscription
# -----------------------------------------------------------------------------
resource "azurerm_security_center_contact" "connectivity" {
  count = var.deploy_defender ? 1 : 0

  provider = azurerm.connectivity

  name                = "security-contact-connectivity"
  email               = var.security_contact_email
  phone               = var.security_contact_phone
  alert_notifications = var.security_alert_notifications
  alerts_to_admins    = var.security_alerts_to_admins
}

# -----------------------------------------------------------------------------
# Security Contact - Identity Subscription
# -----------------------------------------------------------------------------
resource "azurerm_security_center_contact" "identity" {
  count = var.deploy_defender ? 1 : 0

  provider = azurerm.identity

  name                = "security-contact-identity"
  email               = var.security_contact_email
  phone               = var.security_contact_phone
  alert_notifications = var.security_alert_notifications
  alerts_to_admins    = var.security_alerts_to_admins
}

# -----------------------------------------------------------------------------
# NOTE: Auto Provisioning (Log Analytics Agent) is DEPRECATED
# Microsoft now uses Azure Monitor Agent (AMA) with Data Collection Rules
# Configured via 03-management orchestrator
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Workspace Settings - Link Defender to Log Analytics (Management)
# -----------------------------------------------------------------------------
resource "azurerm_security_center_workspace" "management" {
  count = var.deploy_defender && local.log_analytics_workspace_id != null ? 1 : 0

  scope        = "/subscriptions/${var.management_subscription_id}"
  workspace_id = local.log_analytics_workspace_id
}

# -----------------------------------------------------------------------------
# Workspace Settings - Link Defender to Log Analytics (Connectivity)
# -----------------------------------------------------------------------------
resource "azurerm_security_center_workspace" "connectivity" {
  count = var.deploy_defender && local.log_analytics_workspace_id != null ? 1 : 0

  provider = azurerm.connectivity

  scope        = "/subscriptions/${var.connectivity_subscription_id}"
  workspace_id = local.log_analytics_workspace_id
}

# -----------------------------------------------------------------------------
# Workspace Settings - Link Defender to Log Analytics (Identity)
# -----------------------------------------------------------------------------
resource "azurerm_security_center_workspace" "identity" {
  count = var.deploy_defender && local.log_analytics_workspace_id != null ? 1 : 0

  provider = azurerm.identity

  scope        = "/subscriptions/${var.identity_subscription_id}"
  workspace_id = local.log_analytics_workspace_id
}
