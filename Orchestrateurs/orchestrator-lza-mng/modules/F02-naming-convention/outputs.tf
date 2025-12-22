################################################################################
# outputs.tf - Module Outputs
# Module: naming-convention (F02)
################################################################################

#-------------------------------------------------------------------------------
# Primary Outputs
#-------------------------------------------------------------------------------

output "name" {
  description = "Generated resource name following Azure CAF conventions. This is the primary output to use for resource naming."
  value       = local.final_name
}

output "name_unique" {
  description = "Generated resource name with random suffix for global uniqueness. Same as 'name' if random_suffix_length > 0, otherwise includes a default 4-char suffix."
  value       = var.random_suffix_length > 0 ? local.final_name : "${local.generated_name}${substr(md5(local.generated_name), 0, 4)}"
}

#-------------------------------------------------------------------------------
# Name Components
#-------------------------------------------------------------------------------

output "slug" {
  description = "Resource type slug/prefix (e.g., 'rg', 'vnet', 'st')."
  value       = local.resource_def.slug
}

output "workload" {
  description = "Workload/application name component."
  value       = var.workload
}

output "environment" {
  description = "Full environment name."
  value       = var.environment
}

output "environment_abbreviation" {
  description = "Abbreviated environment name (e.g., 'prd', 'dev', 'sbx')."
  value       = local.env_abbrev
}

output "region" {
  description = "Region abbreviation used in the name."
  value       = var.region
}

output "instance" {
  description = "Instance number if provided."
  value       = local.instance_component
}

#-------------------------------------------------------------------------------
# Resource Constraints
#-------------------------------------------------------------------------------

output "max_length" {
  description = "Maximum allowed length for this resource type."
  value       = local.resource_def.max_length
}

output "actual_length" {
  description = "Actual length of the generated name."
  value       = length(local.final_name)
}

output "lowercase_required" {
  description = "Whether this resource type requires lowercase names."
  value       = local.resource_def.lowercase
}

output "alphanumeric_only" {
  description = "Whether this resource type only allows alphanumeric characters."
  value       = local.resource_def.alphanum_only
}

output "scope" {
  description = "Uniqueness scope for this resource type (e.g., 'global', 'resource_group', 'subscription')."
  value       = local.resource_def.scope
}

#-------------------------------------------------------------------------------
# Validation
#-------------------------------------------------------------------------------

output "is_valid" {
  description = "Whether the generated name meets all constraints for the resource type."
  value       = local.name_valid
}

output "validation_message" {
  description = "Validation result message."
  value       = local.validation_message
}

#-------------------------------------------------------------------------------
# Reference Data
#-------------------------------------------------------------------------------

output "resource_definitions" {
  description = "Map of all supported resource types and their naming constraints. Useful for documentation and validation."
  value       = local.resource_definitions
}

output "region_abbreviations" {
  description = "Map of Azure region names to their abbreviations."
  value       = local.region_abbreviations
}

output "environment_abbreviations" {
  description = "Map of environment names to their abbreviations."
  value       = local.environment_abbreviations
}

#-------------------------------------------------------------------------------
# Convenience Outputs
#-------------------------------------------------------------------------------

output "name_parts" {
  description = "List of name components before joining."
  value       = local.name_parts
}

output "separator" {
  description = "Separator character used between name components."
  value       = local.effective_separator
}

output "custom_name_used" {
  description = "Whether a custom name was provided (bypassing conventions)."
  value       = var.custom_name != null
}
