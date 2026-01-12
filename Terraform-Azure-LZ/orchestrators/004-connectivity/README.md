# Orchestrator 04-Connectivity

## Description

Cet orchestrateur déploie la couche Connectivity de la Landing Zone Azure.

**Lit les remote states :**
- `foundation.tfstate` → Locations (australiaeast, australiasoutheast), tenant_id, root_id, common_tags
- `governance.tfstate` → Policy IDs (pour référence future)
- `management.tfstate` → Log Analytics ID (pour diagnostic settings)

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         REMOTE STATE DEPENDENCIES                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  foundation.tfstate ──────────────────────────────────────┐                │
│  ├── primary_location = "australiaeast"                   │                │
│  ├── secondary_location = "australiasoutheast"            │                │
│  ├── tenant_id                                            │                │
│  ├── root_id = "intelly"                                  ▼                │
│  └── common_tags                                  ┌────────────────┐       │
│                                                   │                │       │
│  governance.tfstate ──────────────────────────────►│ 04-Connectivity│       │
│  └── (policy IDs - future reference)              │                │       │
│                                                   │ Hub VNets      │       │
│  management.tfstate ─────────────────────────────►│ Firewalls      │       │
│  ├── m01_log_analytics_id                         │ Bastion        │       │
│  ├── m01_log_analytics_name                       │ DNS Resolver   │       │
│  └── resource_group_name                          │ VPN Gateway    │       │
│                                                   │ App Gateway    │       │
│                                                   └────────────────┘       │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Ressources déployées

| Composant | Australia East | Australia Southeast |
|-----------|----------------|---------------------|
| **Hub VNet** | vnet-hub-aue-001 (10.0.0.0/22) | vnet-hub-ause-001 (10.1.0.0/22) |
| **Azure Firewall** | afw-hub-aue-001 (Premium) | afw-hub-ause-001 (Premium) |
| **Azure Bastion** | bas-hub-aue-001 (Standard) | bas-hub-ause-001 (Standard) |
| **VPN Gateway** | vgw-hub-aue-001 (VpnGw2AZ) | ❌ (DR) |
| **DNS Resolver** | pdr-hub-aue-001 | pdr-hub-ause-001 |
| **Private DNS Zones** | ✅ (all zones) | ❌ (shared from primary) |
| **Application Gateway** | agw-hub-aue-001 (WAF_v2) | ❌ (DR) |

## Prérequis

1. **01-foundation** déployé avec `foundation.tfstate`
2. **02-governance** déployé avec `governance.tfstate`
3. **03-management** déployé avec `management.tfstate`
4. Accès au Storage Account contenant les tfstates

## Configuration

### 1. Remplacer les placeholders

**Dans versions.tf, data.tf :**
```
__TFSTATE_SUBSCRIPTION_ID__  → Subscription du Storage tfstate
__TFSTATE_RESOURCE_GROUP__   → Resource Group du Storage
__TFSTATE_STORAGE_ACCOUNT__  → Storage Account name
```

**Dans terraform.tfvars :**
```
__CONNECTIVITY_SUBSCRIPTION_ID__ → Subscription pour Connectivity
__OWNER__                        → Owner (e.g., "Platform Team")
__COST_CENTER__                  → Cost Center (e.g., "IT-Infrastructure")
```

### 2. Script de remplacement

```powershell
# PowerShell
$files = Get-ChildItem -Path "*.tf","*.tfvars" -Recurse
foreach ($file in $files) {
    (Get-Content $file.FullName) `
        -replace '__TFSTATE_SUBSCRIPTION_ID__', 'your-tfstate-sub-id' `
        -replace '__TFSTATE_RESOURCE_GROUP__', 'rg-terraform-state' `
        -replace '__TFSTATE_STORAGE_ACCOUNT__', 'stterraformstate' `
        -replace '__CONNECTIVITY_SUBSCRIPTION_ID__', 'your-connectivity-sub-id' `
        -replace '__OWNER__', 'Platform Team' `
        -replace '__COST_CENTER__', 'IT-Infrastructure' |
    Set-Content $file.FullName
}
```

## Usage

```bash
cd orchestrators/04-connectivity

# Initialiser avec backend
terraform init

# Planifier
terraform plan

# Appliquer
terraform apply
```

## Flux des données depuis remote states

```
foundation.tfstate                 management.tfstate
       │                                  │
       ▼                                  ▼
┌──────────────────┐            ┌──────────────────┐
│ primary_location │            │ log_analytics_id │
│ = "australiaeast"│            │ = "/subs/.../log-│
│                  │            │   platform-..."  │
│ secondary_location            └─────────┬────────┘
│ = "australiasoutheast"                  │
└─────────┬────────┘                      │
          │                               │
          ▼                               ▼
┌─────────────────────────────────────────────────┐
│                   locals.tf                     │
│                                                 │
│ primary_location   = foundation.primary_location│
│ secondary_location = foundation.secondary_location
│ log_analytics_id   = management.m01_log_analytics_id
│ common_tags        = foundation.common_tags     │
└─────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────┐
│                   main.tf                       │
│                                                 │
│ resource "azurerm_resource_group" "network_aue" │
│   location = local.primary_location             │
│                                                 │
│ module "alz_connectivity" {                     │
│   australiaeast = {                             │
│     location = local.primary_location           │
│   }                                             │
│ }                                               │
│                                                 │
│ resource "azurerm_monitor_diagnostic_setting"   │
│   log_analytics_workspace_id = local.log_analytics_id
└─────────────────────────────────────────────────┘
```

## Outputs pour orchestrateurs suivants

```hcl
# 05-subscriptions peut utiliser :
spoke_peering_config = {
  australiaeast = {
    hub_vnet_id         = "/subs/.../vnet-hub-aue-001"
    firewall_private_ip = "10.0.0.68"
    dns_resolver_ip     = "10.0.1.4"
    route_table_id      = "/subs/.../rt-..."
  }
}

# Pour le peering des spokes :
hub_vnet_ids = {
  australiaeast      = "/subs/.../vnet-hub-aue-001"
  australiasoutheast = "/subs/.../vnet-hub-ause-001"
}

# Pour les UDR des spokes :
firewall_private_ips = {
  australiaeast      = "10.0.0.68"
  australiasoutheast = "10.1.0.68"
}
```

## Ordre de déploiement

```
01-foundation     ✅ Déployé (14 Management Groups)
      │
      ▼
02-governance     ✅ Déployé (50 Policies)
      │
      ▼
03-management     ✅ Déployé (~35 ressources)
      │
      ▼
04-connectivity   ◄── VOUS ÊTES ICI
      │
      ▼
05-subscriptions  ⏳ Prochain
```

## Structure des fichiers

```
orchestrators/04-connectivity/
├── versions.tf       # Terraform version + backend azurerm
├── providers.tf      # Provider azurerm + azapi
├── data.tf           # Remote states (foundation, governance, management)
├── locals.tf         # Valeurs dérivées des remote states
├── variables.tf      # Variables (sans tenant_id, locations!)
├── main.tf           # Module AVM + ressources
├── outputs.tf        # Outputs pour orchestrateurs suivants
├── terraform.tfvars  # Configuration spécifique projet
└── README.md         # Ce fichier
```

## Troubleshooting

### Erreur: Remote state not found

```
Error: Unable to find remote state "foundation"
```

**Solution:** Vérifier que 01-foundation, 02-governance et 03-management ont été déployés.

### Erreur: Module not found

```
Error: Module not installed
```

**Solution:** Exécuter `terraform init` pour télécharger le module AVM.

### Erreur: Subnet overlap

```
Error: Subnet address prefix overlaps with existing subnet
```

**Solution:** Vérifier l'IP Plan dans terraform.tfvars pour éviter les chevauchements.
