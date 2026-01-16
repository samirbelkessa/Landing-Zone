# =============================================================================
# MAIN.TF - Microsoft Defender for Cloud Resources
# =============================================================================
# Module: S01-defender-for-cloud
# Purpose: Deploy and configure Microsoft Defender for Cloud
# =============================================================================

# =============================================================================
# SECURITY CENTER SUBSCRIPTION PRICING
# =============================================================================

# -----------------------------------------------------------------------------
# Defender for Servers
# -----------------------------------------------------------------------------
resource "azurerm_security_center_subscription_pricing" "virtual_machines" {
  tier          = local.plan_tier_mapping["VirtualMachines"].tier
  resource_type = "VirtualMachines"
  subplan       = local.plan_tier_mapping["VirtualMachines"].tier == "Standard" ? local.plan_tier_mapping["VirtualMachines"].subplan : null
}

# -----------------------------------------------------------------------------
# Defender for Storage
# -----------------------------------------------------------------------------
resource "azurerm_security_center_subscription_pricing" "storage_accounts" {
  tier          = local.plan_tier_mapping["StorageAccounts"].tier
  resource_type = "StorageAccounts"
  subplan       = local.plan_tier_mapping["StorageAccounts"].tier == "Standard" ? local.plan_tier_mapping["StorageAccounts"].subplan : null
}

# -----------------------------------------------------------------------------
# Defender for SQL
# -----------------------------------------------------------------------------
resource "azurerm_security_center_subscription_pricing" "sql_servers" {
  tier          = local.plan_tier_mapping["SqlServers"].tier
  resource_type = "SqlServers"
}

# -----------------------------------------------------------------------------
# Defender for SQL on VMs
# -----------------------------------------------------------------------------
resource "azurerm_security_center_subscription_pricing" "sql_server_vms" {
  tier          = local.plan_tier_mapping["SqlServerVirtualMachines"].tier
  resource_type = "SqlServerVirtualMachines"
}

# -----------------------------------------------------------------------------
# Defender for App Services
# -----------------------------------------------------------------------------
resource "azurerm_security_center_subscription_pricing" "app_services" {
  tier          = local.plan_tier_mapping["AppServices"].tier
  resource_type = "AppServices"
}

# -----------------------------------------------------------------------------
# Defender for Key Vaults
# -----------------------------------------------------------------------------
resource "azurerm_security_center_subscription_pricing" "key_vaults" {
  tier          = local.plan_tier_mapping["KeyVaults"].tier
  resource_type = "KeyVaults"
}

# -----------------------------------------------------------------------------
# Defender for Resource Manager
# -----------------------------------------------------------------------------
resource "azurerm_security_center_subscription_pricing" "arm" {
  tier          = local.plan_tier_mapping["Arm"].tier
  resource_type = "Arm"
  subplan       = local.plan_tier_mapping["Arm"].tier == "Standard" ? local.plan_tier_mapping["Arm"].subplan : null
}

# -----------------------------------------------------------------------------
# Defender for DNS
# -----------------------------------------------------------------------------
resource "azurerm_security_center_subscription_pricing" "dns" {
  tier          = local.plan_tier_mapping["Dns"].tier
  resource_type = "Dns"
}

# -----------------------------------------------------------------------------
# Defender for Containers
# -----------------------------------------------------------------------------
resource "azurerm_security_center_subscription_pricing" "containers" {
  tier          = local.plan_tier_mapping["Containers"].tier
  resource_type = "Containers"
}

# -----------------------------------------------------------------------------
# Defender for Open Source Databases
# -----------------------------------------------------------------------------
resource "azurerm_security_center_subscription_pricing" "oss_databases" {
  tier          = local.plan_tier_mapping["OpenSourceRelationalDatabases"].tier
  resource_type = "OpenSourceRelationalDatabases"
}

# -----------------------------------------------------------------------------
# Defender for Cosmos DB
# -----------------------------------------------------------------------------
resource "azurerm_security_center_subscription_pricing" "cosmos_db" {
  tier          = local.plan_tier_mapping["CosmosDbs"].tier
  resource_type = "CosmosDbs"
}

# -----------------------------------------------------------------------------
# Defender CSPM (Cloud Security Posture Management)
# -----------------------------------------------------------------------------
resource "azurerm_security_center_subscription_pricing" "cloud_posture" {
  tier          = local.plan_tier_mapping["CloudPosture"].tier
  resource_type = "CloudPosture"
}

# =============================================================================
# SECURITY CENTER CONTACT
# =============================================================================

resource "azurerm_security_center_contact" "this" {
  email               = var.security_contact_email
  phone               = var.security_contact_phone
  alert_notifications = var.alert_notifications_state == "On"
  alerts_to_admins    = var.alerts_to_admins_state == "On"
}

# =============================================================================
# AUTO PROVISIONING
# =============================================================================

resource "azurerm_security_center_auto_provisioning" "this" {
  auto_provision = var.enable_auto_provisioning ? "On" : "Off"
}

# =============================================================================
# WORKSPACE CONFIGURATION (Export to Log Analytics)
# =============================================================================

resource "azurerm_security_center_workspace" "this" {
  scope        = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  workspace_id = var.log_analytics_workspace_id
}

# =============================================================================
# DATA SOURCES
# =============================================================================

data "azurerm_client_config" "current" {}
