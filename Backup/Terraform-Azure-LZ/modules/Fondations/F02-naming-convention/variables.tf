################################################################################
# variables.tf - Input Variables
# Module: naming-convention (F02)
################################################################################

#-------------------------------------------------------------------------------
# REQUIRED VARIABLES
#-------------------------------------------------------------------------------

variable "resource_type" {
  description = "Type of Azure resource to generate name for. Must be a valid resource type abbreviation (e.g., 'rg', 'vnet', 'st', 'kv', 'pip')."
  type        = string

  validation {
    condition     = contains(keys(local.resource_definitions), var.resource_type)
    error_message = "Invalid resource_type. Must be one of: ${join(", ", keys(local.resource_definitions))}"
  }
}

variable "workload" {
  description = "Workload or application name (e.g., 'hub', 'erp', 'web'). Used as the main identifier in the resource name."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.workload)) && length(var.workload) >= 2 && length(var.workload) <= 30
    error_message = "Workload must be 2-30 characters, lowercase alphanumeric with optional hyphens, no leading/trailing hyphens."
  }
}

variable "environment" {
  description = "Environment abbreviation. Valid values: 'prod', 'nonprod', 'dev', 'test', 'uat', 'stg', 'sandbox'."
  type        = string

  validation {
    condition     = contains(["prod", "nonprod", "dev", "test", "uat", "stg", "sandbox"], var.environment)
    error_message = "Environment must be one of: prod, nonprod, dev, test, uat, stg, sandbox."
  }
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES
#-------------------------------------------------------------------------------

variable "region" {
  description = "Azure region abbreviation. Defaults to 'aue' (Australia East). Common values: 'aue' (Australia East), 'aus' (Australia Southeast), 'weu' (West Europe)."
  type        = string
  default     = "aue"

  validation {
    condition     = can(regex("^[a-z]{2,6}$", var.region))
    error_message = "Region must be 2-6 lowercase letters."
  }
}

variable "instance" {
  description = "Instance number for multiple resources of the same type. Set to null or empty string to omit. Format: '001', '01', '1'."
  type        = string
  default     = null

  validation {
    condition     = var.instance == null || var.instance == "" || can(regex("^[0-9]+$", var.instance))
    error_message = "Instance must be null, empty, or numeric string (e.g., '001', '01', '1')."
  }
}

variable "suffix" {
  description = "Optional custom suffix to append to the resource name. Useful for unique identifiers or specific naming requirements."
  type        = string
  default     = null

  validation {
    condition     = var.suffix == null || can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.suffix))
    error_message = "Suffix must be lowercase alphanumeric with optional hyphens."
  }
}

variable "use_slug" {
  description = "Whether to include the resource type slug/prefix in the name. Set to false for resources that don't support prefixes."
  type        = bool
  default     = true
}

variable "separator" {
  description = "Character to use as separator between name components. Default is hyphen. Some resources (like Storage Accounts) require no separator."
  type        = string
  default     = "-"

  validation {
    condition     = contains(["-", "", "_"], var.separator)
    error_message = "Separator must be '-', '', or '_'."
  }
}

variable "random_suffix_length" {
  description = "Length of random suffix to add for uniqueness. Set to 0 to disable. Useful for globally unique names like Storage Accounts."
  type        = number
  default     = 0

  validation {
    condition     = var.random_suffix_length >= 0 && var.random_suffix_length <= 8
    error_message = "Random suffix length must be between 0 and 8."
  }
}

variable "custom_name" {
  description = "If provided, this name will be used as-is, bypassing all naming conventions. Use sparingly for legacy or special requirements."
  type        = string
  default     = null
}
