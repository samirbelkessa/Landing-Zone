# M07 - Data Collection Rules

## Description

Generic Terraform module for creating Azure Monitor Data Collection Rules (DCR) for Azure Monitor Agent (AMA). This module is a zero-hardcode wrapper around `azurerm_monitor_data_collection_rule` that supports all DCR features.

**Key Features:**
- ✅ Zero hardcoded configurations - all passed from orchestrator
- ✅ Supports all data source types (performance, events, syslog, IIS, custom logs)
- ✅ Multi-destination support (Log Analytics, Storage, Event Hub)
- ✅ KQL transformations for cost optimization
- ✅ Optional associations (recommended to use Azure Policy instead)
- ✅ Fully extensible - add new DCRs without modifying module

## Prerequisites

| Module | Required | Description |
|--------|----------|-------------|
| **M01** | ✅ Yes | Log Analytics Workspace (provides `workspace_resource_id`) |
| **M08** | 🟡 Optional | Diagnostics Storage (if using storage destination) |
| **I03** | 🟡 Optional | Managed Identity (for certain data sources) |
| F02 | ❌ No | Not used - descriptive names provided by orchestrator |
| F03 | ❌ No | Tags inherited from orchestrator |

## Dependencies

### From M01 (Log Analytics Workspace)
```hcl
module.m01_log_analytics[0].outputs_for_m07 = {
  workspace_id          = "/subscriptions/.../workspaces/law-xxx"
  workspace_resource_id = "12345678-1234-1234-1234-123456789012"  # GUID
  location              = "australiaeast"
}
```

### From M08 (Optional - Storage Destination)
```hcl
module.m08_diagnostics_storage[0].id = "/subscriptions/.../storageAccounts/stdiag"
```

## Usage

### Basic Example - Create DCRs Only (Recommended for New Landing Zones)
```hcl
module "m07_dcr" {
  source = "./modules/M07-data-collection-rules"
  
  data_collection_rules = {
    "dcr-windows-performance" = {
      location            = module.m01_log_analytics[0].outputs_for_m07.location
      resource_group_name = azurerm_resource_group.management.name
      description         = "Performance counters for all Windows VMs"
      kind                = "Windows"
      
      destinations = {
        log_analytics = {
          "central" = {
            workspace_resource_id = module.m01_log_analytics[0].outputs_for_m07.workspace_resource_id
          }
        }
      }
      
      data_flow = [{
        streams      = ["Microsoft-Perf"]
        destinations = ["central"]
      }]
      
      data_sources = {
        performance_counter = [{
          streams                       = ["Microsoft-Perf"]
          sampling_frequency_in_seconds = 60
          counter_specifiers = [
            "\\Processor(_Total)\\% Processor Time",
            "\\Memory\\Available MBytes"
          ]
          name = "perfCounters"
        }]
      }
    }
  }
  
  # Tags inherited from M01
  tags = module.m01_log_analytics[0].tags
  
  # No associations - use Azure Policy (G03) instead
  enable_associations = false
  
  depends_on = [module.m01_log_analytics]
}
```

### Advanced Example - With KQL Transformations
```hcl
data_collection_rules = {
  "dcr-windows-events-optimized" = {
    # ... destinations ...
    
    data_flow = [{
      streams      = ["Microsoft-WindowsEvent"]
      destinations = ["central"]
      
      # Filter BEFORE ingestion to reduce costs
      transform_kql = <<-KQL
        source
        | where EventLevelName in ("Critical", "Error", "Warning")
        | extend Environment = "Production"
      KQL
    }]
    
    # ... data_sources ...
  }
}
```

### Brownfield Example - With Manual Associations
```hcl
module "m07_dcr" {
  # ... DCR configurations ...
  
  # Enable manual associations
  enable_associations = true
  
  data_collection_rule_associations = {
    "vm-prod-01-perf" = {
      target_resource_id      = "/subscriptions/.../virtualMachines/vm-prod-01"
      data_collection_rule_id = "dcr-windows-performance"
      description             = "Performance monitoring for prod VM"
    }
  }
}
```

## Recommended DCR Configurations

See `orchestrator-lza-mng/dcr_configurations_examples.tf` for the 10 recommended DCR configurations for Azure CAF compliance.

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| `data_collection_rules` | Map of DCR configurations | `map(object)` | No | `{}` |
| `data_collection_rule_associations` | Optional DCR associations | `map(object)` | No | `{}` |
| `tags` | Tags to apply to all DCRs | `map(string)` | No | `{}` |
| `enable_associations` | Enable DCR associations | `bool` | No | `false` |

## Outputs

| Name | Description |
|------|-------------|
| `dcr_ids` | Map of DCR names to resource IDs |
| `dcr_immutable_ids` | Map of DCR names to immutable IDs |
| `association_ids` | Map of association names to IDs |
| `outputs_for_g03` | DCR IDs for VM Insights policies |
| `configuration` | Deployment summary |
| `ready` | Ready flag for dependent modules |

## Extending with New DCRs

To add a new DCR type, simply add it to `var.data_collection_rules` in the orchestrator:
```hcl
data_collection_rules = {
  # ... existing DCRs ...
  
  "dcr-sql-server-logs" = {
    location            = var.location
    resource_group_name = var.rg_name
    
    destinations = { ... }
    data_sources = { ... }
    data_flow    = [ ... ]
  }
}
```

No module modification required!

## Best Practices

1. **Use Azure Policy for Associations**: Don't use `data_collection_rule_associations`. Instead, configure Azure Policy (G03) to auto-associate DCRs to VMs.

2. **Create DCRs Before VMs**: Deploy M07 in week 1-2, deploy VMs in week 5+. Azure Policy will auto-configure monitoring.

3. **Use KQL Transformations**: Filter data BEFORE ingestion to reduce costs by 30-50%.

4. **Separate by Purpose**: Create dedicated DCRs for performance, security, and application logs.

5. **One DCR per OS Type**: Separate Windows and Linux DCRs (VM Insights requirement).

## Module Dependencies

### Consumed by
- **G03** (Policy Assignments): Uses `outputs_for_g03.vm_insights_*_dcr_id`

### Depends on
- **M01** (Log Analytics): Provides `workspace_resource_id`
- **M08** (Optional): Provides `storage_account_id`

## Compliance

This module supports Azure CAF compliance when configured with the 10 recommended DCRs:
- ✅ Monitoring Baseline (performance counters)
- ✅ Security Baseline (event logs, syslog)
- ✅ VM Insights (Azure Policy requirement)

## License

Proprietary - Internal use only