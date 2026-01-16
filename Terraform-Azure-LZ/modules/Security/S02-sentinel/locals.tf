# =============================================================================
# LOCALS.TF - Local Values and Computations
# =============================================================================
# Module: S02-sentinel
# Purpose: Microsoft Sentinel SIEM/SOAR deployment
# =============================================================================

locals {
  # ---------------------------------------------------------------------------
  # Tags
  # ---------------------------------------------------------------------------
  default_tags = {
    ManagedBy = "Terraform"
    Module    = "S02-sentinel"
  }

  tags = merge(local.default_tags, var.tags)

  # ---------------------------------------------------------------------------
  # Data Connectors Filter
  # ---------------------------------------------------------------------------
  enabled_connectors = {
    for connector, enabled in {
      azure_active_directory       = var.data_connectors.azure_active_directory
      azure_activity               = var.data_connectors.azure_activity
      defender_for_cloud           = var.data_connectors.defender_for_cloud
      threat_intelligence          = var.data_connectors.threat_intelligence
      microsoft_cloud_app_security = var.data_connectors.microsoft_cloud_app_security
      office_365                   = var.data_connectors.office_365
      microsoft_365_defender       = var.data_connectors.microsoft_365_defender
      azure_advanced_threat_protection = var.data_connectors.azure_advanced_threat_protection
    } : connector => enabled if enabled
  }

  # ---------------------------------------------------------------------------
  # Subscription ID extraction from workspace ID
  # ---------------------------------------------------------------------------
  subscription_id = regex("^/subscriptions/([^/]+)/", var.log_analytics_workspace_id)[0]
}
