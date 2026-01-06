# M03 - Monitor Action Groups

## Description

This module creates and manages Azure Monitor Action Groups, which define the receivers and actions to be triggered when an alert fires. Action Groups are a fundamental component of Azure monitoring and alerting, supporting multiple notification channels.

### Supported Receiver Types

| Receiver Type | Description | Use Case |
|---------------|-------------|----------|
| **Email** | Send email notifications | Team notifications, on-call alerts |
| **SMS** | Send SMS messages | Critical alerts requiring immediate attention |
| **Voice** | Automated voice calls | Escalation for critical issues |
| **Webhook** | HTTP POST to custom endpoint | Teams, Slack, ServiceNow, custom integrations |
| **Azure Function** | Trigger serverless function | Custom remediation logic |
| **Logic App** | Trigger Logic App workflow | Complex automation workflows |
| **Automation Runbook** | Execute Azure Automation runbook | Auto-remediation scripts |
| **ARM Role** | Notify Azure RBAC role members | Role-based notifications |
| **Event Hub** | Stream to Event Hub | SIEM integration, analytics |
| **ITSM** | Create ITSM ticket | ServiceNow, SCSM integration |

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Azure Monitor Alerts (M04)                       │
│                              │                                       │
│                              ▼                                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                   Action Groups (M03)                          │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │  │
│  │  │  Critical   │  │   Warning   │  │    Info     │            │  │
│  │  │ (Sev 0-1)   │  │  (Sev 2-3)  │  │   (Sev 4)   │            │  │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘            │  │
│  └─────────┼────────────────┼────────────────┼───────────────────┘  │
│            │                │                │                       │
│            ▼                ▼                ▼                       │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │                         Receivers                                ││
│  │  📧 Email  📱 SMS  🔔 Voice  🔗 Webhook  ⚡ Function  🔄 Logic  ││
│  └─────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────┘
```

## Prerequisites

- **Terraform**: >= 1.5.0
- **Provider**: azurerm >= 3.80.0
- **Modules requis**: F02-naming-convention, F03-tags
- **Dependencies**: 
  - M01 Log Analytics Workspace (for ITSM receivers)
  - Resource Group must exist

## Integration with F02 and F03

This module **calls F02 and F03 internally** - you don't need to call them separately.

### F02 - Naming Convention

```hcl
# Called internally in main.tf
module "naming" {
  source = "../F02-naming-convention"

  resource_type = "ag"           # Action Group
  workload      = var.workload   # ex: "platform"
  environment   = var.environment # ex: "prod"
  region        = var.region     # ex: "aue"
  instance      = var.instance   # ex: "001"
}
# Result: ag-platform-prd-aue-001
```

### F03 - Tags

```hcl
# Called internally in main.tf
module "tags" {
  source = "../F03-tags"

  environment         = local.f03_environment  # Mapped from var.environment
  owner               = var.owner
  cost_center         = var.cost_center
  application         = var.application
  criticality         = var.criticality
  data_classification = var.data_classification
  module_name         = "M03-monitor-action-groups"
}
```

### Environment Mapping (F02 → F03)

| F02 Input (var.environment) | F03 Input (local.f03_environment) |
|-----------------------------|-----------------------------------|
| `prod` | `Production` |
| `nonprod` | `PreProduction` |
| `dev` | `Development` |
| `test` | `Test` |
| `uat` | `PreProduction` |
| `stg` | `PreProduction` |
| `sandbox` | `Sandbox` |

## Usage

### Basic Example - Default Action Groups

```hcl
module "action_groups" {
  source = "./modules/M03-monitor-action-groups"

  # F02 Naming inputs
  workload    = "platform"
  environment = "prod"
  region      = "aue"

  # Resource placement
  resource_group_name = "rg-management-prd-aue-001"

  # F03 Tagging inputs
  owner       = "platform-team@company.com"
  cost_center = "IT-PLATFORM-001"
  application = "Platform Monitoring"

  # Create default action groups (Critical, Warning, Info)
  create_default_action_groups = true
  default_email_receivers = [
    {
      name          = "PlatformTeam"
      email_address = "platform-team@company.com"
    },
    {
      name          = "OnCallEngineer"
      email_address = "oncall@company.com"
    }
  ]
  default_webhook_url = "https://company.webhook.office.com/webhookb2/..."
}
```

### Advanced Example - Custom Action Groups

```hcl
module "action_groups" {
  source = "./modules/M03-monitor-action-groups"

  # F02 Naming inputs
  workload    = "platform"
  environment = "prod"
  region      = "aue"

  # Resource placement
  resource_group_name = "rg-management-prd-aue-001"

  # F03 Tagging inputs
  owner       = "platform-team@company.com"
  cost_center = "IT-PLATFORM-001"
  application = "Platform Monitoring"
  criticality = "Critical"

  # Custom Action Groups
  action_groups = {
    # Severity 0-1: Critical issues requiring immediate response
    sev01 = {
      short_name = "Sev01"
      enabled    = true

      email_receivers = [
        {
          name          = "PlatformTeam"
          email_address = "platform-team@company.com"
        }
      ]

      sms_receivers = [
        {
          name         = "OnCallPrimary"
          country_code = "61"
          phone_number = "400000001"
        }
      ]

      webhook_receivers = [
        {
          name        = "TeamsChannel"
          service_uri = "https://company.webhook.office.com/webhookb2/critical"
        },
        {
          name        = "PagerDuty"
          service_uri = "https://events.pagerduty.com/integration/xxx/enqueue"
        }
      ]

      automation_runbook_receivers = [
        {
          name                  = "AutoRemediate"
          automation_account_id = module.automation.id
          runbook_name          = "AutoRemediate-Critical"
          webhook_resource_id   = module.automation.webhooks["auto-remediate"].id
          service_uri           = module.automation.webhooks["auto-remediate"].uri
        }
      ]
    }

    # Severity 2-3: Warning issues
    sev23 = {
      short_name = "Sev23"
      enabled    = true

      email_receivers = [
        {
          name          = "PlatformTeam"
          email_address = "platform-team@company.com"
        }
      ]

      webhook_receivers = [
        {
          name        = "TeamsChannel"
          service_uri = "https://company.webhook.office.com/webhookb2/warning"
        }
      ]
    }

    # Severity 4: Informational
    sev4 = {
      short_name = "Sev4"
      enabled    = true

      email_receivers = [
        {
          name          = "PlatformTeamDaily"
          email_address = "platform-daily@company.com"
        }
      ]
    }

    # ServiceNow Integration
    servicenow = {
      short_name = "ServiceNow"
      enabled    = true

      itsm_receivers = [
        {
          name                 = "ServiceNowProd"
          workspace_id         = module.log_analytics.workspace_id
          connection_id        = azurerm_log_analytics_linked_service.servicenow.id
          ticket_configuration = jsonencode({
            Priority = "2"
            Category = "Azure"
          })
          region = "australiaeast"
        }
      ]
    }
  }
}
```

### Example - Integration with M04 Alerts

```hcl
module "action_groups" {
  source = "./modules/M03-monitor-action-groups"
  # ... configuration ...
}

module "alerts" {
  source = "./modules/M04-monitor-alerts"

  # Use outputs from M03
  action_groups = module.action_groups.outputs_for_m04

  # Define alerts...
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| `workload` | Workload name for F02 naming | `string` | Yes | - |
| `environment` | Environment: prod, nonprod, dev, test, sandbox | `string` | Yes | - |
| `resource_group_name` | Resource Group name | `string` | Yes | - |
| `owner` | Owner email for F03 tags | `string` | Yes | - |
| `cost_center` | Cost center for F03 tags | `string` | Yes | - |
| `application` | Application name for F03 tags | `string` | Yes | - |
| `region` | Region abbreviation for F02 | `string` | No | `"aue"` |
| `instance` | Instance number for F02 | `string` | No | `"001"` |
| `custom_name` | Custom name (bypasses F02) | `string` | No | `null` |
| `criticality` | Criticality level for F03 | `string` | No | `"High"` |
| `data_classification` | Data classification for F03 | `string` | No | `"Internal"` |
| `project` | Project name for F03 | `string` | No | `null` |
| `department` | Department for F03 | `string` | No | `null` |
| `additional_tags` | Additional custom tags | `map(string)` | No | `{}` |
| `action_groups` | Map of Action Groups to create | `map(object)` | No | `{}` |
| `create_default_action_groups` | Create default groups (Critical, Warning, Info) | `bool` | No | `false` |
| `default_email_receivers` | Default email receivers | `list(object)` | No | `[]` |
| `default_webhook_url` | Default webhook URL | `string` | No | `null` |

## Outputs

| Name | Description |
|------|-------------|
| `action_group_ids` | Map of Action Group IDs by key |
| `action_group_names` | Map of Action Group names by key |
| `action_group_short_names` | Map of Action Group short names by key |
| `critical_action_group_id` | ID of the Critical Action Group (if created) |
| `warning_action_group_id` | ID of the Warning Action Group (if created) |
| `info_action_group_id` | ID of the Info Action Group (if created) |
| `generated_name` | Name from F02 module |
| `naming_details` | Full F02 naming details (name, slug, environment_abbreviation, is_valid, etc.) |
| `tags` | All tags from F03 module |
| `tags_details` | F03 tag details (environment, is_production, is_critical, etc.) |
| `configuration` | Complete configuration summary |
| `outputs_for_m04` | Pre-formatted outputs for M04 alerts module |

## Best Practices

1. **Severity-based grouping**: Create separate Action Groups for different severity levels
2. **Common Alert Schema**: Enable `use_common_alert_schema` for consistent payload format
3. **Multi-channel notifications**: Use multiple receiver types for critical alerts
4. **Auto-remediation**: Integrate with Automation Runbooks for known issues
5. **ITSM integration**: Connect to ServiceNow/SCSM for ticket creation

## Dependencies

```
F02-naming-convention ◄── Called internally
F03-tags              ◄── Called internally

M01 Log Analytics Workspace
 └── M03 Monitor Action Groups
      └── M04 Monitor Alerts
```

## Module Structure

```
M03-monitor-action-groups/
├── versions.tf       # Terraform and provider constraints
├── variables.tf      # Input variables (F02 + F03 inputs)
├── locals.tf         # Environment mapping, action groups config
├── main.tf           # F02/F03 module calls + Action Group resources
├── outputs.tf        # Outputs from F02, F03, and resources
├── README.md         # Documentation
└── examples/
    └── australia-lz.tfvars  # Example for Australia project
```

## License

Proprietary - Internal use only
