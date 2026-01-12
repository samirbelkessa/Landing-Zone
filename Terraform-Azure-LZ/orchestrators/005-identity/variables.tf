# =============================================================================
# VARIABLES.TF - Input Variables
# =============================================================================
# Orchestrator: 05-identity
# Purpose: Define all input variables for Identity deployment
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
  description = "Subscription ID where the Terraform state Storage Account is located."
  type        = string
}

variable "identity_subscription_id" {
  description = "Subscription ID for the Identity subscription."
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
# REQUIRED - COMMON
# =============================================================================

variable "location" {
  description = "Azure region for Identity resources."
  type        = string
  default     = "australiaeast"
}

variable "environment" {
  description = "Environment name (e.g., prod, nonprod)."
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name for naming convention."
  type        = string
  default     = "identity"
}

# =============================================================================
# REQUIRED - TAGS (F03)
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
  default     = "Platform Identity"
}

variable "tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}

# =============================================================================
# MODULE FLAGS
# =============================================================================

variable "deploy_role_assignments" {
  description = "Deploy role assignments."
  type        = bool
  default     = true
}

variable "deploy_managed_identities" {
  description = "Deploy managed identities."
  type        = bool
  default     = false
}

# =============================================================================
# ROLE ASSIGNMENTS
# =============================================================================

variable "role_assignments" {
  description = <<-EOT
    Map of role assignments to create.
    
    Supported scope_type values:
    - "management_group" : Use scope_name to reference MG (e.g., "intelly", "intelly-platform")
    - "subscription"     : Use scope_id for subscription GUID
    
    Example:
    ```hcl
    role_assignments = {
      platform-admins-root = {
        group_display_name = "intelly-platform-admins"
        scope_type         = "management_group"
        scope_name         = "intelly"
        role_name          = "Owner"
      }
    }
    ```
  EOT
  type = map(object({
    group_display_name = string
    scope_type         = string # "management_group" or "subscription"
    scope_name         = optional(string, null)
    scope_id           = optional(string, null)
    role_name          = string
    description        = optional(string, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.role_assignments : contains(["management_group", "subscription"], v.scope_type)
    ])
    error_message = "scope_type must be 'management_group' or 'subscription'."
  }
}

# =============================================================================
# MANAGED IDENTITIES (Optional - for future use)
# =============================================================================

variable "managed_identities" {
  description = <<-EOT
    Map of User Assigned Managed Identities to create.
    
    Example:
    ```hcl
    managed_identities = {
      terraform-platform = {
        name        = "uami-terraform-platform"
        description = "CI/CD Terraform for Landing Zone deployment"
        role_assignments = {
          owner-root = {
            scope_type = "management_group"
            scope_name = "intelly"
            role_name  = "Owner"
          }
        }
      }
    }
    ```
  EOT
  type = map(object({
    name        = optional(string, null) # If null, will be generated by F02
    description = optional(string, "Managed Identity")
    role_assignments = optional(map(object({
      scope_type = string
      scope_name = optional(string, null)
      scope_id   = optional(string, null)
      role_name  = string
    })), {})
  }))
  default = {}
}
