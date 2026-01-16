# S01 - Microsoft Defender for Cloud

## Overview

This module deploys and configures **Microsoft Defender for Cloud** across a subscription, enabling threat protection for various Azure resource types.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    MICROSOFT DEFENDER FOR CLOUD                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  DEFENDER PLANS                                                      │   │
│  │  ├── Servers (P2 with EDR/MDE integration)                          │   │
│  │  ├── Storage Accounts (DefenderForStorageV2)                        │   │
│  │  ├── SQL Servers                                                    │   │
│  │  ├── SQL on VMs                                                     │   │
│  │  ├── App Services                                                   │   │
│  │  ├── Key Vaults                                                     │   │
│  │  ├── ARM (Resource Manager)                                         │   │
│  │  ├── DNS                                                            │   │
│  │  ├── Containers                                                     │   │
│  │  └── Cloud Posture (CSPM)                                           │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  CONFIGURATION                                                       │   │
│  │  ├── Security Contact (email/phone)                                 │   │
│  │  ├── Auto-Provisioning (Log Analytics agent)                        │   │
│  │  └── Workspace Export (to Log Analytics)                            │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│                              │                                              │
│                              ▼                                              │
│                   ┌─────────────────────┐                                   │
│                   │  Log Analytics      │                                   │
│                   │  Workspace          │                                   │
│                   │  (from M01)         │                                   │
│                   └─────────────────────┘                                   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Features

- ✅ Enable/disable individual Defender plans
- ✅ Configure plan subplans (P1/P2 for Servers, etc.)
- ✅ Security contact configuration with email/phone
- ✅ Auto-provisioning of monitoring agents
- ✅ Export to Log Analytics Workspace
- ✅ Alert notifications configuration

## Prerequisites

### Dependencies

| Module | Output Used | Purpose |
|--------|-------------|---------|
| M01 | `log_analytics_workspace_id` | Defender data export |

### Permissions

The executing identity requires:
- **Security Admin** role on the subscription
- **Owner** or **Contributor** for pricing tier changes

## Usage

### Basic Example

```hcl
module "defender" {
  source = "../../modules/Security/S01-defender-for-cloud"

  security_contact_email     = "security@company.com"
  log_analytics_workspace_id = data.terraform_remote_state.management.outputs.log_analytics_workspace_id

  tags = {
    Environment = "Production"
    Owner       = "Security Team"
  }
}
```

### Advanced Example (Custom Plans)

```hcl
module "defender" {
  source = "../../modules/Security/S01-defender-for-cloud"

  security_contact_email = "security@company.com"
  security_contact_phone = "+61-2-1234-5678"
  
  log_analytics_workspace_id = data.terraform_remote_state.management.outputs.log_analytics_workspace_id

  # Custom plan configuration
  defender_plans = {
    VirtualMachines = {
      enabled = true
      subplan = "P2"  # P2 includes EDR (MDE)
    }
    StorageAccounts = {
      enabled = true
      subplan = "DefenderForStorageV2"
    }
    SqlServers = {
      enabled = true
      subplan = null
    }
    SqlServerVirtualMachines = {
      enabled = true
      subplan = null
    }
    AppServices = {
      enabled = true
      subplan = null
    }
    KeyVaults = {
      enabled = true
      subplan = null
    }
    Arm = {
      enabled = true
      subplan = "PerApiCall"
    }
    Dns = {
      enabled = false  # Disable DNS protection
      subplan = null
    }
    Containers = {
      enabled = true
      subplan = null
    }
    OpenSourceRelationalDatabases = {
      enabled = false
      subplan = null
    }
    CosmosDbs = {
      enabled = false
      subplan = null
    }
    CloudPosture = {
      enabled = true
      subplan = null
    }
  }

  # Auto-provisioning
  enable_auto_provisioning = true

  # Alert configuration
  alert_notifications_state        = "On"
  alert_notifications_min_severity = "Medium"
  alerts_to_admins_state           = "On"

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
| `security_contact_email` | Email for security alerts | `string` | Yes | - |
| `security_contact_phone` | Phone for security alerts | `string` | No | `null` |
| `log_analytics_workspace_id` | LAW resource ID for export | `string` | Yes | - |
| `defender_plans` | Map of Defender plans configuration | `map(object)` | No | See defaults |
| `enable_auto_provisioning` | Enable agent auto-provisioning | `bool` | No | `true` |
| `alert_notifications_state` | Enable email notifications | `string` | No | `"On"` |
| `alert_notifications_min_severity` | Minimum alert severity | `string` | No | `"Medium"` |
| `alerts_to_admins_state` | Send alerts to admins | `string` | No | `"On"` |
| `tags` | Resource tags | `map(string)` | No | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| `defender_plans_status` | Status of each Defender plan |
| `enabled_plans` | List of enabled plans |
| `disabled_plans` | List of disabled plans |
| `security_contact_id` | Security contact resource ID |
| `security_contact_email` | Configured email |
| `auto_provisioning_status` | Auto-provisioning status |
| `workspace_id` | Workspace configuration ID |
| `configuration_summary` | Complete configuration summary |
| `outputs_for_s02` | Outputs for Sentinel module |

## Cost Estimation

| Plan | Estimated Cost |
|------|----------------|
| Servers P2 | ~$15/VM/month |
| Storage | ~$0.02/10k transactions |
| SQL Servers | ~$15/server/month |
| App Services | ~$15/instance/month |
| Key Vaults | ~$0.02/10k operations |
| Containers | ~$7/vCore/month |
| Cloud Posture | Free tier available |

## Related Modules

- [M01 - Log Analytics Workspace](../../Management/M01-log-analytics-workspace/) - Required for data export
- [S02 - Microsoft Sentinel](../S02-sentinel/) - Uses Defender alerts

## License

This module is part of the Azure Landing Zone CAF project.
