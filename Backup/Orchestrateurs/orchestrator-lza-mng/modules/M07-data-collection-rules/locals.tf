################################################################################
# Local Variables - Tags and Computed Values
################################################################################

locals {
  # Default tags for all DCR resources
  default_tags = {
    ManagedBy = "Terraform"
    Module    = "M07-data-collection-rules"
  }
  
  # Merged tags (default + passed from orchestrator)
  common_tags = merge(local.default_tags, var.tags)
  
  # DCR-specific tags merged with common tags
  dcr_tags = {
    for dcr_key, dcr in var.data_collection_rules : dcr_key => merge(
      local.common_tags,
      try(dcr.tags, {})
    )
  }
  
  # Resolve DCR associations - map data_collection_rule_id (key) to actual DCR resource ID
  resolved_associations = {
    for assoc_key, assoc in var.data_collection_rule_associations : assoc_key => {
      target_resource_id      = assoc.target_resource_id
      data_collection_rule_id = try(
        azurerm_monitor_data_collection_rule.this[assoc.data_collection_rule_id].id,
        null
      )
      description = try(assoc.description, "Association managed by M07")
    }
  }
  
  # Filter out null associations (where DCR key doesn't exist)
  valid_associations = {
    for k, v in local.resolved_associations : k => v
    if v.data_collection_rule_id != null
  }
}