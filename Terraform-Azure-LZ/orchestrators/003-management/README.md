# Orchestrator 03-Management

## Description

Cet orchestrateur déploie la couche Management (M01-M08) de la Landing Zone Azure.

**Lit les remote states :**
- `foundation.tfstate` → Locations, tags communs, tenant_id
- `governance.tfstate` → Policy IDs (pour référence future)

**Les modules M01-M08 appellent F02 et F03 en interne** pour le nommage et les tags.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                   REMOTE STATE DEPENDENCIES                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  foundation.tfstate ────────────────────────────────────────┐          │
│  ├── primary_location = "australiaeast"                     │          │
│  ├── secondary_location = "australiasoutheast"              │          │
│  ├── allowed_regions = ["australiaeast", "australiasoutheast"]         │
│  ├── tenant_id                                              │          │
│  ├── root_id = "intelly"                                    │          │
│  └── common_tags                                            │          │
│                                                             ▼          │
│  governance.tfstate ──────────────────────────┐   ┌────────────────┐  │
│  ├── policy_definition_ids                    │   │ 03-Management  │  │
│  ├── all_initiative_ids                       ├──►│                │  │
│  └── all_assignment_ids                       │   │ M01-M08        │  │
│                                               │   └────────────────┘  │
└───────────────────────────────────────────────┴─────────────────────────┘
```

## Modules déployés

| Module | Description | Dépendances |
|--------|-------------|-------------|
| **M01** | Log Analytics Workspace | - |
| **M02** | Automation Account | M01 |
| **M03** | Monitor Action Groups | - |
| **M04** | Monitor Alerts | M01, M03 |
| **M05** | Diagnostic Settings | M01 |
| **M06** | Update Management | - |
| **M07** | Data Collection Rules | M01 |
| **M08** | Diagnostics Storage Account | - |

## Flux des données

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      ORCHESTRATOR 03-MANAGEMENT                         │
│                                                                         │
│  data.tf:                                                               │
│  ├── terraform_remote_state.foundation → locals.tf                     │
│  └── terraform_remote_state.governance → (future use)                  │
│                                                                         │
│  locals.tf:                                                             │
│  ├── primary_location   = foundation.outputs.primary_location          │
│  ├── secondary_location = foundation.outputs.secondary_location        │
│  ├── primary_region     = location_abbrev[primary_location] → "aue"   │
│  └── common_tags        = foundation.outputs.common_tags               │
│                                                                         │
└─────────────────────┬───────────────────────────────────────────────────┘
                      │
          ┌───────────┴───────────┐
          ▼                       ▼
┌─────────────────────┐   ┌─────────────────────┐
│        M01          │   │        M02          │
│   Log Analytics     │   │  Automation Account │
├─────────────────────┤   ├─────────────────────┤
│ Inputs from orch:   │   │ Inputs from orch:   │
│ ├── workload        │   │ ├── workload        │
│ ├── environment     │   │ ├── environment     │
│ ├── region (aue)    │   │ ├── region (aue)    │
│ └── location        │   │ └── location        │
├─────────────────────┤   ├─────────────────────┤
│ INTERNAL F02/F03:   │   │ INTERNAL F02/F03:   │
│ ┌─────────────────┐ │   │ ┌─────────────────┐ │
│ │ module "naming" │ │   │ │ module "naming" │ │
│ │   resource:log  │ │   │ │   resource:aa   │ │
│ └─────────────────┘ │   │ └─────────────────┘ │
├─────────────────────┤   ├─────────────────────┤
│ OUTPUT:             │   │ OUTPUT:             │
│ log-platform-prd-   │   │ aa-platform-prd-    │
│ aue-001             │   │ aue-001             │
└─────────────────────┘   └─────────────────────┘
```

## Prérequis

1. **01-foundation** déployé avec `foundation.tfstate`
2. **02-governance** déployé avec `governance.tfstate`
3. Accès au Storage Account contenant les tfstates

## Configuration

### 1. Remplacer les placeholders

```powershell
# Windows PowerShell
$files = Get-ChildItem -Path "*.tf" -Recurse
foreach ($file in $files) {
    (Get-Content $file.FullName) `
        -replace '__TFSTATE_SUBSCRIPTION_ID__', 'votre-subscription-id' `
        -replace '__TFSTATE_RESOURCE_GROUP__', 'rg-terraform-state' `
        -replace '__TFSTATE_STORAGE_ACCOUNT__', 'stterraformstate' `
        -replace '__MANAGEMENT_SUBSCRIPTION_ID__', 'votre-management-sub-id' |
    Set-Content $file.FullName
}
```

### 2. Configurer terraform.tfvars

```hcl
# Emails et webhooks
owner               = "platform-team@company.com"
cost_center         = "IT-PLATFORM-001"

default_email_receivers = [
  {
    name          = "PlatformTeam"
    email_address = "platform-team@company.com"
  }
]
```

## Usage

```bash
cd orchestrators/03-management

# Initialiser avec backend
terraform init

# Planifier
terraform plan

# Appliquer
terraform apply
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
# }
```

## Outputs principaux

| Output | Description |
|--------|-------------|
| `m01_log_analytics_id` | Resource ID du Log Analytics |
| `m01_log_analytics_workspace_id` | Workspace ID (GUID) |
| `m02_automation_account_id` | Resource ID Automation Account |
| `m03_action_group_ids` | Map des Action Groups |
| `m07_dcr_ids` | Map des Data Collection Rules |
| `m08_diagnostics_storage_id` | Storage Account diagnostics |
| `deployment_status` | Status de chaque module |

## Outputs pour orchestrateurs suivants

```hcl
# 04-connectivity peut utiliser :
# - m01_log_analytics_id pour diagnostic settings
# - m08_diagnostics_storage_id pour flow logs

# 05-subscriptions peut utiliser :
# - m03_action_group_ids pour alertes
# - m07_dcr_ids pour VM monitoring
```

## Ordre de déploiement

```
01-foundation     ✅ Déployé
      │
      ▼
02-governance     ✅ Déployé
      │
      ▼
03-management     ◄── VOUS ÊTES ICI
      │
      ▼
04-connectivity   ⏳ Prochain
      │
      ▼
05-subscriptions  ⏳ À venir
```

## Troubleshooting

### Erreur: Remote state not found

```
Error: Unable to find remote state "foundation"
```

**Solution:** Vérifier que 01-foundation a été déployé et que les credentials backend sont corrects.

### Erreur: Variable not found

```
Error: Reference to undeclared input variable
```

**Solution:** Les variables `primary_location` et `secondary_location` viennent maintenant du remote state foundation. Ne pas les déclarer dans terraform.tfvars.

## Structure des fichiers

```
orchestrators/03-management/
├── versions.tf       # Backend azurerm + providers
├── providers.tf      # Provider azurerm config
├── data.tf           # Remote states (foundation, governance)
├── locals.tf         # Valeurs dérivées des remote states
├── variables.tf      # Variables (sans locations!)
├── main.tf           # Appels modules M01-M08
├── outputs.tf        # Outputs pour orchestrateurs suivants
├── terraform.tfvars  # Configuration spécifique projet
└── README.md         # Ce fichier
```
