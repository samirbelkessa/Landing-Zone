# =============================================================================
# MAIN.TF - Microsoft Sentinel Resources
# =============================================================================
# Module: S02-sentinel
# Purpose: Deploy and configure Microsoft Sentinel SIEM/SOAR
# =============================================================================

# =============================================================================
# SENTINEL ONBOARDING
# =============================================================================

resource "azurerm_sentinel_log_analytics_workspace_onboarding" "this" {
  workspace_id                 = var.log_analytics_workspace_id
  customer_managed_key_enabled = var.customer_managed_key_enabled
}

# =============================================================================
# DATA CONNECTORS
# =============================================================================

# -----------------------------------------------------------------------------
# Azure Active Directory (Entra ID) - Requires P1/P2 License
# -----------------------------------------------------------------------------
resource "azurerm_sentinel_data_connector_azure_active_directory" "this" {
  count = var.data_connectors.azure_active_directory ? 1 : 0

  name                       = "AzureActiveDirectory"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  depends_on = [azurerm_sentinel_log_analytics_workspace_onboarding.this]
}

# -----------------------------------------------------------------------------
# Azure Security Center (Defender for Cloud)
# -----------------------------------------------------------------------------
resource "azurerm_sentinel_data_connector_azure_security_center" "this" {
  count = var.data_connectors.defender_for_cloud ? 1 : 0

  name                       = "AzureSecurityCenter"
  log_analytics_workspace_id = var.log_analytics_workspace_id
  subscription_id            = local.subscription_id

  depends_on = [azurerm_sentinel_log_analytics_workspace_onboarding.this]
}

# -----------------------------------------------------------------------------
# Threat Intelligence Platforms
# -----------------------------------------------------------------------------
resource "azurerm_sentinel_data_connector_threat_intelligence" "this" {
  count = var.data_connectors.threat_intelligence ? 1 : 0

  name                       = "ThreatIntelligence"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  depends_on = [azurerm_sentinel_log_analytics_workspace_onboarding.this]
}

# -----------------------------------------------------------------------------
# Microsoft Cloud App Security (MCAS)
# -----------------------------------------------------------------------------
resource "azurerm_sentinel_data_connector_microsoft_cloud_app_security" "this" {
  count = var.data_connectors.microsoft_cloud_app_security ? 1 : 0

  name                       = "MicrosoftCloudAppSecurity"
  log_analytics_workspace_id = var.log_analytics_workspace_id
  alerts_enabled             = true
  discovery_logs_enabled     = true

  depends_on = [azurerm_sentinel_log_analytics_workspace_onboarding.this]
}

# -----------------------------------------------------------------------------
# Office 365 - Requires License
# -----------------------------------------------------------------------------
resource "azurerm_sentinel_data_connector_office_365" "this" {
  count = var.data_connectors.office_365 ? 1 : 0

  name                       = "Office365"
  log_analytics_workspace_id = var.log_analytics_workspace_id
  exchange_enabled           = true
  sharepoint_enabled         = true
  teams_enabled              = true

  depends_on = [azurerm_sentinel_log_analytics_workspace_onboarding.this]
}

# -----------------------------------------------------------------------------
# Microsoft 365 Defender - Requires M365 E5
# -----------------------------------------------------------------------------
resource "azurerm_sentinel_data_connector_microsoft_defender_advanced_threat_protection" "this" {
  count = var.data_connectors.microsoft_365_defender ? 1 : 0

  name                       = "Microsoft365Defender"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  depends_on = [azurerm_sentinel_log_analytics_workspace_onboarding.this]
}

# -----------------------------------------------------------------------------
# Azure Advanced Threat Protection (Microsoft Defender for Identity)
# -----------------------------------------------------------------------------
resource "azurerm_sentinel_data_connector_azure_advanced_threat_protection" "this" {
  count = var.data_connectors.azure_advanced_threat_protection ? 1 : 0

  name                       = "AzureAdvancedThreatProtection"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  depends_on = [azurerm_sentinel_log_analytics_workspace_onboarding.this]
}

# =============================================================================
# WATCHLISTS
# =============================================================================

resource "azurerm_sentinel_watchlist" "this" {
  for_each = var.watchlists

  name                       = each.key
  log_analytics_workspace_id = var.log_analytics_workspace_id
  display_name               = each.value.display_name
  description                = each.value.description
  item_search_key            = each.value.item_search_key
  labels                     = each.value.labels

  depends_on = [azurerm_sentinel_log_analytics_workspace_onboarding.this]
}

# =============================================================================
# DATA SOURCES
# =============================================================================

data "azurerm_client_config" "current" {}
