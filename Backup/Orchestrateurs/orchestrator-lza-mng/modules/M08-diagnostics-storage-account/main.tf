################################################################################
# main.tf - M08 Diagnostics Storage Account Module
# Azure Storage Account with F02 Naming and F03 Tags
################################################################################

#-------------------------------------------------------------------------------
# F02 - Naming Convention Module
#-------------------------------------------------------------------------------

module "naming" {
  source = "../F02-naming-convention"

  resource_type = "st"
  workload      = var.workload
  environment   = var.environment
  region        = var.region
  instance      = var.instance
}

#-------------------------------------------------------------------------------
# F03 - Tags Module
#-------------------------------------------------------------------------------

module "tags" {
  source = "../F03-tags"

  environment         = local.f03_environment
  owner               = var.owner
  cost_center         = var.cost_center
  application         = var.application
  criticality         = var.criticality
  data_classification = var.data_classification
  project             = var.project
  department          = var.department
  module_name         = "M08-diagnostics-storage-account"
  additional_tags     = var.additional_tags
}

#-------------------------------------------------------------------------------
# Storage Account
#-------------------------------------------------------------------------------

resource "azurerm_storage_account" "this" {
  name                = local.storage_account_name
  resource_group_name = var.resource_group_name
  location            = var.location

  #-----------------------------------------------------------------------------
  # Account Configuration
  #-----------------------------------------------------------------------------
  account_tier             = var.account_tier
  account_kind             = var.account_kind
  account_replication_type = local.account_replication_type
  access_tier              = var.access_tier

  #-----------------------------------------------------------------------------
  # Security Configuration
  #-----------------------------------------------------------------------------
  min_tls_version                 = var.min_tls_version
  https_traffic_only_enabled      = var.https_traffic_only_enabled
  allow_nested_items_to_be_public = var.allow_nested_items_to_be_public
  public_network_access_enabled   = var.public_network_access_enabled
  shared_access_key_enabled       = var.shared_access_key_enabled
  default_to_oauth_authentication = var.default_to_oauth_authentication

  # Infrastructure double encryption (optional)
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled

#-----------------------------------------------------------------------------
  # Blob Properties
  #-----------------------------------------------------------------------------
  blob_properties {
    # Soft delete for blobs
    delete_retention_policy {
      days = var.blob_soft_delete_retention_days > 0 ? var.blob_soft_delete_retention_days : null
    }

    # Soft delete for containers
    container_delete_retention_policy {
      days = var.container_soft_delete_retention_days > 0 ? var.container_soft_delete_retention_days : null
    }

    # Versioning
    versioning_enabled = var.enable_versioning

    # Change feed - attributs directs (pas de bloc dynamic)
    change_feed_enabled           = var.enable_change_feed
    change_feed_retention_in_days = var.enable_change_feed ? var.change_feed_retention_in_days : null
  }

  #-----------------------------------------------------------------------------
  # Network Rules (Optional)
  #-----------------------------------------------------------------------------
  dynamic "network_rules" {
    for_each = var.network_rules != null ? [var.network_rules] : []
    content {
      default_action             = network_rules.value.default_action
      bypass                     = network_rules.value.bypass
      ip_rules                   = network_rules.value.ip_rules
      virtual_network_subnet_ids = network_rules.value.virtual_network_subnet_ids
    }
  }

  #-----------------------------------------------------------------------------
  # Tags from F03
  #-----------------------------------------------------------------------------
  tags = module.tags.all_tags

  #-----------------------------------------------------------------------------
  # Lifecycle
  #-----------------------------------------------------------------------------
  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
    prevent_destroy = false
  }
}

#-------------------------------------------------------------------------------
# Storage Containers
#-------------------------------------------------------------------------------

resource "azurerm_storage_container" "containers" {
  for_each = local.all_containers

  name                  = each.key
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = each.value.container_access_type
  metadata              = each.value.metadata

  depends_on = [azurerm_storage_account.this]
}

#-------------------------------------------------------------------------------
# Lifecycle Management Policy
#-------------------------------------------------------------------------------

resource "azurerm_storage_management_policy" "this" {
  count = var.enable_lifecycle_management && length(local.lifecycle_rules) > 0 ? 1 : 0

  storage_account_id = azurerm_storage_account.this.id

  dynamic "rule" {
    for_each = local.lifecycle_rules
    content {
      name    = rule.key
      enabled = rule.value.enabled

      filters {
        prefix_match = length(rule.value.prefix_match) > 0 ? rule.value.prefix_match : null
        blob_types   = rule.value.blob_types
      }

      actions {
        # Base blob actions
        base_blob {
          # Tier to Cool
          tier_to_cool_after_days_since_modification_greater_than = rule.value.tier_to_cool_after_days

          # Tier to Cold (optional, for Cold tier storage)
          tier_to_cold_after_days_since_modification_greater_than = rule.value.tier_to_cold_after_days

          # Tier to Archive
          tier_to_archive_after_days_since_modification_greater_than = rule.value.tier_to_archive_after_days

          # Delete
          delete_after_days_since_modification_greater_than = rule.value.delete_after_days

          # Auto-tier from Cool to Hot based on access
          auto_tier_to_hot_from_cool_enabled = rule.value.auto_tier_to_hot_from_cool_enabled
        }

        # Snapshot actions
        snapshot {
          delete_after_days_since_creation_greater_than = rule.value.delete_snapshot_after_days
        }

        # Version actions (if versioning enabled)
        dynamic "version" {
          for_each = var.enable_versioning ? [1] : []
          content {
            delete_after_days_since_creation = rule.value.delete_after_days
          }
        }
      }
    }
  }

  depends_on = [azurerm_storage_account.this]
}

#-------------------------------------------------------------------------------
# Diagnostic Settings for Storage Account (Self-diagnostics)
# Sends Storage Account logs to Log Analytics (M01)
#-------------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "storage_account" {
  count = var.enable_diagnostic_settings && var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "diag-${local.storage_account_name}"
  target_resource_id         = azurerm_storage_account.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Metrics
  dynamic "metric" {
    for_each = var.diagnostic_metric_categories
    content {
      category = metric.value
      enabled  = true
    }
  }

  depends_on = [azurerm_storage_account.this]
}

#-------------------------------------------------------------------------------
# Diagnostic Settings for Blob Service
#-------------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "blob_service" {
  count = var.enable_diagnostic_settings && var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "diag-${local.storage_account_name}-blob"
  target_resource_id         = "${azurerm_storage_account.this.id}/blobServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Logs
  dynamic "enabled_log" {
    for_each = local.blob_diagnostic_log_categories
    content {
      category = enabled_log.value
    }
  }

  # Metrics
  dynamic "metric" {
    for_each = local.blob_diagnostic_metric_categories
    content {
      category = metric.value
      enabled  = true
    }
  }

  depends_on = [azurerm_storage_account.this]
}
