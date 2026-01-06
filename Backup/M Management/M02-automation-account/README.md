# M02 - Automation Account Module

## Description

Ce module Terraform crée un compte Azure Automation avec intégration complète des modules F02 (naming-convention) et F03 (tags). Il est lié au workspace Log Analytics pour supporter :

- **Update Management** : Gestion des mises à jour VMs Windows/Linux
- **Change Tracking** : Suivi des modifications système
- **Inventory** : Inventaire logiciel et matériel
- **Runbooks** : Scripts PowerShell/Python automatisés
- **DSC** : Desired State Configuration
- **Schedules** : Planification des tâches
- **Credentials** : Stockage sécurisé des identifiants

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Management Resource Group                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                    Automation Account                          │  │
│  │  Name: aa-{workload}-{env}-{region}-{instance} (via F02)      │  │
│  │  Tags: Environment, Owner, CostCenter, etc. (via F03)         │  │
│  │  ┌─────────────────────────────────────────────────────────┐  │  │
│  │  │ Managed Identity: System Assigned                        │  │  │
│  │  │ SKU: Basic                                               │  │  │
│  │  └─────────────────────────────────────────────────────────┘  │  │
│  │                                                               │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐  │  │
│  │  │    Runbooks     │  │   Schedules     │  │ Credentials  │  │  │
│  │  │  - PowerShell   │  │  - Maintenance  │  │  - Service   │  │  │
│  │  │  - Python 3     │  │  - Patching     │  │    Accounts  │  │  │
│  │  └─────────────────┘  └─────────────────┘  └──────────────┘  │  │
│  │                                                               │  │
│  │  ┌─────────────────┐  ┌─────────────────┐                    │  │
│  │  │      DSC        │  │    Webhooks     │                    │  │
│  │  │ Configurations  │  │  - Triggers     │                    │  │
│  │  └─────────────────┘  └─────────────────┘                    │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                              │                                       │
│                              │ Linked Service                        │
│                              ▼                                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │              Log Analytics Workspace (M01)                     │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

## Prérequis

- **Terraform** : >= 1.5.0
- **Provider** : azurerm >= 3.80.0
- **Modules requis** : F02-naming-convention, F03-tags
- **Dépendances** : M01 Log Analytics Workspace

## Intégration F02 et F03

### F02 - Naming Convention

```hcl
module "naming" {
  source = "../F02-naming-convention"

  resource_type = "aa"           # Automation Account
  workload      = var.workload   # ex: "platform"
  environment   = var.environment # ex: "prod"
  region        = var.region     # ex: "aue"
  instance      = var.instance   # ex: "001"
}
# Résultat : aa-platform-prd-aue-001
```

### F03 - Tags

```hcl
module "tags" {
  source = "../F03-tags"

  environment         = "Production"  # Mappé depuis var.environment
  owner               = var.owner
  cost_center         = var.cost_center
  application         = var.application
  module_name         = "M02-automation-account"
}
```

## Usage

### Exemple Basique

```hcl
module "automation_account" {
  source = "./modules/M02-automation-account"

  # F02 Naming inputs
  workload    = "platform"
  environment = "prod"
  region      = "aue"

  # Resource placement
  resource_group_name = "rg-management-prd-aue-001"
  location            = "australiaeast"

  # F03 Tagging inputs
  owner       = "platform-team@company.com"
  cost_center = "IT-PLATFORM-001"
  application = "Platform Management"

  # Link to Log Analytics
  log_analytics_workspace_id = module.log_analytics.id
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| `workload` | Workload name for F02 naming | `string` | Yes | - |
| `environment` | Environment | `string` | Yes | - |
| `region` | Azure region abbreviation | `string` | No | `"aue"` |
| `instance` | Instance number | `string` | No | `"001"` |
| `resource_group_name` | Resource group name | `string` | Yes | - |
| `location` | Azure region | `string` | Yes | - |
| `owner` | Owner email for F03 tags | `string` | Yes | - |
| `cost_center` | Cost center for F03 tags | `string` | Yes | - |
| `application` | Application name for F03 tags | `string` | Yes | - |
| `log_analytics_workspace_id` | LA workspace ID | `string` | No | `null` |
| `runbooks` | Map of runbooks | `map(object)` | No | `{}` |
| `schedules` | Map of schedules | `map(object)` | No | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| `id` | Resource ID |
| `name` | Automation Account name |
| `generated_name` | Name from F02 module |
| `naming_details` | Full F02 naming details |
| `tags` | All F03 tags |
| `tags_details` | F03 tag details |
| `principal_id` | Managed identity principal ID |
| `configuration` | Full config summary |
| `outputs_for_m06` | Outputs for Update Management |

## License

Proprietary - Internal use only
