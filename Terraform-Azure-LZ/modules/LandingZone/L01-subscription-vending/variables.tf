# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Variables - L01 Subscription Vending                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════════════════════════════════════════════════════════════════════════════
# REQUIRED Variables
# ══════════════════════════════════════════════════════════════════════════════

variable "subscriptions" {
  description = <<-EOT
    Map of subscriptions to create. Each subscription requires:
    - display_name: The display name of the subscription
    - archetype: The landing zone archetype (determines MG placement)
    - workload_type: Production or DevTest (affects pricing)
    - owner_object_id: Azure AD Object ID of the initial owner
    
    Optional:
    - tags: Additional tags for the subscription
    - budget: Budget configuration
  EOT
  type = map(object({
    display_name    = string
    archetype       = string # corp_prod, corp_nonprod, online_prod, online_nonprod, sandbox, management, connectivity, identity
    workload_type   = optional(string, "Production") # Production or DevTest
    owner_object_id = optional(string, null)
    
    tags = optional(map(string), {})
    
    budget = optional(object({
      amount     = number
      time_grain = optional(string, "Monthly")
      start_date = optional(string, null)
      end_date   = optional(string, null)
      notifications = optional(map(object({
        enabled        = optional(bool, true)
        threshold      = number
        operator       = optional(string, "GreaterThan")
        contact_emails = optional(list(string), [])
        contact_roles  = optional(list(string), ["Owner"])
      })), {})
    }), null)
  }))

  validation {
    condition = alltrue([
      for k, v in var.subscriptions : contains([
        "corp_prod", "corp_nonprod", "online_prod", "online_nonprod",
        "sandbox", "management", "connectivity", "identity",
        "landing_zones", "platform", "decommissioned", "root"
      ], v.archetype)
    ])
    error_message = "archetype must be one of: corp_prod, corp_nonprod, online_prod, online_nonprod, sandbox, management, connectivity, identity, landing_zones, platform, decommissioned, root."
  }

  validation {
    condition = alltrue([
      for k, v in var.subscriptions : contains(["Production", "DevTest"], v.workload_type)
    ])
    error_message = "workload_type must be either 'Production' or 'DevTest'."
  }
}

variable "billing_account_name" {
  description = "The name of the billing account. For EA: enrollment account name. For MCA: billing account ID."
  type        = string
}

variable "billing_scope" {
  description = <<-EOT
    The billing scope for subscription creation. Format depends on agreement type:
    - EA: /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/enrollmentAccounts/{enrollmentAccountName}
    - MCA: /providers/Microsoft.Billing/billingAccounts/{billingAccountId}/billingProfiles/{billingProfileId}/invoiceSections/{invoiceSectionId}
  EOT
  type        = string
}

# ══════════════════════════════════════════════════════════════════════════════
# Management Group IDs - From F01 Foundation
# ══════════════════════════════════════════════════════════════════════════════

variable "management_group_ids" {
  description = <<-EOT
    Map of management group IDs from F01 module outputs. Expected keys:
    - root, platform, management, connectivity, identity
    - landing_zones, corp_prod, corp_nonprod, online_prod, online_nonprod
    - sandbox, decommissioned
    
    Pass module.management_groups.all_mg_ids or data.terraform_remote_state.foundation.outputs.all_mg_ids
  EOT
  type        = map(string)

  validation {
    condition     = contains(keys(var.management_group_ids), "root")
    error_message = "management_group_ids must contain at least the 'root' key."
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL Variables - Configuration
# ══════════════════════════════════════════════════════════════════════════════

variable "subscription_alias_prefix" {
  description = "Prefix for subscription alias names."
  type        = string
  default     = "sub"
}

variable "default_tags" {
  description = "Default tags to apply to all subscriptions."
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Module    = "L01-subscription-vending"
  }
}

variable "enable_subscription_placement" {
  description = "Enable automatic placement of subscriptions into management groups."
  type        = bool
  default     = true
}

variable "wait_for_subscription_creation" {
  description = "Time to wait after subscription creation before placement (handles Azure propagation delays)."
  type        = string
  default     = "60s"
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL Variables - RBAC
# ══════════════════════════════════════════════════════════════════════════════

variable "default_role_assignments" {
  description = "Default role assignments to apply to all subscriptions."
  type = map(object({
    role_definition_name = string
    principal_id         = string
    principal_type       = optional(string, "Group") # User, Group, ServicePrincipal
  }))
  default = {}
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL Variables - Existing Subscriptions
# ══════════════════════════════════════════════════════════════════════════════

variable "existing_subscriptions" {
  description = <<-EOT
    Map of existing subscriptions to place into management groups (brownfield scenario).
    Use this to move existing subscriptions without creating new ones.
  EOT
  type = map(object({
    subscription_id = string
    archetype       = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.existing_subscriptions : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", v.subscription_id))
    ])
    error_message = "All subscription_id values must be valid GUIDs."
  }
}
