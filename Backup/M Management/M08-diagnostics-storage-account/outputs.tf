################################################################################
# outputs.tf - M08 Diagnostics Storage Account Module
# All useful outputs for downstream modules
################################################################################

#-------------------------------------------------------------------------------
# F02 Naming Outputs
#-------------------------------------------------------------------------------

output "generated_name" {
  description = "Generated Storage Account name from F02 pattern (or custom name if provided)."
  value       = local.storage_account_name
}

output "naming_details" {
  description = "Full naming details from F02 module."
  value = {
    resource_type    = "st"
    workload         = var.workload
    environment      = var.environment
    region           = var.region
    instance         = var.instance
    generated_name   = local.storage_account_name
    custom_name_used = var.custom_name != null
  }
}

#-------------------------------------------------------------------------------
# F03 Tags Outputs
#-------------------------------------------------------------------------------

output "tags" {
  description = "All tags applied to resources (F03 + additional)."
  value       = module.tags.all_tags
}

output "tags_details" {
  description = "Detailed tags information from F03 module."
  value = {
    environment         = module.tags.environment
    owner               = module.tags.owner
    cost_center         = module.tags.cost_center
    application         = module.tags.application
    criticality         = module.tags.criticality
    data_classification = module.tags.data_classification
    is_production       = module.tags.is_production
    is_critical         = module.tags.is_critical
  }
}

#-------------------------------------------------------------------------------
# Storage Account Core Outputs
#-------------------------------------------------------------------------------

output "id" {
  description = "The ID of the Storage Account."
  value       = azurerm_storage_account.this.id
}

output "name" {
  description = "The name of the Storage Account."
  value       = azurerm_storage_account.this.name
}

output "primary_location" {
  description = "The primary location of the Storage Account."
  value       = azurerm_storage_account.this.primary_location
}

output "secondary_location" {
  description = "The secondary location of the Storage Account (only if GRS/GZRS/RAGRS/RAGZRS)."
  value       = azurerm_storage_account.this.secondary_location
}

output "resource_group_name" {
  description = "The Resource Group name where the Storage Account is located."
  value       = azurerm_storage_account.this.resource_group_name
}

#-------------------------------------------------------------------------------
# Connection & Access Outputs
#-------------------------------------------------------------------------------

output "primary_access_key" {
  description = "The primary access key for the Storage Account."
  value       = azurerm_storage_account.this.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "The secondary access key for the Storage Account."
  value       = azurerm_storage_account.this.secondary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "The primary connection string for the Storage Account."
  value       = azurerm_storage_account.this.primary_connection_string
  sensitive   = true
}

output "secondary_connection_string" {
  description = "The secondary connection string for the Storage Account."
  value       = azurerm_storage_account.this.secondary_connection_string
  sensitive   = true
}

#-------------------------------------------------------------------------------
# Blob Endpoint Outputs
#-------------------------------------------------------------------------------

output "primary_blob_endpoint" {
  description = "The primary blob endpoint URL."
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "secondary_blob_endpoint" {
  description = "The secondary blob endpoint URL (only if GRS/GZRS/RAGRS/RAGZRS)."
  value       = azurerm_storage_account.this.secondary_blob_endpoint
}

output "primary_blob_host" {
  description = "The primary blob host name."
  value       = azurerm_storage_account.this.primary_blob_host
}

output "primary_blob_connection_string" {
  description = "The primary blob storage connection string."
  value       = azurerm_storage_account.this.primary_blob_connection_string
  sensitive   = true
}

#-------------------------------------------------------------------------------
# Other Endpoint Outputs
#-------------------------------------------------------------------------------

output "primary_queue_endpoint" {
  description = "The primary queue endpoint URL."
  value       = azurerm_storage_account.this.primary_queue_endpoint
}

output "primary_table_endpoint" {
  description = "The primary table endpoint URL."
  value       = azurerm_storage_account.this.primary_table_endpoint
}

output "primary_file_endpoint" {
  description = "The primary file endpoint URL."
  value       = azurerm_storage_account.this.primary_file_endpoint
}

output "primary_dfs_endpoint" {
  description = "The primary Data Lake Storage Gen2 endpoint URL."
  value       = azurerm_storage_account.this.primary_dfs_endpoint
}

output "primary_web_endpoint" {
  description = "The primary static website endpoint URL."
  value       = azurerm_storage_account.this.primary_web_endpoint
}

#-------------------------------------------------------------------------------
# Container Outputs
#-------------------------------------------------------------------------------

output "container_ids" {
  description = "Map of container names to their resource IDs."
  value = {
    for k, v in azurerm_storage_container.containers : k => v.id
  }
}

output "container_names" {
  description = "List of all container names created."
  value       = keys(azurerm_storage_container.containers)
}

output "bootdiagnostics_container_name" {
  description = "Name of the boot diagnostics container (if created)."
  value       = var.create_default_containers ? "bootdiagnostics" : null
}

output "insights_logs_container_name" {
  description = "Name of the insights-logs container (if created)."
  value       = var.create_default_containers ? "insights-logs" : null
}

output "insights_metrics_container_name" {
  description = "Name of the insights-metrics container (if created)."
  value       = var.create_default_containers ? "insights-metrics" : null
}

#-------------------------------------------------------------------------------
# Configuration Outputs
#-------------------------------------------------------------------------------

output "replication_type" {
  description = "The replication type used (LRS, GRS, etc.)."
  value       = local.account_replication_type
}

output "is_production" {
  description = "Whether this is a production environment."
  value       = local.is_production
}

output "is_geo_redundant" {
  description = "Whether the storage account uses geo-redundant replication."
  value       = contains(["GRS", "RAGRS", "GZRS", "RAGZRS"], local.account_replication_type)
}

output "lifecycle_management_enabled" {
  description = "Whether lifecycle management is enabled."
  value       = var.enable_lifecycle_management
}

output "lifecycle_policy_id" {
  description = "The ID of the lifecycle management policy (if enabled)."
  value       = var.enable_lifecycle_management && length(local.lifecycle_rules) > 0 ? azurerm_storage_management_policy.this[0].id : null
}

#-------------------------------------------------------------------------------
# Security Outputs
#-------------------------------------------------------------------------------

output "min_tls_version" {
  description = "The minimum TLS version configured."
  value       = azurerm_storage_account.this.min_tls_version
}

output "https_only" {
  description = "Whether HTTPS-only traffic is enforced."
  value       = azurerm_storage_account.this.https_traffic_only_enabled
}

output "public_access_enabled" {
  description = "Whether public network access is enabled."
  value       = azurerm_storage_account.this.public_network_access_enabled
}

output "blob_public_access_enabled" {
  description = "Whether public blob access is allowed."
  value       = azurerm_storage_account.this.allow_nested_items_to_be_public
}

#-------------------------------------------------------------------------------
# Integration Outputs for Other Modules
#-------------------------------------------------------------------------------

output "outputs_for_m05" {
  description = "Pre-formatted outputs for M05 diagnostic-settings module."
  value = {
    storage_account_id   = azurerm_storage_account.this.id
    storage_account_name = azurerm_storage_account.this.name
  }
}

output "outputs_for_m07" {
  description = "Pre-formatted outputs for M07 data-collection-rules module (storage destination)."
  value = {
    storage_account_id       = azurerm_storage_account.this.id
    container_resource_id    = var.create_default_containers ? azurerm_storage_container.containers["insights-logs"].id : null
    storage_blob_endpoint    = azurerm_storage_account.this.primary_blob_endpoint
  }
}

output "outputs_for_b01" {
  description = "Pre-formatted outputs for B01 recovery-services-vault module."
  value = {
    storage_account_id = azurerm_storage_account.this.id
  }
}

#-------------------------------------------------------------------------------
# Configuration Summary
#-------------------------------------------------------------------------------

output "configuration" {
  description = "Complete M08 configuration summary."
  value = {
    # Identity
    name                = azurerm_storage_account.this.name
    id                  = azurerm_storage_account.this.id
    resource_group_name = azurerm_storage_account.this.resource_group_name
    location            = azurerm_storage_account.this.location

    # Account settings
    account_tier      = azurerm_storage_account.this.account_tier
    account_kind      = azurerm_storage_account.this.account_kind
    replication_type  = local.account_replication_type
    access_tier       = azurerm_storage_account.this.access_tier

    # Security
    min_tls_version   = azurerm_storage_account.this.min_tls_version
    https_only        = azurerm_storage_account.this.https_traffic_only_enabled
    public_access     = azurerm_storage_account.this.public_network_access_enabled

    # Features
    is_production             = local.is_production
    is_geo_redundant          = contains(["GRS", "RAGRS", "GZRS", "RAGZRS"], local.account_replication_type)
    lifecycle_enabled         = var.enable_lifecycle_management
    diagnostic_settings       = var.enable_diagnostic_settings
    versioning_enabled        = var.enable_versioning
    soft_delete_enabled       = var.blob_soft_delete_retention_days > 0

    # Containers
    containers_created = keys(azurerm_storage_container.containers)
    default_containers = var.create_default_containers

    # Lifecycle settings
    tier_to_cool_days    = var.default_lifecycle_tier_to_cool_days
    tier_to_archive_days = var.default_lifecycle_tier_to_archive_days
    delete_after_days    = var.default_lifecycle_delete_days
  }
}

#-------------------------------------------------------------------------------
# Ready Flag for Dependencies
#-------------------------------------------------------------------------------

output "ready" {
  description = "Indicates M08 Storage Account is ready for use by dependent modules."
  value       = true

  depends_on = [
    azurerm_storage_account.this,
    azurerm_storage_container.containers,
    azurerm_storage_management_policy.this
  ]
}
