# ==============================================================================
# M06 - Update Management (Azure Update Manager) - Variables
# ==============================================================================

#-------------------------------------------------------------------------------
# REQUIRED VARIABLES - F02 Naming Convention Inputs
#-------------------------------------------------------------------------------

variable "workload" {
  description = "Workload name for F02 naming convention (e.g., 'platform', 'app')."
  type        = string

  validation {
    condition     = length(var.workload) >= 2 && length(var.workload) <= 10
    error_message = "Workload must be between 2 and 10 characters."
  }
}

variable "environment" {
  description = "Environment for F02 naming convention (e.g., 'prod', 'dev', 'test')."
  type        = string

  validation {
    condition     = contains(["prod", "dev", "test", "uat", "staging", "qa"], var.environment)
    error_message = "Environment must be one of: prod, dev, test, uat, staging, qa."
  }
}

variable "region" {
  description = "Azure region abbreviation for F02 naming (e.g., 'aue' for Australia East)."
  type        = string
  default     = "aue"

  validation {
    condition     = length(var.region) >= 2 && length(var.region) <= 4
    error_message = "Region abbreviation must be between 2 and 4 characters."
  }
}

variable "instance" {
  description = "Instance number for F02 naming convention (e.g., '001', '002')."
  type        = string
  default     = "001"

  validation {
    condition     = can(regex("^[0-9]{3}$", var.instance))
    error_message = "Instance must be a 3-digit number (e.g., '001')."
  }
}

#-------------------------------------------------------------------------------
# REQUIRED VARIABLES - Resource Placement
#-------------------------------------------------------------------------------

variable "resource_group_name" {
  description = "Name of the resource group for Maintenance Configurations."
  type        = string
}

variable "location" {
  description = "Azure region for Maintenance Configurations."
  type        = string
}

#-------------------------------------------------------------------------------
# REQUIRED VARIABLES - F03 Tagging Inputs
#-------------------------------------------------------------------------------

variable "owner" {
  description = "Owner email for F03 tags (required)."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.owner))
    error_message = "Owner must be a valid email address."
  }
}

variable "cost_center" {
  description = "Cost center code for F03 tags (required)."
  type        = string

  validation {
    condition     = length(var.cost_center) >= 3 && length(var.cost_center) <= 20
    error_message = "Cost center must be between 3 and 20 characters."
  }
}

variable "application" {
  description = "Application name for F03 tags."
  type        = string
  default     = "Platform Update Management"
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - F03 Tagging Inputs
#-------------------------------------------------------------------------------

variable "criticality" {
  description = "Business criticality for F03 tags: Critical, High, Medium, Low."
  type        = string
  default     = "High"

  validation {
    condition     = contains(["Critical", "High", "Medium", "Low"], var.criticality)
    error_message = "Criticality must be one of: Critical, High, Medium, Low."
  }
}

variable "data_classification" {
  description = "Data classification for F03 tags: Public, Internal, Confidential, Restricted."
  type        = string
  default     = "Internal"

  validation {
    condition     = contains(["Public", "Internal", "Confidential", "Restricted"], var.data_classification)
    error_message = "Data classification must be one of: Public, Internal, Confidential, Restricted."
  }
}

variable "project" {
  description = "Project name for F03 tags."
  type        = string
  default     = null
}

variable "department" {
  description = "Department for F03 tags."
  type        = string
  default     = null
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Custom Naming (Bypasses F02)
#-------------------------------------------------------------------------------

variable "custom_name_prefix" {
  description = "Custom prefix for Maintenance Configuration names. If provided, bypasses F02 naming convention. Example: 'mc-custom' will create 'mc-custom-windows-weekly'."
  type        = string
  default     = null
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Maintenance Configurations
#-------------------------------------------------------------------------------

variable "maintenance_configurations" {
  description = <<-EOT
    Map of custom Maintenance Configurations for Azure Update Manager.
    Each configuration defines a patching schedule and settings.
    Configuration names will be prefixed with F02 naming (or custom_name_prefix if provided).
  EOT
  type = map(object({
    description = optional(string)
    scope       = optional(string, "InGuestPatch")
    visibility  = optional(string, "Custom")

    window = object({
      start_date_time      = string
      duration             = string
      time_zone            = string
      recur_every          = string
      expiration_date_time = optional(string)
    })

    install_patches = optional(object({
      reboot = optional(string, "IfRequired")

      linux = optional(object({
        classifications_to_include    = optional(list(string), ["Critical", "Security"])
        package_names_mask_to_exclude = optional(list(string), [])
        package_names_mask_to_include = optional(list(string), [])
      }))

      windows = optional(object({
        classifications_to_include = optional(list(string), ["Critical", "Security"])
        kb_numbers_to_exclude       = optional(list(string), [])
        kb_numbers_to_include       = optional(list(string), [])
      }))
    }))

    in_guest_user_patch_mode = optional(string, "User")
  }))
  default = {}
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - VM Assignments
#-------------------------------------------------------------------------------

variable "vm_assignments" {
  description = <<-EOT
    Map of static VM assignments to Maintenance Configurations.
    Each assignment links specific VM IDs to a maintenance configuration.
    Use the configuration KEY (not the full name generated by F02).
  EOT
  type = map(object({
    maintenance_configuration_key = string
    virtual_machine_ids           = list(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.vm_assignments :
      length(v.virtual_machine_ids) > 0
    ])
    error_message = "Each VM assignment must specify at least one virtual_machine_id."
  }
}

variable "dynamic_scope_assignments" {
  description = <<-EOT
    Map of dynamic scope assignments (filter-based) to Maintenance Configurations.
    VMs matching the filter criteria will be automatically assigned.
    Use the configuration KEY (not the full name generated by F02).
  EOT
  type = map(object({
    maintenance_configuration_key = string
    filter = object({
      resource_types  = optional(list(string), ["Microsoft.Compute/virtualMachines", "Microsoft.HybridCompute/machines"])
      resource_groups = optional(list(string))
      locations       = optional(list(string))
      os_types        = optional(list(string))
      tag_filter = optional(object({
        tag_operator = optional(string, "Any")
        tags = list(object({
          tag    = string
          values = list(string)
        }))
      }))
    })
  }))
  default = {}
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Default Configurations
#-------------------------------------------------------------------------------

variable "create_default_windows_config" {
  description = "Create a default Windows Maintenance Configuration (Critical+Security, weekly Sunday 2AM)."
  type        = bool
  default     = false
}

variable "create_default_linux_config" {
  description = "Create a default Linux Maintenance Configuration (Critical+Security, weekly Sunday 3AM)."
  type        = bool
  default     = false
}

variable "default_timezone" {
  description = "Default timezone for maintenance windows."
  type        = string
  default     = "UTC"

  validation {
    condition     = length(var.default_timezone) > 0
    error_message = "Timezone cannot be empty."
  }
}

variable "default_target_locations" {
  description = "Default Azure regions to target for updates (used in default configurations)."
  type        = list(string)
  default     = []
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Module Integration
#-------------------------------------------------------------------------------

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace from M01 module (optional, for future integration)."
  type        = string
  default     = null
}

variable "action_group_ids" {
  description = "Map of action group IDs from M03 module for alerting integration (optional)."
  type        = map(string)
  default     = {}
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Additional Tags
#-------------------------------------------------------------------------------

variable "additional_tags" {
  description = "Additional tags to merge with F03 tags. Use this to add custom tags specific to Update Management."
  type        = map(string)
  default     = {}
}
