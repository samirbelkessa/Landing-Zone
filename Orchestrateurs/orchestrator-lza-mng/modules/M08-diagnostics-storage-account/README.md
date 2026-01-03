# M08 - Diagnostics Storage Account Module

## Overview

This Terraform module deploys a secure Azure Storage Account dedicated to storing diagnostic data, boot diagnostics, and archived logs/metrics. It integrates with F02 (Naming Convention) and F03 (Tagging) modules to ensure consistent naming and tagging across all resources.

## 🎯 Key Features

- ✅ **Secure by Default**: TLS 1.2 minimum, HTTPS only, public blob access disabled
- ✅ **Environment-Aware Replication**: GRS for production, LRS for non-production (cost optimization)
- ✅ **Lifecycle Management**: Automatic tiering (Hot → Cool → Archive) with configurable retention
- ✅ **Pre-configured Containers**: Boot diagnostics, insights-logs, insights-metrics
- ✅ **M01 Integration**: Self-diagnostics sent to Log Analytics Workspace
- ✅ **F02/F03 Integration**: Consistent naming and tagging strategy
- ✅ **Zero Hardcoding**: All values configurable via variables

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    M08 - Diagnostics Storage Account                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐     │
│  │ bootdiagnostics  │   │   insights-logs   │   │ insights-metrics │     │
│  │    Container     │   │     Container     │   │    Container     │     │
│  │                  │   │                   │   │                  │     │
│  │   VM Boot Diag   │   │  Archived Logs    │   │ Archived Metrics │     │
│  └──────────────────┘   └──────────────────┘   └──────────────────┘     │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │                    Lifecycle Management                         │     │
│  │   Hot (0-30 days) → Cool (30-90 days) → Archive (90-400 days) │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │ Security: TLS 1.2 | HTTPS Only | No Public Blob | Entra ID Auth │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │ Replication: GRS (Production) | LRS (Non-Production)            │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└────────────────────────┬────────────────────────────────────────────────┘
                         │
                         │ Diagnostic Settings
                         ▼
              ┌─────────────────────────┐
              │   M01 - Log Analytics   │
              │       Workspace         │
              └─────────────────────────┘
```

## Prerequisites

### Required Modules

| Module | Required | Description |
|--------|----------|-------------|
| **F02** | ✅ Yes | Naming Convention (`../F02-naming-convention`) |
| **F03** | ✅ Yes | Tags (`../F03-tags`) |
| **M01** | 🟡 Optional | Log Analytics Workspace (for self-diagnostics) |

### Required Permissions

The Terraform service principal needs:
- `Storage Account Contributor` on the resource group
- `Monitoring Contributor` if enabling diagnostic settings

### Terraform Version

- **Terraform**: >= 1.5.0
- **Provider**: azurerm >= 4.57.0

## Usage

### Basic Example - Production Environment

```hcl
module "m08_diagnostics_storage" {
  source = "./modules/M08-diagnostics-storage-account"

  # F02 Naming inputs
  workload    = "diag"
  environment = "prod"
  region      = "aue"
  instance    = "001"

  # Resource placement
  resource_group_name = "rg-management-prd-aue-001"
  location            = "australiaeast"

  # F03 Tagging inputs
  owner       = "platform-team@company.com.au"
  cost_center = "IT-PLATFORM-001"
  application = "Platform Diagnostics"
  criticality = "High"
  project     = "Azure-Landing-Zone"

  # Will auto-select GRS replication for production
  # Will create default containers: bootdiagnostics, insights-logs, insights-metrics
  # Will enable lifecycle management with default tiering
}
```

### Advanced Example - Non-Production with Custom Lifecycle

```hcl
module "m08_diagnostics_storage" {
  source = "./modules/M08-diagnostics-storage-account"

  # F02 Naming inputs
  workload    = "diag"
  environment = "dev"
  region      = "aue"
  instance    = "001"

  # Resource placement
  resource_group_name = "rg-management-dev-aue-001"
  location            = "australiaeast"

  # F03 Tagging inputs
  owner       = "dev-team@company.com.au"
  cost_center = "IT-DEV-001"
  application = "Platform Diagnostics"
  criticality = "Low"

  # Override replication (default for dev would be LRS)
  # replication_type = "LRS"  # Already default for non-prod

  # Custom lifecycle rules
  lifecycle_rules = {
    "aggressive-cleanup" = {
      enabled                    = true
      prefix_match               = []
      blob_types                 = ["blockBlob"]
      tier_to_cool_after_days    = 7
      tier_to_archive_after_days = 30
      delete_after_days          = 90
      delete_snapshot_after_days = 30
    }
  }

  # Additional containers
  additional_containers = {
    "custom-logs" = {
      container_access_type = "private"
      metadata = {
        purpose = "Application Logs"
      }
    }
  }
}
```

### Example with M01 Integration (Self-Diagnostics)

```hcl
module "m08_diagnostics_storage" {
  source = "./modules/M08-diagnostics-storage-account"

  # F02 Naming inputs
  workload    = "diag"
  environment = "prod"
  region      = "aue"
  instance    = "001"

  # Resource placement
  resource_group_name = "rg-management-prd-aue-001"
  location            = "australiaeast"

  # F03 Tagging inputs
  owner       = "platform-team@company.com.au"
  cost_center = "IT-PLATFORM-001"
  application = "Platform Diagnostics"

  # Enable self-diagnostics to Log Analytics
  enable_diagnostic_settings = true
  log_analytics_workspace_id = module.m01_log_analytics.id

  # Custom retention settings
  default_lifecycle_tier_to_cool_days    = 30
  default_lifecycle_tier_to_archive_days = 90
  default_lifecycle_delete_days          = 400  # ~1.1 years per client requirements
}
```

### Example with Network Restrictions

```hcl
module "m08_diagnostics_storage" {
  source = "./modules/M08-diagnostics-storage-account"

  # ... F02/F03 inputs ...

  # Network restrictions
  network_rules = {
    default_action             = "Deny"
    bypass                     = ["AzureServices", "Logging", "Metrics"]
    ip_rules                   = ["203.0.113.0/24"]
    virtual_network_subnet_ids = [module.hub_vnet.shared_services_subnet_id]
  }

  # Disable public access (use Private Endpoints)
  public_network_access_enabled = false
}
```

## Inputs

### Required Variables - F02 Naming

| Name | Description | Type | Example |
|------|-------------|------|---------|
| `workload` | Workload name (2-15 chars, lowercase) | `string` | `"diag"` |
| `environment` | Environment code | `string` | `"prod"` |

### Required Variables - F03 Tags

| Name | Description | Type | Example |
|------|-------------|------|---------|
| `owner` | Owner email | `string` | `"team@company.com"` |
| `cost_center` | Cost center code | `string` | `"IT-001"` |
| `application` | Application name | `string` | `"Platform Diagnostics"` |

### Required Variables - Resource Placement

| Name | Description | Type |
|------|-------------|------|
| `resource_group_name` | Resource group name | `string` |
| `location` | Azure region | `string` |

### Optional Variables - Naming

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `region` | Region abbreviation | `string` | `"aue"` |
| `instance` | Instance number | `string` | `"001"` |
| `custom_name` | Custom storage account name | `string` | `null` |

### Optional Variables - Storage Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `account_tier` | Storage tier | `string` | `"Standard"` |
| `account_kind` | Storage kind | `string` | `"StorageV2"` |
| `access_tier` | Default blob access tier | `string` | `"Hot"` |
| `replication_type` | Replication type (auto if null) | `string` | `null` |

### Optional Variables - Security

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `min_tls_version` | Minimum TLS version | `string` | `"TLS1_2"` |
| `https_traffic_only_enabled` | Force HTTPS | `bool` | `true` |
| `allow_nested_items_to_be_public` | Allow public blob access | `bool` | `false` |
| `public_network_access_enabled` | Allow public network access | `bool` | `true` |
| `shared_access_key_enabled` | Allow key-based access | `bool` | `true` |

### Optional Variables - Lifecycle Management

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `enable_lifecycle_management` | Enable lifecycle policies | `bool` | `true` |
| `default_lifecycle_tier_to_cool_days` | Days before Hot→Cool | `number` | `30` |
| `default_lifecycle_tier_to_archive_days` | Days before Cool→Archive | `number` | `90` |
| `default_lifecycle_delete_days` | Days before deletion | `number` | `400` |

### Optional Variables - Containers

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `create_default_containers` | Create bootdiagnostics, insights-logs, insights-metrics | `bool` | `true` |
| `additional_containers` | Map of additional containers | `map(object)` | `{}` |

### Optional Variables - Diagnostics

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `enable_diagnostic_settings` | Enable self-diagnostics | `bool` | `false` |
| `log_analytics_workspace_id` | Log Analytics Workspace ID | `string` | `null` |

## Outputs

### Core Outputs

| Name | Description |
|------|-------------|
| `id` | Storage Account resource ID |
| `name` | Storage Account name |
| `primary_blob_endpoint` | Primary blob endpoint URL |
| `primary_access_key` | Primary access key (sensitive) |
| `primary_connection_string` | Primary connection string (sensitive) |

### Container Outputs

| Name | Description |
|------|-------------|
| `container_ids` | Map of container names to IDs |
| `container_names` | List of all container names |
| `bootdiagnostics_container_name` | Boot diagnostics container name |
| `insights_logs_container_name` | Logs container name |
| `insights_metrics_container_name` | Metrics container name |

### Integration Outputs

| Name | Description |
|------|-------------|
| `outputs_for_m05` | Pre-formatted outputs for M05 diagnostic-settings |
| `outputs_for_m07` | Pre-formatted outputs for M07 data-collection-rules |
| `outputs_for_b01` | Pre-formatted outputs for B01 recovery-services-vault |
| `configuration` | Complete configuration summary |
| `ready` | Ready flag for dependency management |

## Environment-Based Defaults

| Setting | Production | Non-Production |
|---------|------------|----------------|
| Replication Type | GRS (Geo-Redundant) | LRS (Locally Redundant) |
| Soft Delete | 7 days | 7 days |
| Lifecycle Delete | 400 days (~1.1 years) | 400 days |

## Lifecycle Management Timeline

```
Day 0          Day 30         Day 90         Day 400
  │              │              │               │
  ▼              ▼              ▼               ▼
┌────┐        ┌────┐        ┌───────┐       ┌──────┐
│ Hot│───────▶│Cool│───────▶│Archive│──────▶│Delete│
└────┘        └────┘        └───────┘       └──────┘
  │              │              │               │
  │  Active      │  Infrequent  │  Compliance   │  Cleanup
  │  Access      │  Access      │  Archive      │
```

## Security Best Practices

This module implements the following security measures:

1. **TLS 1.2 Minimum**: All connections require TLS 1.2 or higher
2. **HTTPS Only**: HTTP traffic is rejected
3. **No Public Blob Access**: Blobs cannot be accessed anonymously
4. **Entra ID Authentication**: Default authentication method in Azure Portal
5. **Soft Delete**: Protection against accidental deletion
6. **Network Rules**: Optional IP and VNet restrictions

## Module Dependencies

### Consumed by

- **M01** (Log Analytics): Uses storage account for archive destination
- **M02** (Automation Account): Boot diagnostics storage
- **M05** (Diagnostic Settings): Archive destination for resource diagnostics
- **M07** (Data Collection Rules): Storage destination for DCR data
- **B01** (Recovery Services Vault): Backup storage

### Depends on

- **F02** (Naming Convention): Resource naming
- **F03** (Tags): Resource tagging
- **M01** (Optional): Log Analytics for self-diagnostics

## Troubleshooting

### Storage Account Name Too Long

**Issue**: Generated name exceeds 24 characters

**Solution**: The module automatically truncates names to 24 characters. Use `custom_name` for specific naming requirements.

### Network Access Denied

**Issue**: Cannot access storage account after enabling network rules

**Solution**: Ensure `bypass` includes `["AzureServices", "Logging", "Metrics"]` for Azure Monitor integration.

### Lifecycle Rules Not Applying

**Issue**: Blobs not being tiered or deleted

**Solution**: 
- Lifecycle rules apply to blobs created AFTER the rule was created
- Rules run once per day, not immediately
- Check that blob last modified date meets the criteria

## Compliance

This module supports Azure CAF compliance:
- ✅ Secure defaults (TLS 1.2, HTTPS only)
- ✅ Geo-redundancy for production
- ✅ Configurable retention (default 1.1 years)
- ✅ Audit trail via diagnostic settings
- ✅ Consistent tagging

## License

Proprietary - Internal use only
