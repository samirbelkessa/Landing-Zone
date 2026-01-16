# =============================================================================
# REMOTE-STATE.TF - Remote State Data Sources
# =============================================================================
# Orchestrator: 007-security
# Purpose: Read outputs from other orchestrators via remote state
# =============================================================================

# =============================================================================
# MANAGEMENT ORCHESTRATOR STATE
# =============================================================================

data "terraform_remote_state" "management" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.remote_state_config.resource_group_name
    storage_account_name = var.remote_state_config.storage_account_name
    container_name       = var.remote_state_config.container_name
    key                  = "Management"
  }
}

# =============================================================================
# CONNECTIVITY ORCHESTRATOR STATE
# =============================================================================

data "terraform_remote_state" "connectivity" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.remote_state_config.resource_group_name
    storage_account_name = var.remote_state_config.storage_account_name
    container_name       = var.remote_state_config.container_name
    key                  = "Connectivity"
  }
}

# =============================================================================
# FOUNDATION ORCHESTRATOR STATE (Optional)
# =============================================================================

data "terraform_remote_state" "foundation" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.remote_state_config.resource_group_name
    storage_account_name = var.remote_state_config.storage_account_name
    container_name       = var.remote_state_config.container_name
    key                  = "Foundation"
  }
}



# =============================================================================
# MAIN.TF - Security Orchestrator (Consolidated)
# =============================================================================
# Orchestrator: 007-security
# Components:
#   - Resource Group
#   - S01: Microsoft Defender for Cloud (Custom Module)
#   - S02: Microsoft Sentinel (Custom Module)
#   - S03: Azure Key Vault (AVM Direct)
#   - S04: Private Endpoint (Integrated in S03 AVM)
#   - S05: Network Security Group + Baseline Rules (AVM Direct)
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
# S01 - MICROSOFT DEFENDER FOR CLOUD (Custom Module)
# =============================================================================
# Deploys Defender plans across subscription with threat protection
# Dependencies: M01 (Log Analytics Workspace)
# =============================================================================

module "defender" {
  source = "../../modules/Security/S01-defender-for-cloud"
  count  = var.deploy_defender ? 1 : 0

  # Security contact configuration
  security_contact_email = var.security_contact_email
  security_contact_phone = var.security_contact_phone

  # Log Analytics integration (from remote state)
  log_analytics_workspace_id = local.log_analytics_workspace_id

  # Defender plans configuration
  defender_plans = var.defender_plans

  # Auto-provisioning
  enable_auto_provisioning = true

  # Alert configuration
  alert_notifications_state        = "On"
  alert_notifications_min_severity = "Medium"
  alerts_to_admins_state           = "On"

  tags = local.tags
}

# =============================================================================
# S02 - MICROSOFT SENTINEL (Custom Module)
# =============================================================================
# Deploys Sentinel SIEM/SOAR on Log Analytics Workspace
# Dependencies: M01 (Log Analytics Workspace), S01 (Defender - optional)
# =============================================================================

module "sentinel" {
  source = "../../modules/Security/S02-sentinel"
  count  = var.deploy_sentinel && local.log_analytics_workspace_id != null ? 1 : 0

  # Log Analytics Workspace (from remote state)
  log_analytics_workspace_id   = local.log_analytics_workspace_id
  log_analytics_workspace_name = local.log_analytics_workspace_name
  resource_group_name          = local.management_resource_group

  # Data connectors configuration
  data_connectors = var.sentinel_data_connectors

  # Optional features
  enable_ueba               = false
  customer_managed_key_enabled = false

  tags = local.tags

  depends_on = [module.defender]
}

# =============================================================================
# S03 - KEY VAULT (AVM Direct Call)
# =============================================================================
# Deploys platform Key Vault with Private Endpoint and RBAC
# Dependencies: Connectivity (Subnet, DNS Zone), M01 (Log Analytics)
# AVM Source: Azure/avm-res-keyvault-vault/azurerm v0.10.2
# =============================================================================

module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.2"
  count   = var.deploy_key_vault ? 1 : 0

  # Basic configuration
  name                = local.key_vault_name
  location            = var.location
  resource_group_name = var.deploy_resource_group ? azurerm_resource_group.security[0].name : local.management_resource_group
  tenant_id           = var.tenant_id

  # SKU and security settings
  sku_name                   = var.key_vault_sku
  purge_protection_enabled   = var.key_vault_enable_purge_protection
  soft_delete_retention_days = var.key_vault_soft_delete_retention_days

  # Network access
  public_network_access_enabled = var.key_vault_public_network_access

  # Network ACLs (deny by default when private endpoint is enabled)
  network_acls = var.key_vault_enable_private_endpoint ? {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = []
    virtual_network_subnet_ids = []
  } : null

  # ---------------------------------------------------------------------------
  # S04 - PRIVATE ENDPOINT (Integrated in AVM)
  # ---------------------------------------------------------------------------
  # Private Endpoint is integrated directly in the Key Vault AVM module
  # No need for separate S04 module call
  # ---------------------------------------------------------------------------
  private_endpoints = var.key_vault_enable_private_endpoint && local.private_endpoint_subnet_id != null ? {
    primary = {
      name                          = "pe-${local.key_vault_name}"
      subnet_resource_id            = local.private_endpoint_subnet_id
      private_dns_zone_resource_ids = local.keyvault_dns_zone_id != null ? [local.keyvault_dns_zone_id] : []
      
      # Optional: specify resource group for PE (defaults to KV resource group)
      # resource_group_name = local.hub_resource_group_name
    }
  } : {}

  # Diagnostic settings (from remote state)
  diagnostic_settings = local.log_analytics_workspace_id != null ? {
    to_law = {
      name                  = "diag-${local.key_vault_name}-law"
      workspace_resource_id = local.log_analytics_workspace_id
      log_groups            = ["allLogs"]
      metric_categories     = ["AllMetrics"]
    }
  } : {}

  # Disable telemetry for enterprise deployments
  enable_telemetry = false

  tags = local.tags
}

# =============================================================================
# S05 - NETWORK SECURITY GROUP + BASELINE RULES (AVM Direct Call)
# =============================================================================
# Deploys NSG with baseline rules for Shared Services subnet
# Dependencies: Connectivity (for association), M01 (Log Analytics for diagnostics)
# AVM Source: Azure/avm-res-network-networksecuritygroup/azurerm v0.5.1
# =============================================================================

module "nsg_shared_services" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.1"
  count   = var.deploy_nsg_baseline ? 1 : 0

  providers = {
    azurerm = azurerm.connectivity
  }

  # Basic configuration
  name                = local.nsg_name
  location            = var.location
  resource_group_name = local.hub_resource_group_name

  # ---------------------------------------------------------------------------
  # Security Rules - Merged Baseline + Custom
  # ---------------------------------------------------------------------------
  # Baseline rules are defined in nsg-baseline-rules.tf
  # Custom rules can be passed via var.custom_nsg_rules
  # Merge happens in locals.tf: local.all_nsg_rules
  # ---------------------------------------------------------------------------
  security_rules = local.all_nsg_rules

  # Diagnostic settings (from remote state)
  diagnostic_settings = local.log_analytics_workspace_id != null ? {
    to_law = {
      name                  = "diag-${local.nsg_name}-law"
      workspace_resource_id = local.log_analytics_workspace_id
      log_groups            = ["allLogs"]
      metric_categories     = ["AllMetrics"]
    }
  } : {}

  # Disable telemetry for enterprise deployments
  enable_telemetry = false

  tags = local.tags
}

# =============================================================================
# DATA SOURCES
# =============================================================================

data "azurerm_client_config" "current" {}
