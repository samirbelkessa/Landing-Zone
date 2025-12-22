# Orchestrateur Management Layer

## Description

Cet orchestrateur déploie la couche Management (M01-M08) de la Landing Zone Azure. Les modules M01 et M02 appellent **F02 et F03 en interne** pour le nommage et les tags.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      ORCHESTRATOR MANAGEMENT                            │
│                                                                         │
│  Variables passées:                                                     │
│  - project_name = "platform"                                            │
│  - environment = "prod"                                                 │
│  - owner, cost_center, application, etc.                               │
│                                                                         │
└─────────────────────┬───────────────────────────────────────────────────┘
                      │
          ┌───────────┴───────────┐
          ▼                       ▼
┌─────────────────────┐   ┌─────────────────────┐
│        M01          │   │        M02          │
│   Log Analytics     │   │  Automation Account │
├─────────────────────┤   ├─────────────────────┤
│ INTERNE:            │   │ INTERNE:            │
│ ┌─────────────────┐ │   │ ┌─────────────────┐ │
│ │ module "naming" │ │   │ │ module "naming" │ │
│ │   source: F02   │ │   │ │   source: F02   │ │
│ │ resource: "log" │ │   │ │ resource: "aa"  │ │
│ └─────────────────┘ │   │ └─────────────────┘ │
│                     │   │                     │
│ ┌─────────────────┐ │   │ ┌─────────────────┐ │
│ │ module "tags"   │ │   │ │ module "tags"   │ │
│ │   source: F03   │ │   │ │   source: F03   │ │
│ └─────────────────┘ │   │ └─────────────────┘ │
├─────────────────────┤   ├─────────────────────┤
│ OUTPUT:             │   │ OUTPUT:             │
│ log-platform-prd-   │   │ aa-platform-prd-    │
│ aue-001             │   │ aue-001             │
└─────────────────────┘   └─────────────────────┘
```

## Flux d'appel F02/F03

```
Orchestrator
    │
    ├── module "m01_log_analytics" {
    │       workload    = var.project_name    ──┐
    │       environment = var.environment       │
    │       region      = local.primary_region  ├── Passés à M01
    │       owner       = var.owner             │
    │       cost_center = var.cost_center     ──┘
    │   }
    │       │
    │       └── M01 main.tf
    │               │
    │               ├── module "naming" {        ◄── F02 appelé ICI
    │               │       source = "../F02-naming-convention"
    │               │       resource_type = "log"
    │               │       workload = var.workload
    │               │   }
    │               │
    │               └── module "tags" {          ◄── F03 appelé ICI
    │                       source = "../F03-tags"
    │                       environment = local.f03_environment
    │                       owner = var.owner
    │                   }
    │
    └── module "m02_automation_account" { ... }
            │
            └── (même pattern)
```

## Usage

```bash
cd orchestrators/management
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

## Vérifier les noms générés

```bash
# Après apply
terraform output m01_naming_details
terraform output m02_naming_details

# Résultat attendu:
# m01_naming_details = {
#   name = "log-platform-prd-aue-001"
#   slug = "log"
#   ...
# }
# m02_naming_details = {
#   name = "aa-platform-prd-aue-001"
#   slug = "aa"
#   ...
# }
```

## Vérifier les tags générés

```bash
terraform output m01_tags
terraform output m02_tags

# Résultat attendu:
# {
#   Application = "Platform Management"
#   CostCenter = "IT-PLATFORM-001"
#   Criticality = "Critical"
#   Environment = "Production"
#   ManagedBy = "Terraform"
#   Module = "M01-log-analytics-workspace"
#   Owner = "platform-team@yourcompany.com"
#   ...
# }
```

## Structure des Modules

```
modules/
├── F02-naming-convention/     ◄── Module de nommage CAF
├── F03-tags/                  ◄── Module de tags standardisés
├── M01-log-analytics-workspace/
│   └── main.tf
│       ├── module "naming" { source = "../F02-naming-convention" }
│       └── module "tags" { source = "../F03-tags" }
├── M02-automation-account/
│   └── main.tf
│       ├── module "naming" { source = "../F02-naming-convention" }
│       └── module "tags" { source = "../F03-tags" }
└── ...

orchestrators/
└── management/
    ├── main.tf
    │   ├── module "m01_log_analytics" { source = "../../modules/M01-..." }
    │   └── module "m02_automation_account" { source = "../../modules/M02-..." }
    └── terraform.tfvars
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `project_name` | Nom du projet pour F02 | `string` | `"platform"` |
| `environment` | Environnement (prod, dev, etc.) | `string` | `"prod"` |
| `owner` | Email owner pour F03 | `string` | Required |
| `cost_center` | Cost center pour F03 | `string` | Required |
| `application` | Application pour F03 | `string` | `"Platform Management"` |
| `deploy_m01_log_analytics` | Déployer M01 | `bool` | `true` |
| `deploy_m02_automation` | Déployer M02 | `bool` | `false` |

## Outputs

| Name | Description |
|------|-------------|
| `m01_naming_details` | Détails F02 pour M01 |
| `m01_tags` | Tags F03 pour M01 |
| `m02_naming_details` | Détails F02 pour M02 |
| `m02_tags` | Tags F03 pour M02 |
| `deployment_status` | Status de chaque module |
