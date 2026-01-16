# =============================================================================
# VARIABLES.TF - Input Variables
# =============================================================================
# Orchestrator: 007-security
# Purpose: Security components deployment (Defender, Sentinel, Key Vault, NSG)
# =============================================================================

# =============================================================================
# SUBSCRIPTION CONFIGURATION
# =============================================================================

variable "tenant_id" {
  description = "Azure Tenant ID."
  type        = string

  validation {
    condition     = can(regex("^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$", var.tenant_id))
    error_message = "Must be a valid GUID."
  }
}

variable "management_subscription_id" {
  description = "Subscription ID for Management resources."
  type        = string

  validation {
    condition     = can(regex("^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$", var.management_subscription_id))
    error_message = "Must be a valid GUID."
  }
}

variable "connectivity_subscription_id" {
  description = "Subscription ID for Connectivity resources."
  type        = string

  validation {
    condition     = can(regex("^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$", var.connectivity_subscription_id))
    error_message = "Must be a valid GUID."
  }
}

variable "identity_subscription_id" {
  description = "Subscription ID for Identity resources."
  type        = string

  validation {
    condition     = can(regex("^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$", var.identity_subscription_id))
    error_message = "Must be a valid GUID."
  }
}

# =============================================================================
# LOCATION CONFIGURATION
# =============================================================================

variable "location" {
  description = "Primary Azure region for deployment."
  type        = string
  default     = "australiaeast"
}

variable "location_secondary" {
  description = "Secondary Azure region for DR."
  type        = string
  default     = "australiasoutheast"
}

# =============================================================================
# NAMING CONFIGURATION
# =============================================================================

variable "organization" {
  description = "Organization name for resource naming."
  type        = string
  default     = "intelly"
}

variable "environment" {
  description = "Environment name (prod, nonprod, dev, test, sandbox)."
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["prod", "nonprod", "dev", "test", "sandbox"], var.environment)
    error_message = "Environment must be one of: prod, nonprod, dev, test, sandbox."
  }
}

# =============================================================================
# REMOTE STATE CONFIGURATION
# =============================================================================

variable "remote_state_config" {
  description = "Configuration for reading remote state from other orchestrators."
  type = object({
    resource_group_name  = string
    storage_account_name = string
    container_name       = string
  })
}

variable "remote_state_outputs" {
  description = "Mapping of remote state output keys."
  type = object({
    management = object({
      log_analytics_workspace_id   = optional(string, "log_analytics_workspace_id")
      log_analytics_workspace_name = optional(string, "log_analytics_workspace_name")
      log_analytics_workspace_guid = optional(string, "log_analytics_workspace_guid")
      resource_group_name          = optional(string, "resource_group_name")
    })
    connectivity = object({
      hub_vnet_id             = optional(string, "hub_vnet_id")
      hub_resource_group_name = optional(string, "hub_resource_group_name")
      hub_subnet_ids          = optional(string, "hub_subnet_ids")
      private_dns_zone_ids    = optional(string, "private_dns_zone_ids")
    })
  })
  default = {
    management = {
      log_analytics_workspace_id   = "log_analytics_workspace_id"
      log_analytics_workspace_name = "log_analytics_workspace_name"
      log_analytics_workspace_guid = "log_analytics_workspace_guid"
      resource_group_name          = "resource_group_name"
    }
    connectivity = {
      hub_vnet_id             = "hub_vnet_id"
      hub_resource_group_name = "hub_resource_group_name"
      hub_subnet_ids          = "hub_subnet_ids"
      private_dns_zone_ids    = "private_dns_zone_ids"
    }
  }
}

# =============================================================================
# FEATURE FLAGS
# =============================================================================

variable "deploy_resource_group" {
  description = "Deploy dedicated security resource group."
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

variable "deploy_nsg_baseline" {
  description = "Deploy baseline NSG for shared services."
  type        = bool
  default     = true
}

# =============================================================================
# KEY VAULT CONFIGURATION
# =============================================================================

variable "key_vault_name" {
  description = "Name for the platform Key Vault. If null, auto-generated."
  type        = string
  default     = null
}

variable "key_vault_sku" {
  description = "SKU for Key Vault (standard or premium)."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.key_vault_sku)
    error_message = "Must be standard or premium."
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
  description = "Key name of subnet in hub_subnet_ids for Private Endpoints."
  type        = string
  default     = "SharedServicesSubnet"
}

variable "keyvault_dns_zone_key" {
  description = "Key name of Key Vault Private DNS zone."
  type        = string
  default     = "privatelink.vaultcore.azure.net"
}

# =============================================================================
# DEFENDER CONFIGURATION
# =============================================================================

variable "security_contact_email" {
  description = "Email address for security alerts."
  type        = string
}

variable "security_contact_phone" {
  description = "Phone number for security alerts."
  type        = string
  default     = null
}

variable "defender_plans" {
  description = "Map of Defender plans to enable."
  type = map(object({
    enabled = bool
    subplan = optional(string, null)
  }))
  default = {
    VirtualMachines = {
      enabled = true
      subplan = "P2"
    }
    StorageAccounts = {
      enabled = true
      subplan = "DefenderForStorageV2"
    }
    SqlServers = {
      enabled = true
      subplan = null
    }
    SqlServerVirtualMachines = {
      enabled = true
      subplan = null
    }
    AppServices = {
      enabled = true
      subplan = null
    }
    KeyVaults = {
      enabled = true
      subplan = null
    }
    Arm = {
      enabled = true
      subplan = "PerApiCall"
    }
    Dns = {
      enabled = true
      subplan = null
    }
    Containers = {
      enabled = true
      subplan = null
    }
    OpenSourceRelationalDatabases = {
      enabled = false
      subplan = null
    }
    CosmosDbs = {
      enabled = false
      subplan = null
    }
    CloudPosture = {
      enabled = true
      subplan = null
    }
  }
}

# =============================================================================
# SENTINEL CONFIGURATION
# =============================================================================

variable "sentinel_data_connectors" {
  description = "Sentinel data connectors to enable."
  type = object({
    azure_active_directory       = optional(bool, false)
    azure_activity               = optional(bool, true)
    defender_for_cloud           = optional(bool, true)
    threat_intelligence          = optional(bool, true)
    microsoft_cloud_app_security = optional(bool, false)
    office_365                   = optional(bool, false)
    microsoft_365_defender       = optional(bool, false)
    azure_advanced_threat_protection = optional(bool, false)
  })
  default = {
    azure_active_directory       = false
    azure_activity               = true
    defender_for_cloud           = true
    threat_intelligence          = true
    microsoft_cloud_app_security = false
    office_365                   = false
    microsoft_365_defender       = false
    azure_advanced_threat_protection = false
  }
}

# =============================================================================
# NSG CONFIGURATION
# =============================================================================

variable "enable_nsg_baseline_rules" {
  description = "Enable baseline NSG rules from standard ruleset."
  type        = bool
  default     = true
}

variable "custom_nsg_rules" {
  description = "Additional custom NSG rules to merge with baseline."
  type = map(object({
    access                                     = string
    direction                                  = string
    priority                                   = number
    protocol                                   = string
    name                                       = string
    description                                = optional(string)
    source_address_prefix                      = optional(string)
    source_address_prefixes                    = optional(set(string))
    source_port_range                          = optional(string)
    source_port_ranges                         = optional(set(string))
    destination_address_prefix                 = optional(string)
    destination_address_prefixes               = optional(set(string))
    destination_port_range                     = optional(string)
    destination_port_ranges                    = optional(set(string))
    source_application_security_group_ids      = optional(set(string))
    destination_application_security_group_ids = optional(set(string))
  }))
  default = {}
}

# =============================================================================
# TAGS
# =============================================================================

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "owner" {
  description = "Owner email for resource tagging."
  type        = string
}

variable "cost_center" {
  description = "Cost center for resource tagging."
  type        = string
}
