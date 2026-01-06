# M01 - Log Analytics Workspace Module

## Description

Ce module Terraform crée un workspace Azure Log Analytics avec intégration complète des modules F02 (naming-convention) et F03 (tags). Il constitue le hub central de logging pour la Landing Zone.

## Fonctionnalités

- **Naming automatique** : Nom généré via F02 (pattern: `log-{workload}-{env}-{region}-{instance}`)
- **Tags standardisés** : Tags générés via F03 (Environment, Owner, CostCenter, etc.)
- **Rétention flexible** : 90 jours interactif + archive configurable par table
- **Solutions** : SecurityInsights, VMInsights, Updates, ChangeTracking, etc.
- **DR optionnel** : Workspace secondaire dans une région DR
- **Diagnostic settings** : Auto-logging du workspace

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                   Log Analytics Workspace (M01)                      │
│  Name: log-{workload}-{env}-{region}-{instance} (via F02)           │
│  Tags: via F03 module                                                │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │ Retention: 90 days interactive + 310 days archive              │ │
│  │ Tables with custom archive: SecurityEvent, Syslog, AuditLogs   │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │ Solutions: SecurityInsights, VMInsights, Updates, ChangeTracking│ │
│  └────────────────────────────────────────────────────────────────┘ │
│                              │                                       │
│            ┌─────────────────┼─────────────────┐                    │
│            ▼                 ▼                 ▼                    │
│       ┌────────┐       ┌────────┐       ┌────────┐                 │
│       │  M02   │       │  M05   │       │  S02   │                 │
│       │Automat.│       │ Diag.  │       │Sentinel│                 │
│       └────────┘       └────────┘       └────────┘                 │
└─────────────────────────────────────────────────────────────────────┘
```

## Prérequis

- **Terraform** : >= 1.5.0
- **Provider** : azurerm >= 3.80.0
- **Modules requis** : F02-naming-convention, F03-tags

## Intégration F02 et F03

### F02 - Naming Convention

```hcl
module "naming" {
  source = "../F02-naming-convention"

  resource_type = "log"          # Log Analytics Workspace
  workload      = var.workload   # ex: "platform"
  environment   = var.environment # ex: "prod"
  region        = var.region     # ex: "aue"
  instance      = var.instance   # ex: "001"
}
# Résultat : log-platform-prd-aue-001
```

### F03 - Tags

```hcl
module "tags" {
  source = "../F03-tags"

  environment         = "Production"  # Mappé depuis var.environment
  owner               = var.owner
  cost_center         = var.cost_center
  application         = var.application
  module_name         = "M01-log-analytics-workspace"
}
```

## Usage

### Exemple Basique

```hcl
module "log_analytics" {
  source = "./modules/M01-log-analytics-workspace"

  # F02 Naming inputs
  workload    = "platform"
  environment = "prod"
  region      = "aue"
  instance    = "001"

  # Resource placement
  resource_group_name = "rg-management-prd-aue-001"
  location            = "australiaeast"

  # F03 Tagging inputs
  owner       = "platform-team@company.com"
  cost_center = "IT-PLATFORM-001"
  application = "Platform Management"
}
```

### Exemple Complet (Australie)

```hcl
module "log_analytics" {
  source = "./modules/M01-log-analytics-workspace"

  # F02 Naming inputs
  workload    = "platform"
  environment = "prod"
  region      = "aue"
  instance    = "001"

  # Resource placement
  resource_group_name = "rg-management-prd-aue-001"
  location            = "australiaeast"

  # F03 Tagging inputs
  owner               = "platform-team@company.com"
  cost_center         = "IT-PLATFORM-001"
  application         = "Platform Management"
  criticality         = "Critical"
  data_classification = "Internal"
  project             = "Azure-Landing-Zone"

  # Retention
  retention_in_days       = 90
  total_retention_in_days = 400  # ~1.1 years

  # Archive tables
  enable_table_level_archive = true
  archive_tables = {
    "SecurityEvent" = 400
    "Syslog"        = 400
    "AzureActivity" = 400
    "SigninLogs"    = 400
    "AuditLogs"     = 400
    "Perf"          = 180
  }

  # Solutions
  deploy_solutions = true

  # DR (optional)
  enable_cross_region_workspace = false
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| `workload` | Workload name for F02 naming | `string` | Yes | - |
| `environment` | Environment (prod, nonprod, dev, test, sandbox) | `string` | Yes | - |
| `region` | Azure region abbreviation | `string` | No | `"aue"` |
| `instance` | Instance number | `string` | No | `"001"` |
| `resource_group_name` | Resource group name | `string` | Yes | - |
| `location` | Azure region | `string` | Yes | - |
| `owner` | Owner email for F03 tags | `string` | Yes | - |
| `cost_center` | Cost center for F03 tags | `string` | Yes | - |
| `application` | Application name for F03 tags | `string` | Yes | - |
| `retention_in_days` | Interactive retention | `number` | No | `90` |
| `total_retention_in_days` | Total retention | `number` | No | `400` |
| `deploy_solutions` | Deploy LA solutions | `bool` | No | `true` |

## Outputs

| Name | Description |
|------|-------------|
| `id` | Resource ID |
| `workspace_id` | Workspace GUID |
| `name` | Workspace name |
| `generated_name` | Name from F02 |
| `naming_details` | Full F02 details |
| `tags` | All F03 tags |
| `tags_details` | F03 tag details |
| `primary_shared_key` | Primary key (sensitive) |
| `configuration` | Full config summary |
| `outputs_for_m02` | Outputs for Automation Account |

## Modules Dépendants

- **M02** : Automation Account (linked service)
- **M05** : Diagnostic Settings
- **M07** : Data Collection Rules
- **S01** : Defender for Cloud
- **S02** : Microsoft Sentinel

## License

Proprietary - Internal use only
