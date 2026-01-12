# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Variables - F00 Terraform Backend                                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─────────────────────────────────────────────────────────────────────────────────
# REQUIRED
# ─────────────────────────────────────────────────────────────────────────────────

variable "management_subscription_id" {
  description = "Subscription ID of the Management subscription (Platform)."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.management_subscription_id))
    error_message = "Must be a valid GUID format."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group for terraform state storage."
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account (3-24 chars, lowercase alphanumeric only)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be 3-24 lowercase letters and numbers only."
  }
}

# ─────────────────────────────────────────────────────────────────────────────────
# OPTIONAL
# ─────────────────────────────────────────────────────────────────────────────────

variable "location" {
  description = "Azure region for resources."
  type        = string
  default     = "australiaeast"
}

variable "container_name" {
  description = "Name of the blob container for tfstate files."
  type        = string
  default     = "tfstate"
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
