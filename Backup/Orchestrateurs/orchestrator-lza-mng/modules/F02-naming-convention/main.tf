################################################################################
# main.tf - Main Module Logic
# Module: naming-convention (F02)
################################################################################

# This module is a pure Terraform module that generates resource names
# following Azure CAF naming conventions. It uses only local values and
# does not create any Azure resources.

# The main logic is implemented in locals.tf where:
# 1. Resource definitions are maintained (slugs, max lengths, constraints)
# 2. Name components are assembled based on input variables
# 3. Transformations are applied (lowercase, alphanumeric-only)
# 4. Validation is performed against resource constraints

# Random string for globally unique names (Storage Accounts, Key Vaults, etc.)
resource "random_string" "suffix" {
  count = var.random_suffix_length > 0 ? 1 : 0

  length  = var.random_suffix_length
  special = false
  upper   = !local.resource_def.lowercase
  lower   = true
  numeric = true
}

# Construct final name with optional random suffix
locals {
  # Final name with random suffix if enabled
  final_name = var.random_suffix_length > 0 ? (
    "${local.generated_name}${random_string.suffix[0].result}"
  ) : local.generated_name

  # Also provide name without random suffix for reference
  name_without_suffix = local.generated_name
}
