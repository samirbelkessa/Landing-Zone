# Module M01: Log Analytics Workspace

## Description

This module deploys a centralized Log Analytics workspace following Cloud Adoption Framework (CAF) best practices for Azure Landing Zones. It serves as the foundation for monitoring, security, and compliance across the entire Azure environment.

### Key Features

- **Centralized Logging**: Single pane of glass for all Azure resources
- **Archive Support**: Interactive + archive retention for compliance (90 days + archive = 1.1 years)
- **Table-Level Retention**: Granular control over retention per table type
- **Pre-configured Solutions**: SecurityInsights (Sentinel), VMInsights, Updates, etc.
- **Automation Integration**: Ready for linking with Automation Account (M02)
- **DR Support**: Optional secondary workspace in DR region
- **Saved Queries**: Common operational queries pre-deployed
- **Query Pack**: Reusable query collections for teams

## Architecture
```
┌─────────────────────────────────────────────────────────────────────┐
│                 Primary Region (Australia East)                      │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │           Log Analytics Workspace (Primary)                    │  │
│  │  ┌─────────────────────────────────────────────────────────┐  │  │
│  │  │ Interactive Retention: 90 days                           │  │  │
│  │  │ Archive Retention: 310 days (total: 400 / ~1.1 years)   │  │  │
│  │  └─────────────────────────────────────────────────────────┘  │  │
│  │  ┌─────────────────────────────────────────────────────────┐  │  │
│  │  │ Solutions: Sentinel, VMInsights, Updates, ChangeTracking│  │  │
│  │  └─────────────────────────────────────────────────────────┘  │  │
│  │  ┌─────────────────────────────────────────────────────────┐  │  │
│  │  │ Linked: Automation Account (M02)                         │  │  │
│  │  └─────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ Optional DR
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│               Secondary Region (Australia Southeast)                 │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │         Log Analytics Workspace (DR - Simplified)              │  │
│  │         Retention: 30 days (cost-optimized)                    │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

## Prerequisites

- **Terraform**: >= 1.5.0
- **Provider**: azurerm >= 3.80.0
- **Permissions**: Contributor on target Resource Group
- **Resource Group**: Must exist before deployment

## Dependencies

This module has **no upstream dependencies** and should be deployed first in the Management layer.

### Downstream Dependencies

| Module | Required Output |
|--------|-----------------|
| M02 - Automation Account | `outputs_for_m02` |
| M05 - Diagnostic Settings | `outputs_for_m05` |
| M07 - Data Collection Rules | `outputs_for_m07` |
| S01 - Defender for Cloud | `outputs_for_s01` |
| S02 - Sentinel | `outputs_for_s02` |

## Usage

### Basic Usage
```hcl
module "log_analytics" {
  source = "./modules/log-analytics-workspace"

  name                = "law-platform-aue-001"
  resource_group_name = "rg-management-aue-001"
  location            = "australiaeast"

  tags = {
    Environment = "Production"
    Owner       = "platform-team@company.com"
    CostCenter  = "IT-PLATFORM-001"
    Application = "Platform Management"
  }
}
```

### Australia Landing Zone Configuration (Full)
```hcl
module "log_analytics" {
  source = "./modules/log-analytics-workspace"

  # Required
  name                = "law-platform-aue-001"
  resource_group_name = "rg-management-aue-001"
  location            = "australiaeast"

  # Retention - 90 days interactive, 1.1 years total
  retention_in_days       = 90
  total_retention_in_days = 400

  # Archive configuration per table
  enable_table_level_archive = true
  archive_tables = {
    "SecurityEvent"    = 400  # 1.1 years for security
    "Syslog"           = 400
    "AzureActivity"    = 400
    "SigninLogs"       = 400
    "AuditLogs"        = 400
    "Perf"             = 180  # 6 months for performance
    "AzureMetrics"     = 180
  }

  # SKU - PerGB2018 for flexibility
  sku           = "PerGB2018"
  daily_quota_gb = -1  # No limit

  # Network - Allow public access (Private Endpoints configured separately)
  internet_ingestion_enabled = true
  internet_query_enabled     = true

  # Solutions
  deploy_solutions = true
  solutions = [
    { name = "SecurityInsights", publisher = "Microsoft" },
    { name = "AzureActivity", publisher = "Microsoft" },
    { name = "VMInsights", publisher = "Microsoft" },
    { name = "Updates", publisher = "Microsoft" },
    { name = "ChangeTracking", publisher = "Microsoft" },
    { name = "ServiceMap", publisher = "Microsoft" },
  ]

  # Diagnostic Settings
  enable_diagnostic_settings    = true
  diagnostic_storage_account_id = module.diagnostics_storage.id  # M08

  # DR Workspace (Optional)
  enable_cross_region_workspace = true
  secondary_location            = "australiasoutheast"
  secondary_retention_in_days   = 30  # Cost-optimized for DR

  tags = {
    Environment = "Production"
    Owner       = "platform-team@company.com"
    CostCenter  = "IT-PLATFORM-001"
    Application = "Platform Management"
    Criticality = "Critical"
  }
}

# Link Automation Account after M02 deployment
resource "azurerm_log_analytics_linked_service" "automation" {
  resource_group_name = "rg-management-aue-001"
  workspace_id        = module.log_analytics.id
  read_access_id      = module.automation_account.id

  depends_on = [module.automation_account]
}
```

### With Capacity Reservation (High Volume)
```hcl
module "log_analytics" {
  source = "./modules/log-analytics-workspace"

  name                = "law-platform-aue-001"
  resource_group_name = "rg-management-aue-001"
  location            = "australiaeast"

  # Capacity Reservation for predictable pricing
  sku                                = "CapacityReservation"
  reservation_capacity_in_gb_per_day = 200  # 200 GB/day commitment

  retention_in_days       = 90
  total_retention_in_days = 400

  tags = {
    Environment = "Production"
    Owner       = "platform-team@company.com"
    CostCenter  = "IT-PLATFORM-001"
    Application = "Platform Management"
  }
}
```

## Orchestrator Integration

For the Management layer orchestrator (M01-M08), use the dedicated outputs:
```hcl
# orchestrator/main.tf

module "m01_log_analytics" {
  source = "../modules/log-analytics-workspace"
  # ... configuration
}

module "m02_automation_account" {
  source = "../modules/automation-account"

  # Use dedicated output for M02
  log_analytics_workspace_id   = module.m01_log_analytics.outputs_for_m02.workspace_id
  log_analytics_workspace_name = module.m01_log_analytics.outputs_for_m02.workspace_name
  resource_group_name          = module.m01_log_analytics.outputs_for_m02.resource_group_name
  location                     = module.m01_log_analytics.outputs_for_m02.location

  depends_on = [module.m01_log_analytics]
}

module "m07_dcr" {
  source = "../modules/data-collection-rules"

  log_analytics_workspace_id = module.m01_log_analytics.outputs_for_m07.workspace_id
  location                   = module.m01_log_analytics.outputs_for_m07.location

  depends_on = [module.m01_log_analytics]
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| `name` | Workspace name (globally unique) | `string` | Yes | - |
| `resource_group_name` | Resource group name | `string` | Yes | - |
| `location` | Azure region | `string` | Yes | - |
| `retention_in_days` | Interactive retention (30-730) | `number` | No | `90` |
| `total_retention_in_days` | Total retention including archive | `number` | No | `400` |
| `enable_table_level_archive` | Enable per-table archive | `bool` | No | `true` |
| `archive_tables` | Tables with custom retention | `map(number)` | No | See variables.tf |
| `sku` | Workspace SKU | `string` | No | `"PerGB2018"` |
| `reservation_capacity_in_gb_per_day` | Capacity reservation GB/day | `number` | No | `null` |
| `daily_quota_gb` | Daily ingestion quota | `number` | No | `-1` |
| `internet_ingestion_enabled` | Allow public ingestion | `bool` | No | `true` |
| `internet_query_enabled` | Allow public queries | `bool` | No | `true` |
| `local_authentication_disabled` | Disable shared keys | `bool` | No | `false` |
| `deploy_solutions` | Deploy LA solutions | `bool` | No | `true` |
| `solutions` | Solutions to deploy | `list(object)` | No | See variables.tf |
| `link_automation_account` | Link Automation Account | `bool` | No | `false` |
| `automation_account_id` | Automation Account ID | `string` | No | `null` |
| `enable_diagnostic_settings` | Enable diagnostics | `bool` | No | `true` |
| `diagnostic_storage_account_id` | Storage for diagnostics | `string` | No | `null` |
| `enable_cross_region_workspace` | Enable DR workspace | `bool` | No | `false` |
| `secondary_location` | DR region | `string` | No | `"australiasoutheast"` |
| `secondary_retention_in_days` | DR retention | `number` | No | `30` |
| `tags` | Resource tags | `map(string)` | No | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| `id` | Workspace resource ID |
| `workspace_id` | Workspace ID (GUID) for agent config |
| `name` | Workspace name |
| `primary_shared_key` | Primary key (sensitive) |
| `secondary_shared_key` | Secondary key (sensitive) |
| `retention_in_days` | Interactive retention |
| `total_retention_in_days` | Total retention |
| `archive_retention_in_days` | Archive period |
| `solutions` | Deployed solutions map |
| `sentinel_solution_id` | Sentinel solution ID |
| `archive_tables` | Archive-configured tables |
| `secondary_workspace_id` | DR workspace ID |
| `dr_enabled` | DR status |
| `configuration` | Full config summary |
| `ready` | Dependency signal |
| `outputs_for_m02` | M02 Automation inputs |
| `outputs_for_m05` | M05 Diagnostics inputs |
| `outputs_for_m07` | M07 DCR inputs |
| `outputs_for_s01` | S01 Defender inputs |
| `outputs_for_s02` | S02 Sentinel inputs |

## Table Archive Configuration

The module supports granular retention per table type:

| Table | Default Retention | Use Case |
|-------|-------------------|----------|
| SecurityEvent | 400 days | Security investigations |
| SigninLogs | 400 days | Identity compliance |
| AuditLogs | 400 days | Audit compliance |
| AzureActivity | 400 days | Change tracking |
| Syslog | 400 days | Linux system logs |
| Perf | 180 days | Performance trending |
| AzureMetrics | 180 days | Metrics analysis |

## Best Practices

1. **Use PerGB2018 SKU** unless you have predictable high volume (>100GB/day)
2. **Configure table-level archive** for compliance-sensitive data
3. **Enable diagnostic settings** to capture workspace audit logs
4. **Consider DR workspace** for business-critical environments
5. **Link Automation Account** early for Update Management

## Troubleshooting

### Archive Tables Not Created
Tables are created automatically when data is ingested. Pre-configuring retention on non-existent tables is safe.

### Solution Deployment Fails
Some solutions require additional permissions. Ensure the deploying identity has Contributor on the resource group.

### Query Performance Slow
Archived data requires restore before querying. Use interactive retention for frequently accessed data.

## License

Proprietary - Internal use only