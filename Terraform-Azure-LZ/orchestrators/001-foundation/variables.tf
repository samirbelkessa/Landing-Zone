# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Variables - Orchestrator Foundation                                           ║
# ║ These are passed to module F01 (Management Groups)                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════════════════════════════════════════════════════════════════════════════
# REQUIRED Variables
# ══════════════════════════════════════════════════════════════════════════════

variable "root_parent_id" {
  description = "The ID of the Tenant Root Group. Use your Azure AD Tenant ID."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.root_parent_id))
    error_message = "root_parent_id must be a valid GUID (tenant ID)."
  }
}

variable "root_name" {
  description = "Display name for the root management group (e.g., 'Intelly Group')."
  type        = string

  validation {
    condition     = length(var.root_name) >= 2 && length(var.root_name) <= 90
    error_message = "root_name must be between 2 and 90 characters."
  }
}

variable "root_id" {
  description = "ID/Name for the root management group. Used in resource naming (e.g., 'intelly')."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.root_id)) && length(var.root_id) >= 2 && length(var.root_id) <= 90
    error_message = "root_id must contain only alphanumeric characters, hyphens, and underscores."
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL Variables - Structure Configuration
# ══════════════════════════════════════════════════════════════════════════════

variable "deploy_platform_mg" {
  description = "Deploy the Platform management group and its children."
  type        = bool
  default     = true
}

variable "deploy_landing_zones_mg" {
  description = "Deploy the Landing Zones management group and its children."
  type        = bool
  default     = true
}

variable "deploy_decommissioned_mg" {
  description = "Deploy the Decommissioned management group."
  type        = bool
  default     = true
}

variable "deploy_sandbox_mg" {
  description = "Deploy the Sandbox management group under Landing Zones."
  type        = bool
  default     = true
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL Variables - Landing Zone Archetypes
# ══════════════════════════════════════════════════════════════════════════════

variable "deploy_corp_landing_zones" {
  description = "Deploy Corp landing zone archetypes."
  type        = bool
  default     = true
}

variable "deploy_online_landing_zones" {
  description = "Deploy Online landing zone archetypes."
  type        = bool
  default     = true
}

variable "deploy_prod_nonprod_separation" {
  description = "Create separate Prod and NonProd management groups for each archetype."
  type        = bool
  default     = true
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL Variables - Custom Management Groups
# ══════════════════════════════════════════════════════════════════════════════

variable "custom_landing_zone_children" {
  description = "Map of custom child management groups under Landing Zones."
  type = map(object({
    display_name = string
  }))
  default = {}
}

variable "custom_platform_children" {
  description = "Map of custom child management groups under Platform."
  type = map(object({
    display_name = string
  }))
  default = {}
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL Variables - Naming and Metadata
# ══════════════════════════════════════════════════════════════════════════════

variable "default_location" {
  description = "Default Azure region."
  type        = string
  default     = "australiaeast"
}

variable "secondary_location" {
  description = "Secondary Azure region for DR."
  type        = string
  default     = "australiasoutheast"
}

variable "allowed_regions" {
  description = "List of allowed Azure regions for policy enforcement."
  type        = list(string)
  default     = ["australiaeast", "australiasoutheast"]
}

variable "subscription_ids_by_mg" {
  description = "Map of management group names to subscription IDs for initial placement."
  type        = map(list(string))
  default     = {}
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL Variables - Timeouts
# ══════════════════════════════════════════════════════════════════════════════

variable "timeouts" {
  description = "Timeout configuration for management group operations."
  type = object({
    create = optional(string, "30m")
    read   = optional(string, "5m")
    update = optional(string, "30m")
    delete = optional(string, "30m")
  })
  default = {}
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL Variables - Tags
# ══════════════════════════════════════════════════════════════════════════════

variable "tags" {
  description = "Additional tags to apply to resources."
  type        = map(string)
  default     = {}
}
