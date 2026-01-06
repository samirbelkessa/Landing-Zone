# =============================================================================
# Variables - Module tags (F03)
# =============================================================================

# -----------------------------------------------------------------------------
# REQUIRED VARIABLES
# -----------------------------------------------------------------------------

variable "environment" {
  description = "Environment name. Must be one of: Production, PreProduction, Development, Test, Sandbox, DR."
  type        = string

  validation {
    condition     = contains(["Production", "PreProduction", "Development", "Test", "Sandbox", "DR"], var.environment)
    error_message = "Environment must be one of: Production, PreProduction, Development, Test, Sandbox, DR."
  }
}

variable "owner" {
  description = "Email address of the resource owner (team or individual)."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.owner))
    error_message = "Owner must be a valid email address."
  }
}

variable "cost_center" {
  description = "Cost center code for billing and chargeback."
  type        = string

  validation {
    condition     = length(var.cost_center) >= 3 && length(var.cost_center) <= 20
    error_message = "Cost center must be between 3 and 20 characters."
  }
}

variable "application" {
  description = "Name of the application or workload."
  type        = string

  validation {
    condition     = length(var.application) >= 2 && length(var.application) <= 50
    error_message = "Application name must be between 2 and 50 characters."
  }
}

# -----------------------------------------------------------------------------
# OPTIONAL VARIABLES - WITH DEFAULTS
# -----------------------------------------------------------------------------

variable "criticality" {
  description = "Business criticality level. Determines SLA, backup policies, and DR requirements."
  type        = string
  default     = "Medium"

  validation {
    condition     = contains(["Critical", "High", "Medium", "Low"], var.criticality)
    error_message = "Criticality must be one of: Critical, High, Medium, Low."
  }
}

variable "data_classification" {
  description = "Data classification for security and compliance."
  type        = string
  default     = "Internal"

  validation {
    condition     = contains(["Public", "Internal", "Confidential", "Restricted"], var.data_classification)
    error_message = "Data classification must be one of: Public, Internal, Confidential, Restricted."
  }
}

variable "expiration_date" {
  description = "Expiration date for temporary resources (required for Sandbox). Format: YYYY-MM-DD."
  type        = string
  default     = null

  validation {
    condition     = var.expiration_date == null || can(regex("^\\d{4}-\\d{2}-\\d{2}$", var.expiration_date))
    error_message = "Expiration date must be in YYYY-MM-DD format."
  }
}

variable "project" {
  description = "Project name or code for grouping related resources."
  type        = string
  default     = null

  validation {
    condition     = var.project == null || (length(var.project) >= 2 && length(var.project) <= 50)
    error_message = "Project name must be between 2 and 50 characters."
  }
}

variable "department" {
  description = "Department or business unit name."
  type        = string
  default     = null

  validation {
    condition     = var.department == null || (length(var.department) >= 2 && length(var.department) <= 50)
    error_message = "Department name must be between 2 and 50 characters."
  }
}

variable "compliance" {
  description = "Compliance frameworks applicable to the resource (comma-separated)."
  type        = string
  default     = null

  validation {
    condition     = var.compliance == null || length(var.compliance) <= 100
    error_message = "Compliance string must not exceed 100 characters."
  }
}

variable "maintenance_window" {
  description = "Preferred maintenance window (e.g., 'Sun 02:00-06:00 AEST')."
  type        = string
  default     = null
}

variable "created_by" {
  description = "Identity or pipeline that created the resource."
  type        = string
  default     = null
}

variable "terraform_workspace" {
  description = "Terraform workspace name (auto-populated if using workspaces)."
  type        = string
  default     = null
}

variable "module_name" {
  description = "Name of the Terraform module creating this resource."
  type        = string
  default     = null
}

variable "additional_tags" {
  description = "Additional custom tags to merge with standard tags."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# ARCHETYPE-SPECIFIC VARIABLES
# -----------------------------------------------------------------------------

variable "archetype" {
  description = "Landing Zone archetype. Determines which policies and configurations apply."
  type        = string
  default     = null

  validation {
    condition     = var.archetype == null || contains(["Online-Prod", "Online-NonProd", "Corp-Prod", "Corp-NonProd", "Sandbox"], var.archetype)
    error_message = "Archetype must be one of: Online-Prod, Online-NonProd, Corp-Prod, Corp-NonProd, Sandbox."
  }
}

variable "enforce_sandbox_expiration" {
  description = "When true, enforce expiration_date requirement for Sandbox environment."
  type        = bool
  default     = true
}
