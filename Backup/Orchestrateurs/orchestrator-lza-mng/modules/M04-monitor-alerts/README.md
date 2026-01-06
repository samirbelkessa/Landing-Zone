# M04 - Monitor Alerts Module

## Description

This module deploys Azure Monitor alerts for platform-level monitoring in an Azure Landing Zone. It creates default alerts for Service Health, Resource Health, and Activity Log events, while supporting custom metric and log-based alerts.

The module integrates with:
- **F02 (naming-convention)**: Consistent naming across all alerts
- **F03 (tags)**: Standardized tagging for governance
- **M01 (log-analytics-workspace)**: Log query alerts integration
- **M03 (monitor-action-groups)**: Automatic severity-to-action-group mapping

## Features

- **Default Platform Alerts**:
  - Service Health alerts (incidents, maintenance, security advisories)
  - Resource Health alerts (degraded, unavailable resources)
  - Activity Log Administrative alerts (delete operations on critical resources)
  - Activity Log Security alerts (policy violations, security changes)

- **Custom Alerts Support**:
  - Activity Log alerts with flexible criteria
  - Metric alerts with static and dynamic thresholds
  - Log Analytics query alerts (Scheduled Query Rules v2)

- **Automatic Action Group Mapping**:
  - Severity-based routing to appropriate action groups
  - Configurable mapping overrides

## Prerequisites

| Module | Required | Description |
|--------|----------|-------------|
| F02 | No | Naming convention (pattern replicated in module) |
| F03 | No | Tags standard (pattern replicated in module) |
| M01 | Optional | Log Analytics workspace for log query alerts |
| M03 | Yes | Action groups for alert notifications |

## Usage

### Important: No Hardcoding

This module is designed to receive all resource IDs dynamically from other module outputs or variables. **Never hardcode subscription IDs, resource IDs, or scopes.**

```hcl
# ❌ WRONG - Hardcoded values
subscription_ids = ["00000000-0000-0000-0000-000000000000"]
action_group_ids = {
  critical = "/subscriptions/.../actionGroups/ag-critical"
}

# ✅ CORRECT - Dynamic values from modules/variables
subscription_ids = [var.management_subscription_id, var.connectivity_subscription_id]
action_group_ids = module.action_groups.outputs_for_m04.action_group_ids
```

### Basic Usage (Default Alerts Only)

```hcl
module "monitor_alerts" {
  source = "../M04-monitor-alerts"

  # F02 Naming inputs
  workload    = "platform"
  environment = "prod"
  region      = "aue"
  instance    = "001"

  # F03 Tags inputs
  owner       = "platform-team@company.com"
  cost_center = "IT-001"
  application = "Azure Landing Zone"

  # Azure resources - from Terraform resources
  resource_group_name = azurerm_resource_group.management.name

  # M03 Action Groups - from module output
  action_group_ids = module.action_groups.outputs_for_m04.action_group_ids

  # Scopes - from variables (not hardcoded)
  subscription_ids = [var.management_subscription_id]
}
```

### Advanced Usage (With Custom Alerts)

```hcl
module "monitor_alerts" {
  source = "../M04-monitor-alerts"

  # F02 Naming inputs
  workload    = "platform"
  environment = "prod"
  region      = "aue"
  instance    = "001"

  # F03 Tags inputs
  owner              = "platform-team@company.com"
  cost_center        = "IT-001"
  application        = "Azure Landing Zone"
  criticality        = "Critical"
  data_classification = "Internal"
  project            = "Landing Zone Deployment"
  department         = "Cloud Platform"

  # Azure resources - from module outputs
  resource_group_name        = azurerm_resource_group.management.name
  log_analytics_workspace_id = module.log_analytics.id

  # M03 Action Groups - from module output
  action_group_ids = module.action_groups.outputs_for_m04.action_group_ids

  # Scopes - subscription IDs from variables
  subscription_ids = [
    var.management_subscription_id,
    var.connectivity_subscription_id,
    var.identity_subscription_id
  ]

  # Custom Service Health configuration
  service_health_alert_config = {
    enabled     = true
    event_types = ["Incident", "Maintenance", "Security"]
    regions     = ["Australia East", "Australia Southeast", "Global"]
    severity    = "critical"
  }

  # Custom Resource Health configuration
  resource_health_alert_config = {
    enabled        = true
    current_states = ["Degraded", "Unavailable"]
    severity       = "warning"
  }

  # Custom Activity Log alerts
  custom_activity_log_alerts = {
    "rbac-changes" = {
      description    = "Alert for RBAC role assignment changes"
      category       = "Administrative"
      operation_name = "Microsoft.Authorization/roleAssignments/write"
      severity       = "security"
    }
    "nsg-changes" = {
      description    = "Alert for NSG rule modifications"
      category       = "Administrative"
      operation_name = "Microsoft.Network/networkSecurityGroups/securityRules/write"
      severity       = "network"
    }
  }

  # Custom Metric alerts - scopes from module outputs
  custom_metric_alerts = {
    "firewall-throughput" = {
      description = "High throughput on Azure Firewall"
      scopes      = [module.azure_firewall.id]  # From module output
      severity    = "warning"
      criteria = [{
        metric_namespace = "Microsoft.Network/azureFirewalls"
        metric_name      = "Throughput"
        aggregation      = "Average"
        operator         = "GreaterThan"
        threshold        = 900000000
      }]
    }
  }

  # Custom Log Query alerts - scopes from module outputs
  custom_log_query_alerts = {
    "failed-logins" = {
      description = "Multiple failed login attempts"
      scopes      = [module.log_analytics.id]  # From module output
      query       = <<-QUERY
        SigninLogs
        | where ResultType != "0"
        | summarize FailedCount = count() by UserPrincipalName, bin(TimeGenerated, 5m)
        | where FailedCount > 5
      QUERY
      threshold   = 0
      operator    = "GreaterThan"
      severity    = "security"
    }
  }

  additional_tags = {
    DeployedBy = "Terraform"
  }
}
```

### Disable Default Alerts

```hcl
module "monitor_alerts" {
  source = "../M04-monitor-alerts"

  workload            = "platform"
  environment         = "dev"
  owner               = "dev-team@company.com"
  cost_center         = "DEV-001"
  application         = "Development"
  resource_group_name = "rg-management-dev-aue-001"

  # Disable all default alerts
  create_default_alerts = false

  # Only create custom alerts
  custom_metric_alerts = {
    # ... your custom alerts
  }
}
```

## Inputs

### Required Inputs

| Name | Type | Description |
|------|------|-------------|
| `workload` | `string` | Workload name for resource naming (2-30 chars) |
| `environment` | `string` | Environment: prod, nonprod, dev, test, sandbox |
| `owner` | `string` | Email address of resource owner |
| `cost_center` | `string` | Cost center code for billing |
| `application` | `string` | Application name for tagging |
| `resource_group_name` | `string` | Resource group for alert resources |

### Optional Inputs - Naming

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `region` | `string` | `"aue"` | Azure region abbreviation |
| `instance` | `string` | `"001"` | Instance number |
| `custom_name_prefix` | `string` | `null` | Override F02 naming |

### Optional Inputs - Tags

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `criticality` | `string` | `"High"` | Business criticality level |
| `data_classification` | `string` | `"Internal"` | Data classification |
| `project` | `string` | `null` | Project name |
| `department` | `string` | `null` | Department name |
| `additional_tags` | `map(string)` | `{}` | Additional custom tags |

### Optional Inputs - Scopes

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `subscription_ids` | `list(string)` | `[]` | List of subscription IDs to monitor (UUIDs only, not full resource IDs) |
| `default_scopes` | `list(string)` | `[]` | Full resource IDs for scopes (takes precedence over subscription_ids) |
| `log_analytics_workspace_id` | `string` | `null` | Log Analytics workspace ID from M01 module |

**Scope Resolution Priority:**
1. `default_scopes` if provided (full resource IDs)
2. `subscription_ids` if provided (converted to `/subscriptions/{id}`)
3. Current subscription from provider context (automatic fallback)

### Optional Inputs - Action Groups

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `action_group_ids` | `map(string)` | `{}` | Map of action group IDs by severity key |
| `severity_action_group_mapping` | `map(string)` | See below | Custom severity to action group mapping |

Default severity mapping:
```hcl
{
  critical = "critical"
  high     = "critical"
  warning  = "warning"
  medium   = "warning"
  info     = "info"
  low      = "info"
  security = "security"
  backup   = "backup"
  network  = "network"
}
```

### Optional Inputs - Default Alerts

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `create_default_alerts` | `bool` | `true` | Create default platform alerts |
| `service_health_alert_config` | `object` | See variables.tf | Service Health alert configuration |
| `resource_health_alert_config` | `object` | See variables.tf | Resource Health alert configuration |
| `activity_log_admin_alert_config` | `object` | See variables.tf | Admin delete alert configuration |
| `activity_log_security_alert_config` | `object` | See variables.tf | Security alert configuration |

### Optional Inputs - Custom Alerts

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `custom_activity_log_alerts` | `map(object)` | `{}` | Custom Activity Log alerts |
| `custom_metric_alerts` | `map(object)` | `{}` | Custom metric alerts |
| `custom_log_query_alerts` | `map(object)` | `{}` | Custom log query alerts |

## Outputs

| Name | Description |
|------|-------------|
| `generated_name_prefix` | Name prefix from F02 pattern |
| `tags` | All tags from F03 pattern |
| `service_health_alert_id` | Service Health alert ID |
| `service_health_alert_name` | Service Health alert name |
| `resource_health_alert_id` | Resource Health alert ID |
| `resource_health_alert_name` | Resource Health alert name |
| `admin_delete_alert_id` | Admin delete alert ID |
| `security_alert_id` | Security alert ID |
| `custom_activity_alert_ids` | Map of custom Activity Log alert IDs |
| `custom_metric_alert_ids` | Map of custom metric alert IDs |
| `custom_log_alert_ids` | Map of custom log query alert IDs |
| `default_alerts_summary` | Summary of all default alerts |
| `all_alert_ids` | Flat map of all alert IDs |
| `alert_count` | Total count of alerts created |
| `configuration` | Complete configuration summary |
| `outputs_for_diagnostics` | Pre-formatted outputs for M05 integration |

## Default Alerts Details

### Service Health Alert
Monitors Azure service health events:
- **Events**: Incident, Maintenance (configurable: Security, HealthAdvisory, ActionRequired)
- **Regions**: Australia East, Australia Southeast, Global
- **Action Group**: Critical

### Resource Health Alert
Monitors resource availability:
- **Current States**: Degraded, Unavailable
- **Previous States**: Available
- **Reason Types**: PlatformInitiated, Unknown
- **Action Group**: Warning

### Activity Log - Administrative
Monitors delete operations on critical resources:
- Resource Groups
- Virtual Machines
- SQL Servers
- Storage Accounts
- Key Vaults
- Virtual Networks
- Recovery Services Vaults
- **Action Group**: Warning

### Activity Log - Security
Monitors security-related changes:
- Policy assignment deletions
- Policy exemption creations
- Security contact deletions
- Defender pricing changes
- **Action Group**: Security

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    M04 Monitor Alerts                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ Service Health  │  │ Resource Health │  │  Activity Log   │ │
│  │     Alert       │  │     Alert       │  │    Alerts       │ │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘ │
│           │                    │                    │          │
│           ▼                    ▼                    ▼          │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │            Severity → Action Group Mapping              │   │
│  │  critical → M03.critical  |  warning → M03.warning     │   │
│  │  security → M03.security  |  info → M03.info           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│                              ▼                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                M03 Action Groups                         │   │
│  │  Email | SMS | Webhook | ITSM | Logic Apps | Functions  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Dependencies

```
M01 log-analytics-workspace
 └── M03 monitor-action-groups
      └── M04 monitor-alerts (this module)
           └── M05 diagnostic-settings (optional consumer)
```

## Best Practices

1. **Always integrate with M03**: Pass `action_group_ids` from M03 for proper alert routing
2. **Use severity mapping**: Let the module route alerts to appropriate action groups
3. **Start with defaults**: Enable default alerts first, then add custom alerts as needed
4. **Scope appropriately**: Use `default_scopes` for multi-subscription environments
5. **Test in non-prod**: Deploy to non-prod first to validate alert configurations

## Troubleshooting

### Alerts Not Firing
1. Verify action group IDs are correct
2. Check alert scope includes target resources
3. Confirm alert is enabled (`enabled = true`)

### Missing Action Group Mapping
If severity doesn't map to an action group:
1. Ensure `action_group_ids` includes the required key
2. Check `severity_action_group_mapping` configuration
3. Verify M03 module outputs the expected keys

## License

Proprietary - Internal use only.
