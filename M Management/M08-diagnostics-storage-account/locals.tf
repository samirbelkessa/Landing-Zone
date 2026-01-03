################################################################################
# locals.tf - M08 Diagnostics Storage Account Module
# Local Variables and Computed Values
################################################################################

locals {
  #-----------------------------------------------------------------------------
  # Environment Mapping (aligns with F02/F03)
  #-----------------------------------------------------------------------------
  environment_map = {
    prod    = "prd"
    nonprod = "npd"
    dev     = "dev"
    test    = "tst"
    uat     = "uat"
    stg     = "stg"
    sandbox = "sbx"
  }
  env_short = lookup(local.environment_map, var.environment, "dev")

  # Environment for F03 (maps to standard names)
  f03_environment_map = {
    prod    = "Production"
    nonprod = "Non-Production"
    dev     = "Development"
    test    = "Test"
    uat     = "UAT"
    stg     = "Staging"
    sandbox = "Sandbox"
  }
  f03_environment = lookup(local.f03_environment_map, var.environment, "Development")

  # Determine if this is a production environment
  is_production = contains(["prod"], var.environment)

  #-----------------------------------------------------------------------------
  # Storage Account Naming
  # Storage account names: 3-24 chars, lowercase alphanumeric ONLY (no hyphens!)
  #-----------------------------------------------------------------------------
  # F02 would generate: st-<workload>-<env>-<region>-<instance>
  # But storage accounts cannot have hyphens, so we concatenate without them
  # Pattern: st<workload><env><region><instance>
  generated_name = lower(replace(
    "st${var.workload}${local.env_short}${var.region}${var.instance}",
    "-", ""
  ))

  # Use custom name if provided, otherwise use generated name
  # Ensure total length <= 24 characters
  storage_account_name = var.custom_name != null ? var.custom_name : (
    length(local.generated_name) > 24 ? substr(local.generated_name, 0, 24) : local.generated_name
  )

  #-----------------------------------------------------------------------------
  # Replication Type (Environment-based default)
  # Production: GRS (Geo-Redundant) for compliance
  # Non-Production: LRS (Locally Redundant) for cost optimization
  #-----------------------------------------------------------------------------
  replication_type = var.replication_type != null ? var.replication_type : (
    local.is_production ? "GRS" : "LRS"
  )

  # Combined SKU for account_replication_type
  account_replication_type = local.replication_type

  #-----------------------------------------------------------------------------
  # Default Containers for Diagnostics
  #-----------------------------------------------------------------------------
  default_containers = var.create_default_containers ? {
    "bootdiagnostics" = {
      container_access_type = var.default_container_access_type
      metadata = {
        purpose = "VM Boot Diagnostics"
      }
    }
    "insights-logs" = {
      container_access_type = var.default_container_access_type
      metadata = {
        purpose = "Azure Monitor Archived Logs"
      }
    }
    "insights-metrics" = {
      container_access_type = var.default_container_access_type
      metadata = {
        purpose = "Azure Monitor Archived Metrics"
      }
    }
  } : {}

  # Merge default and additional containers
  all_containers = merge(local.default_containers, var.additional_containers)

  #-----------------------------------------------------------------------------
  # Lifecycle Management Rules
  #-----------------------------------------------------------------------------
  # Default lifecycle rules for diagnostic data
  default_lifecycle_rules = var.enable_lifecycle_management ? {
    "default-diagnostics-lifecycle" = {
      enabled                            = true
      prefix_match                       = []  # Apply to all blobs
      blob_types                         = ["blockBlob"]
      tier_to_cool_after_days            = var.default_lifecycle_tier_to_cool_days
      tier_to_archive_after_days         = var.default_lifecycle_tier_to_archive_days
      delete_after_days                  = var.default_lifecycle_delete_days
      delete_snapshot_after_days         = 90
      tier_to_cold_after_days            = null
      auto_tier_to_hot_from_cool_enabled = false
    }
  } : {}

  # Use custom rules if provided, otherwise use defaults
  lifecycle_rules = length(var.lifecycle_rules) > 0 ? var.lifecycle_rules : local.default_lifecycle_rules

  #-----------------------------------------------------------------------------
  # Diagnostic Categories for Blob Service
  #-----------------------------------------------------------------------------
  blob_diagnostic_log_categories = [
    "StorageRead",
    "StorageWrite",
    "StorageDelete"
  ]

  blob_diagnostic_metric_categories = [
    "Transaction",
    "Capacity"
  ]
}
