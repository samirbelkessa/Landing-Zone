# =============================================================================
# VARIABLES.TF - Input Variables
# =============================================================================
# Orchestrator: 06-landing-zones
# Purpose: Define inputs for Landing Zone deployment
# Modes: Greenfield (create subscriptions) or Brownfield (existing subscriptions)
# =============================================================================

# =============================================================================
# REQUIRED VARIABLES - Authentication & Remote State
# =============================================================================

variable "tenant_id" {
  description = "Azure Tenant ID for all subscriptions."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.tenant_id))
    error_message = "Tenant ID must be a valid GUID."
  }
}

variable "terraform_state_subscription_id" {
  description = "Subscription ID where the Terraform state Storage Account is located."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.terraform_state_subscription_id))
    error_message = "Subscription ID must be a valid GUID."
  }
}

variable "management_subscription_id" {
  description = "Subscription ID for the Management/Platform subscription."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.management_subscription_id))
    error_message = "Subscription ID must be a valid GUID."
  }
}

variable "connectivity_subscription_id" {
  description = "Subscription ID for the Connectivity subscription (Hub VNets, Firewall, DNS)."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.connectivity_subscription_id))
    error_message = "Subscription ID must be a valid GUID."
  }
}

# -----------------------------------------------------------------------------
# REMOTE STATE CONFIGURATION
# -----------------------------------------------------------------------------

variable "tfstate_subscription_id" {
  description = "Subscription ID where the Terraform state Storage Account is located."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.tfstate_subscription_id))
    error_message = "Subscription ID must be a valid GUID."
  }
}

variable "remote_state_resource_group" {
  description = "Resource Group name containing the Terraform state storage account."
  type        = string
}

variable "remote_state_storage_account" {
  description = "Storage Account name for Terraform remote state."
  type        = string
}

variable "remote_state_container" {
  description = "Blob container name for Terraform state files."
  type        = string
  default     = "tfstate"
}

# =============================================================================
# SUBSCRIPTION BILLING CONFIGURATION (Required for Greenfield mode)
# =============================================================================

variable "default_billing_scope" {
  description = <<-EOT
    Default billing scope for creating new subscriptions (Greenfield mode).
    Required format depends on agreement type:
    - EA: /providers/Microsoft.Billing/billingAccounts/{billingAccountId}/enrollmentAccounts/{enrollmentAccountId}
    - MCA: /providers/Microsoft.Billing/billingAccounts/{billingAccountId}/billingProfiles/{billingProfileId}/invoiceSections/{invoiceSectionId}
    - MPA: /providers/Microsoft.Billing/billingAccounts/{billingAccountId}/customers/{customerId}
  EOT
  type        = string
  default     = ""
}

# =============================================================================
# LANDING ZONES CONFIGURATION
# =============================================================================

variable "landing_zones" {
  description = <<-EOT
    Map of Landing Zones to deploy. Supports two modes:

    **BROWNFIELD MODE** (existing subscription):
    ```hcl
    "app1-prod" = {
      subscription_id = "existing-subscription-guid"
      archetype       = "online-prod"
      # ... networking config
    }
    ```

    **GREENFIELD MODE** (create new subscription):
    ```hcl
    "app2-prod" = {
      create_subscription       = true
      subscription_alias        = "sub-app2-prod"
      subscription_display_name = "App2 Production"
      subscription_workload     = "Production"
      # subscription_billing_scope = "..." # Optional, uses default_billing_scope if not set
      archetype                 = "online-prod"
      # ... networking config
    }
    ```
  EOT

  type = map(object({
    # -------------------------------------------------------------------------
    # SUBSCRIPTION MODE SELECTION
    # -------------------------------------------------------------------------
    # BROWNFIELD: Use existing subscription
    subscription_id = optional(string)

    # GREENFIELD: Create new subscription
    create_subscription        = optional(bool, false)
    subscription_alias         = optional(string)
    subscription_display_name  = optional(string)
    subscription_workload      = optional(string, "Production") # "Production" or "DevTest"
    subscription_billing_scope = optional(string)               # Override default_billing_scope

    # -------------------------------------------------------------------------
    # ARCHETYPE & LOCATION
    # -------------------------------------------------------------------------
    archetype      = string # online-prod, online-nonprod, corp-prod, corp-nonprod, sandbox
    location       = optional(string, "australiaeast")
    location_short = optional(string)

    # -------------------------------------------------------------------------
    # NETWORKING
    # -------------------------------------------------------------------------
    vnet_name     = optional(string)
    address_space = list(string)
    dns_servers   = optional(list(string)) # Override DNS servers (default: from Hub)

    # Subnets configuration
    subnets = map(object({
      address_prefix                    = string
      private_endpoint_network_policies = optional(string, "Enabled")
      service_endpoints                 = optional(list(string), [])
      delegation = optional(object({
        name         = string
        service_name = string
        actions      = optional(list(string))
      }))
      network_security_group_id = optional(string)
      route_table_id            = optional(string) # Override route table (default: from Hub)
    }))

    # -------------------------------------------------------------------------
    # RESOURCE GROUPS
    # -------------------------------------------------------------------------
    resource_groups = optional(map(object({
      name     = string
      location = optional(string)
      tags     = optional(map(string))
    })), {})

    # -------------------------------------------------------------------------
    # RBAC ASSIGNMENTS
    # -------------------------------------------------------------------------
    role_assignments = optional(map(object({
      principal_id         = string
      role_definition_name = optional(string, "Contributor")
      role_definition_id   = optional(string)
      scope                = optional(string) # subscription, rg:<n>, or resource ID
    })), {})

    # -------------------------------------------------------------------------
    # BUDGET CONFIGURATION
    # -------------------------------------------------------------------------
    budget = optional(object({
      amount     = number
      time_grain = optional(string, "Monthly")
      start_date = optional(string)
      end_date   = optional(string)
      notifications = optional(map(object({
        threshold      = number
        operator       = optional(string, "GreaterThan")
        contact_emails = list(string)
        contact_roles  = optional(list(string))
      })))
    }))

    # -------------------------------------------------------------------------
    # TAGS
    # -------------------------------------------------------------------------
    tags = map(string)

    # -------------------------------------------------------------------------
    # FEATURE FLAGS
    # -------------------------------------------------------------------------
    enable_private_dns_zone_links = optional(bool, true)
    enable_hub_peering            = optional(bool, true)
  }))

  default = {}

  # Validation: Archetype must be valid
  validation {
    condition = alltrue([
      for lz_key, lz in var.landing_zones :
      contains(["online-prod", "online-nonprod", "corp-prod", "corp-nonprod", "sandbox"], lz.archetype)
    ])
    error_message = "Archetype must be one of: online-prod, online-nonprod, corp-prod, corp-nonprod, sandbox."
  }

  # Validation: Location must be valid
  validation {
    condition = alltrue([
      for lz_key, lz in var.landing_zones :
      contains(["australiaeast", "australiasoutheast"], lz.location)
    ])
    error_message = "Location must be either 'australiaeast' or 'australiasoutheast'."
  }

  # Validation: Either subscription_id OR create_subscription must be set
  validation {
    condition = alltrue([
      for lz_key, lz in var.landing_zones :
      (lz.subscription_id != null && lz.subscription_id != "") || lz.create_subscription == true
    ])
    error_message = "Each Landing Zone must either have 'subscription_id' (Brownfield) or 'create_subscription = true' (Greenfield)."
  }

  # Validation: Greenfield requires subscription_alias and subscription_display_name
  validation {
    condition = alltrue([
      for lz_key, lz in var.landing_zones :
      lz.create_subscription != true || (
        lz.subscription_alias != null && lz.subscription_alias != "" &&
        lz.subscription_display_name != null && lz.subscription_display_name != ""
      )
    ])
    error_message = "Greenfield Landing Zones (create_subscription = true) require 'subscription_alias' and 'subscription_display_name'."
  }

  # Validation: subscription_workload must be valid
  validation {
    condition = alltrue([
      for lz_key, lz in var.landing_zones :
      lz.subscription_workload == null || contains(["Production", "DevTest"], lz.subscription_workload)
    ])
    error_message = "subscription_workload must be either 'Production' or 'DevTest'."
  }
}

# =============================================================================
# OPTIONAL VARIABLES - Defaults & Behavior
# =============================================================================

variable "default_tags" {
  description = "Default tags applied to all resources. Merged with Landing Zone specific tags."
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Module    = "06-landing-zones"
  }
}

variable "enable_resource_providers_registration" {
  description = "Enable automatic registration of required Azure resource providers."
  type        = bool
  default     = true
}

variable "resource_providers" {
  description = "List of Azure resource providers to register in each Landing Zone subscription."
  type        = list(string)
  default = [
    "Microsoft.Compute",
    "Microsoft.Network",
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.Web",
    "Microsoft.Sql",
    "Microsoft.ContainerRegistry",
    "Microsoft.ContainerService",
    "Microsoft.Insights",
    "Microsoft.OperationalInsights",
    "Microsoft.ManagedIdentity",
    "Microsoft.Authorization"
  ]
}

variable "private_dns_zones_to_link" {
  description = "List of Private DNS Zone names to link to spoke VNets. If empty, links all zones from connectivity."
  type        = list(string)
  default     = []
}

variable "private_dns_zones_minimal" {
  description = "Minimal set of Private DNS Zones to link (used when private_dns_zones_to_link is empty and full linking is not desired)."
  type        = list(string)
  default = [
    "privatelink.blob.core.windows.net",
    "privatelink.file.core.windows.net",
    "privatelink.queue.core.windows.net",
    "privatelink.table.core.windows.net",
    "privatelink.vaultcore.azure.net",
    "privatelink.database.windows.net",
    "privatelink.azurecr.io",
    "privatelink.monitor.azure.com",
    "privatelink.oms.opinsights.azure.com",
    "privatelink.ods.opinsights.azure.com",
    "privatelink.agentsvc.azure-automation.net"
  ]
}

variable "link_all_private_dns_zones" {
  description = "If true, link all Private DNS Zones from connectivity. If false, use private_dns_zones_minimal."
  type        = bool
  default     = false
}
