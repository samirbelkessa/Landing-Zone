# =============================================================================
# Main - Module tags (F03)
# =============================================================================
# This module is a utility module that doesn't create any Azure resources.
# It standardizes tag generation for use by other modules.
#
# Usage:
#   module "tags" {
#     source      = "../tags"
#     environment = "Production"
#     owner       = "team@company.com"
#     cost_center = "IT-12345"
#     application = "MyApp"
#   }
#
#   resource "azurerm_resource_group" "example" {
#     name     = "rg-example"
#     location = "australiaeast"
#     tags     = module.tags.all_tags
#   }
# =============================================================================

# -----------------------------------------------------------------------------
# Sandbox Expiration Validation
# -----------------------------------------------------------------------------
# This resource will fail if Sandbox environment is used without an expiration date
# when enforce_sandbox_expiration is enabled.

resource "terraform_data" "sandbox_expiration_check" {
  count = local.sandbox_expiration_error ? 1 : 0

  lifecycle {
    precondition {
      condition     = !local.sandbox_expiration_error
      error_message = "Sandbox environment requires an expiration_date. Set expiration_date or disable enforce_sandbox_expiration."
    }
  }
}

# -----------------------------------------------------------------------------
# Tag Validation - Ensure no empty values in mandatory tags
# -----------------------------------------------------------------------------
resource "terraform_data" "tag_validation" {
  lifecycle {
    precondition {
      condition     = length(var.owner) > 0
      error_message = "Owner tag cannot be empty."
    }

    precondition {
      condition     = length(var.cost_center) > 0
      error_message = "CostCenter tag cannot be empty."
    }

    precondition {
      condition     = length(var.application) > 0
      error_message = "Application tag cannot be empty."
    }
  }
}
