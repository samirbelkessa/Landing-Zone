# S02 - Microsoft Sentinel

## Overview

This module deploys and configures **Microsoft Sentinel**, Azure's cloud-native SIEM (Security Information and Event Management) and SOAR (Security Orchestration, Automation, and Response) solution.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         MICROSOFT SENTINEL                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  LOG ANALYTICS WORKSPACE (from M01)                                  │   │
│  │  └── Sentinel Onboarding                                            │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              │                                              │
│                              ▼                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  DATA CONNECTORS                                                     │   │
│  │  ├── Azure Active Directory (requires license)                      │   │
│  │  ├── Azure Activity Logs                                            │   │
│  │  ├── Microsoft Defender for Cloud                                   │   │
│  │  ├── Threat Intelligence                                            │   │
│  │  ├── Microsoft Cloud App Security (requires license)                │   │
│  │  ├── Office 365 (requires license)                                  │   │
│  │  └── Microsoft 365 Defender (requires M365 E5)                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              │                                              │
│                              ▼                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  ANALYTICS & RESPONSE                                                │   │
│  │  ├── Alert Rules (from templates)                                   │   │
│  │  ├── Watchlists                                                     │   │
│  │  └── UEBA (User & Entity Behavior Analytics)                        │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Features

- ✅ Sentinel onboarding to Log Analytics Workspace
- ✅ Multiple data connectors (license-aware configuration)
- ✅ Watchlist creation
- ✅ UEBA configuration (optional)
- ✅ Customer-managed key support

## Prerequisites

### Dependencies

| Module | Output Used | Purpose |
|--------|-------------|---------|
| M01 | `log_analytics_workspace_id` | Sentinel onboarding |
| M01 | `log_analytics_workspace_name` | Resource reference |
| S01 | (optional) | Defender connector |

### Licensing Requirements

⚠️ **Important**: Some data connectors require specific licenses:

| Connector | License Required |
|-----------|------------------|
| Azure Active Directory | Azure AD Premium P1/P2 or M365 E5 |
| Office 365 | Office 365 E3/E5 |
| Microsoft 365 Defender | Microsoft 365 E5 Security |
| Microsoft Cloud App Security | Microsoft Defender for Cloud Apps |
| Azure ATP | Microsoft Defender for Identity |

### Permissions

The executing identity requires:
- **Microsoft Sentinel Contributor** role on the workspace
- **Log Analytics Contributor** role on the workspace

## Usage

### Basic Example

```hcl
module "sentinel" {
  source = "../../modules/Security/S02-sentinel"

  log_analytics_workspace_id   = data.terraform_remote_state.management.outputs.log_analytics_workspace_id
  log_analytics_workspace_name = data.terraform_remote_state.management.outputs.log_analytics_workspace_name
  resource_group_name          = data.terraform_remote_state.management.outputs.resource_group_name

  # Default connectors (no license required)
  data_connectors = {
    azure_active_directory       = false  # Requires license
    azure_activity               = true
    defender_for_cloud           = true
    threat_intelligence          = true
    microsoft_cloud_app_security = false  # Requires license
    office_365                   = false  # Requires license
    microsoft_365_defender       = false  # Requires license
    azure_advanced_threat_protection = false  # Requires license
  }

  tags = {
    Environment = "Production"
    Owner       = "Security Team"
  }
}
```

### Advanced Example (With Watchlists and UEBA)

```hcl
module "sentinel" {
  source = "../../modules/Security/S02-sentinel"

  log_analytics_workspace_id   = data.terraform_remote_state.management.outputs.log_analytics_workspace_id
  log_analytics_workspace_name = data.terraform_remote_state.management.outputs.log_analytics_workspace_name
  resource_group_name          = data.terraform_remote_state.management.outputs.resource_group_name

  # Enable connectors (ensure you have appropriate licenses)
  data_connectors = {
    azure_active_directory       = true   # Requires Azure AD P1/P2
    azure_activity               = true
    defender_for_cloud           = true
    threat_intelligence          = true
    microsoft_cloud_app_security = true   # Requires MCAS license
    office_365                   = true   # Requires O365 license
    microsoft_365_defender       = false
    azure_advanced_threat_protection = false
  }

  # Create watchlists
  watchlists = {
    high_value_assets = {
      display_name    = "High Value Assets"
      description     = "Critical business assets for enhanced monitoring"
      item_search_key = "AssetName"
      labels          = ["Critical", "Monitored"]
    }
    vip_users = {
      display_name    = "VIP Users"
      description     = "Executive and privileged users"
      item_search_key = "UserPrincipalName"
      labels          = ["VIP", "Executive"]
    }
    allowed_ips = {
      display_name    = "Allowed IP Addresses"
      description     = "Known good IP addresses"
      item_search_key = "IPAddress"
      labels          = ["Whitelist"]
    }
  }

  # Enable UEBA
  enable_ueba = true
  ueba_data_sources = ["AuditLogs", "AzureActivity", "SigninLogs"]

  tags = {
    Environment = "Production"
    Owner       = "Security Team"
    CostCenter  = "IT-Security"
  }
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| `log_analytics_workspace_id` | LAW resource ID | `string` | Yes | - |
| `log_analytics_workspace_name` | LAW name | `string` | Yes | - |
| `resource_group_name` | Resource group name | `string` | Yes | - |
| `data_connectors` | Data connectors configuration | `object` | No | See defaults |
| `enable_default_alert_rules` | Enable default alert rules | `bool` | No | `false` |
| `alert_rule_templates` | Alert rule template GUIDs | `list(string)` | No | `[]` |
| `watchlists` | Watchlists to create | `map(object)` | No | `{}` |
| `enable_ueba` | Enable UEBA | `bool` | No | `false` |
| `ueba_data_sources` | UEBA data sources | `list(string)` | No | See defaults |
| `customer_managed_key_enabled` | Enable CMK | `bool` | No | `false` |
| `tags` | Resource tags | `map(string)` | No | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| `sentinel_onboarding_id` | Sentinel onboarding resource ID |
| `workspace_id` | Log Analytics Workspace ID |
| `workspace_name` | Log Analytics Workspace name |
| `data_connectors_status` | Status of each connector |
| `enabled_connectors` | List of enabled connectors |
| `connector_ids` | Resource IDs of connectors |
| `watchlist_ids` | Map of watchlist IDs |
| `configuration_summary` | Complete configuration summary |
| `outputs_for_l03` | Outputs for Landing Zone module |

## Cost Estimation

| Component | Estimated Cost |
|-----------|----------------|
| Sentinel ingestion | ~$2.76/GB (first 5GB/day free) |
| Sentinel retention | ~$0.12/GB/month (beyond 90 days) |
| Basic logs | ~$0.50/GB |
| Archive | ~$0.02/GB/month |

## Troubleshooting

### Error: InvalidLicense for Azure AD connector

```
Error: The data connector 'AzureActiveDirectory' requires Azure AD Premium license
```

**Solution:** Ensure Azure AD Premium P1/P2 or Microsoft 365 E5 license is active, or disable the connector.

### Error: Insufficient permissions

```
Error: The client does not have authorization to perform action
```

**Solution:** Ensure the executing identity has **Microsoft Sentinel Contributor** role.

## Related Modules

- [M01 - Log Analytics Workspace](../../Management/M01-log-analytics-workspace/) - Required dependency
- [S01 - Defender for Cloud](../S01-defender-for-cloud/) - Defender connector source

## License

This module is part of the Azure Landing Zone CAF project.
