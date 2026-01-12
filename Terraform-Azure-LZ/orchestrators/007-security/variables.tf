# =============================================================================
# VARIABLES.TF - Input Variables
# =============================================================================
# Orchestrator: 07-security
# Purpose: Define all input variables for Security deployment
# =============================================================================

# =============================================================================
# REQUIRED - AUTHENTICATION
# =============================================================================

variable "tenant_id" {
  description = "Azure Tenant ID."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.tenant_id))
    error_message = "Tenant ID must be a valid GUID."
  }
}

variable "terraform_state_subscription_id" {
  description = "Subscription ID where Terraform state is stored."
  type        = string
}

variable "management_subscription_id" {
  description = "Management subscription ID (for Key Vault, Sentinel)."
  type        = string
}

variable "connectivity_subscription_id" {
  description = "Connectivity subscription ID (for Private Endpoints)."
  type        = string
}

variable "identity_subscription_id" {
  description = "Identity subscription ID."
  type        = string
}

# =============================================================================
# REQUIRED - REMOTE STATE
# =============================================================================

variable "remote_state_resource_group" {
  description = "Resource group containing Terraform state storage account."
  type        = string
}

variable "remote_state_storage_account" {
  description = "Storage account name for Terraform state."
  type        = string
}

variable "remote_state_container" {
  description = "Container name for Terraform state."
  type        = string
  default     = "tfstate"
}

# =============================================================================
# REMOTE STATE OUTPUT MAPPING
# =============================================================================
# Maps local variable names to actual output names in remote states.
# This avoids hardcoding and allows flexibility across different deployments.

variable "remote_state_outputs" {
  description = "Mapping of remote state output names for cross-orchestrator references."
  type = object({
    # From 03-management
    management = optional(object({
      log_analytics_workspace_id   = optional(string, "m01_log_analytics_id")
      log_analytics_workspace_guid = optional(string, "m01_log_analytics_workspace_id")
      log_analytics_workspace_name = optional(string, "m01_log_analytics_name")
      resource_group_name          = optional(string, "resource_group_name")
    }), {})
    # From 04-connectivity
    connectivity = optional(object({
      hub_vnet_id            = optional(string, "hub_vnet_id")
      hub_subnet_ids         = optional(string, "hub_subnet_ids")
      hub_resource_group_name = optional(string, "hub_resource_group_name")
      private_dns_zone_ids   = optional(string, "private_dns_zone_ids")
    }), {})
  })
  default = {}
}

# =============================================================================
# REQUIRED - COMMON
# =============================================================================

variable "location" {
  description = "Azure region for Security resources."
  type        = string
  default     = "australiaeast"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "prod"
}

# =============================================================================
# REQUIRED - TAGS
# =============================================================================

variable "owner" {
  description = "Owner email for tagging."
  type        = string
}

variable "cost_center" {
  description = "Cost center for tagging."
  type        = string
}

variable "application" {
  description = "Application name for tagging."
  type        = string
  default     = "Platform Security"
}

variable "tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}

# =============================================================================
# MODULE FLAGS
# =============================================================================

variable "deploy_resource_group" {
  description = "Deploy security resource group."
  type        = bool
  default     = true
}

variable "deploy_key_vault" {
  description = "Deploy platform Key Vault."
  type        = bool
  default     = true
}

variable "deploy_sentinel" {
  description = "Deploy Microsoft Sentinel."
  type        = bool
  default     = true
}

variable "deploy_defender" {
  description = "Deploy Microsoft Defender for Cloud."
  type        = bool
  default     = true
}

# =============================================================================
# KEY VAULT CONFIGURATION
# =============================================================================

variable "key_vault_name" {
  description = "Name for the platform Key Vault. If null, will be auto-generated."
  type        = string
  default     = null
}

variable "key_vault_sku" {
  description = "SKU for Key Vault (standard or premium)."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.key_vault_sku)
    error_message = "Key Vault SKU must be 'standard' or 'premium'."
  }
}

variable "key_vault_soft_delete_retention_days" {
  description = "Soft delete retention days for Key Vault."
  type        = number
  default     = 90
}

variable "key_vault_enable_purge_protection" {
  description = "Enable purge protection for Key Vault."
  type        = bool
  default     = true
}

variable "key_vault_enable_private_endpoint" {
  description = "Enable private endpoint for Key Vault."
  type        = bool
  default     = true
}

variable "key_vault_public_network_access" {
  description = "Enable public network access for Key Vault."
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_key" {
  description = "Key name of the subnet in hub_subnet_ids map for Private Endpoints."
  type        = string
  default     = "SharedServicesSubnet"
}

variable "keyvault_dns_zone_key" {
  description = "Key name of the Key Vault Private DNS zone in private_dns_zone_ids map."
  type        = string
  default     = "privatelink.vaultcore.azure.net"
}

variable "private_endpoint_resource_group" {
  description = "Resource group for Private Endpoint. If null, uses hub_resource_group_name from remote state."
  type        = string
  default     = null
}

# =============================================================================
# SENTINEL CONFIGURATION
# =============================================================================

variable "sentinel_data_connectors" {
  description = <<-EOT
    Sentinel data connectors to enable.
    
    IMPORTANT: azure_active_directory requires Azure AD Premium P1/P2 or Microsoft 365 E5 license.
    Without the appropriate license, enabling this connector will fail with 'InvalidLicense' error.
  EOT
  type = object({
    azure_active_directory = optional(bool, false)  # Requires Entra ID P1/P2 license
    azure_activity         = optional(bool, true)   # Free - Azure Activity logs
    defender_for_cloud     = optional(bool, true)   # Included with Defender plans
    threat_intelligence    = optional(bool, true)   # Free - TI indicators
  })
  default = {}
}

# =============================================================================
# DEFENDER FOR CLOUD CONFIGURATION
# =============================================================================

variable "defender_plans" {
  description = "Defender for Cloud plans to enable."
  type = object({
    virtual_machines = optional(object({
      enabled = optional(bool, true)
      subplan = optional(string, "P2")
    }), {})
    storage_accounts = optional(object({
      enabled = optional(bool, true)
      subplan = optional(string, "DefenderForStorageV2")
    }), {})
    sql_servers = optional(object({
      enabled = optional(bool, true)
    }), {})
    app_services = optional(object({
      enabled = optional(bool, true)
    }), {})
    key_vaults = optional(object({
      enabled = optional(bool, true)
      subplan = optional(string, "PerKeyVault")
    }), {})
    arm = optional(object({
      enabled = optional(bool, true)
      subplan = optional(string, "PerSubscription")
    }), {})
    containers = optional(object({
      enabled = optional(bool, true)
    }), {})
    dns = optional(object({
      enabled = optional(bool, true)
    }), {})
  })
  default = {}
}

variable "defender_subscriptions" {
  description = "List of subscription IDs to enable Defender on. If empty, uses platform subscriptions."
  type        = list(string)
  default     = []
}

variable "security_contact_email" {
  description = "Email address for security alerts."
  type        = string
}

variable "security_contact_phone" {
  description = "Phone number for security alerts (optional)."
  type        = string
  default     = null
}

variable "security_alert_notifications" {
  description = "Enable email notifications for security alerts."
  type        = bool
  default     = true
}

variable "security_alerts_to_admins" {
  description = "Send security alerts to subscription admins."
  type        = bool
  default     = true
}
