################################################################################
# M07 - Data Collection Rules - Outputs
################################################################################

#-------------------------------------------------------------------------------
# DCR Resource IDs
#-------------------------------------------------------------------------------

output "dcr_ids" {
  description = "Map of DCR names to Azure resource IDs."
  value = {
    for k, v in azurerm_monitor_data_collection_rule.this : k => v.id
  }
}

output "dcr_immutable_ids" {
  description = "Map of DCR names to immutable IDs (used by Azure Monitor Agent)."
  value = {
    for k, v in azurerm_monitor_data_collection_rule.this : k => v.immutable_id
  }
}

output "dcr_names" {
  description = "Map of DCR keys to Azure resource names."
  value = {
    for k, v in azurerm_monitor_data_collection_rule.this : k => v.name
  }
}

#-------------------------------------------------------------------------------
# DCR Association IDs
#-------------------------------------------------------------------------------

output "association_ids" {
  description = "Map of DCR association names to resource IDs."
  value = {
    for k, v in azurerm_monitor_data_collection_rule_association.this : k => v.id
  }
}

#-------------------------------------------------------------------------------
# Outputs for G03 (Policy Assignments)
#-------------------------------------------------------------------------------

output "outputs_for_g03" {
  description = <<-EOT
    Outputs specifically needed by G03 (Policy Assignments).
    Provides DCR IDs for VM Insights policy assignments.
  EOT
  
  value = {
    vm_insights_windows_dcr_id = try(
      azurerm_monitor_data_collection_rule.this["dcr-vm-insights-windows"].id,
      null
    )
    vm_insights_linux_dcr_id = try(
      azurerm_monitor_data_collection_rule.this["dcr-vm-insights-linux"].id,
      null
    )
    
    # All DCR IDs for flexible policy assignment
    all_dcr_ids = {
      for k, v in azurerm_monitor_data_collection_rule.this : k => v.id
    }
  }
}

#-------------------------------------------------------------------------------
# Configuration Summary
#-------------------------------------------------------------------------------

output "configuration" {
  description = "Summary of DCR deployment for orchestrator."
  value = {
    dcr_count         = length(azurerm_monitor_data_collection_rule.this)
    association_count = length(azurerm_monitor_data_collection_rule_association.this)
    
    dcrs_by_kind = {
      for kind in distinct([for dcr in azurerm_monitor_data_collection_rule.this : try(dcr.kind, "unspecified")]) :
      kind => [
        for k, v in azurerm_monitor_data_collection_rule.this : k
        if try(v.kind, "unspecified") == kind
      ]
    }
    
    associations_enabled = var.enable_associations
  }
}

#-------------------------------------------------------------------------------
# Tags
#-------------------------------------------------------------------------------

output "tags" {
  description = "Common tags applied to all DCR resources."
  value       = local.common_tags
}

#-------------------------------------------------------------------------------
# Ready Flag
#-------------------------------------------------------------------------------

output "ready" {
  description = "Indicates DCRs are ready for policy assignments and VM associations."
  value       = true
  
  depends_on = [
    azurerm_monitor_data_collection_rule.this
  ]
}