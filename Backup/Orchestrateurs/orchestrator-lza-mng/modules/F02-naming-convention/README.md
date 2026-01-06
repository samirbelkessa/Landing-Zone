# Module F02: naming-convention

## Description

Module utilitaire Terraform générant des noms de ressources conformes aux conventions de nommage Azure Cloud Adoption Framework (CAF). Ce module centralise toutes les règles de nommage pour garantir la cohérence dans l'ensemble de la Landing Zone.

### Fonctionnalités

- ✅ **100+ types de ressources** supportés avec leurs contraintes spécifiques
- ✅ **Préfixes/slugs CAF** automatiques (rg-, vnet-, st-, kv-, etc.)
- ✅ **Contraintes de longueur** respectées automatiquement
- ✅ **Transformations** : lowercase, alphanumeric-only selon le type
- ✅ **Suffixes aléatoires** pour noms globalement uniques
- ✅ **Validation intégrée** avec messages d'erreur explicites
- ✅ **Abréviations régions** et environnements standardisées

## Prérequis

- Terraform >= 1.5.0
- Aucun provider Azure requis (module pur Terraform)

## Dépendances

Aucune dépendance externe. Ce module est utilisé comme base par tous les autres modules.

## Usage

### Exemple basique

```hcl
module "rg_name" {
  source = "./modules/naming-convention"

  resource_type = "rg"
  workload      = "hub"
  environment   = "prod"
  region        = "aue"
}

# Output: rg-hub-prd-aue
```

### Exemple avec instance

```hcl
module "vnet_name" {
  source = "./modules/naming-convention"

  resource_type = "vnet"
  workload      = "spoke"
  environment   = "prod"
  region        = "aue"
  instance      = "001"
}

# Output: vnet-spoke-prd-aue-001
```

### Exemple Storage Account (globalement unique)

```hcl
module "storage_name" {
  source = "./modules/naming-convention"

  resource_type        = "st"
  workload             = "diag"
  environment          = "prod"
  region               = "aue"
  random_suffix_length = 4
}

# Output: stdiagprdaue7x2k (lowercase, no hyphens, 24 chars max)
```

### Exemple Key Vault

```hcl
module "kv_name" {
  source = "./modules/naming-convention"

  resource_type        = "kv"
  workload             = "platform"
  environment          = "prod"
  region               = "aue"
  random_suffix_length = 4
}

# Output: kv-platform-prd-aue-a3b2 (24 chars max)
```

### Exemple avec nom personnalisé (legacy)

```hcl
module "legacy_name" {
  source = "./modules/naming-convention"

  resource_type = "vnet"
  workload      = "ignored"
  environment   = "prod"
  custom_name   = "existing-vnet-legacy"
}

# Output: existing-vnet-legacy (conventions ignorées)
```

### Exemple projet Australie - Nommage complet

```hcl
# Resource Group Hub
module "rg_hub" {
  source = "./modules/naming-convention"

  resource_type = "rg"
  workload      = "hub-connectivity"
  environment   = "prod"
  region        = "aue"
}
# Output: rg-hub-connectivity-prd-aue

# Virtual Network Hub
module "vnet_hub" {
  source = "./modules/naming-convention"

  resource_type = "vnet"
  workload      = "hub"
  environment   = "prod"
  region        = "aue"
}
# Output: vnet-hub-prd-aue

# Azure Firewall
module "afw_hub" {
  source = "./modules/naming-convention"

  resource_type = "afw"
  workload      = "hub"
  environment   = "prod"
  region        = "aue"
}
# Output: afw-hub-prd-aue

# Log Analytics Workspace
module "log_platform" {
  source = "./modules/naming-convention"

  resource_type = "log"
  workload      = "platform"
  environment   = "prod"
  region        = "aue"
}
# Output: log-platform-prd-aue

# Recovery Services Vault
module "rsv_backup" {
  source = "./modules/naming-convention"

  resource_type = "rsv"
  workload      = "backup"
  environment   = "prod"
  region        = "aue"
}
# Output: rsv-backup-prd-aue

# Spoke VNets
module "vnet_spoke" {
  source   = "./modules/naming-convention"
  for_each = toset(["web", "app", "data"])

  resource_type = "vnet"
  workload      = "spoke-${each.key}"
  environment   = "prod"
  region        = "aue"
}
# Outputs: vnet-spoke-web-prd-aue, vnet-spoke-app-prd-aue, vnet-spoke-data-prd-aue
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `resource_type` | Type de ressource Azure (ex: 'rg', 'vnet', 'st', 'kv') | `string` | n/a | ✅ |
| `workload` | Nom du workload/application (2-30 chars, lowercase) | `string` | n/a | ✅ |
| `environment` | Environnement: prod, nonprod, dev, test, uat, stg, sandbox | `string` | n/a | ✅ |
| `region` | Abréviation région Azure (ex: 'aue', 'aus', 'weu') | `string` | `"aue"` | ❌ |
| `instance` | Numéro d'instance (ex: '001', '01', '1') | `string` | `null` | ❌ |
| `suffix` | Suffixe personnalisé optionnel | `string` | `null` | ❌ |
| `use_slug` | Inclure le préfixe de type (rg-, vnet-, etc.) | `bool` | `true` | ❌ |
| `separator` | Séparateur entre composants ('-', '', '_') | `string` | `"-"` | ❌ |
| `random_suffix_length` | Longueur du suffixe aléatoire (0-8) | `number` | `0` | ❌ |
| `custom_name` | Nom personnalisé (contourne les conventions) | `string` | `null` | ❌ |

## Outputs

| Name | Description |
|------|-------------|
| `name` | Nom généré conforme aux conventions CAF |
| `name_unique` | Nom avec suffixe unique (hash ou random) |
| `slug` | Préfixe du type de ressource |
| `workload` | Composant workload |
| `environment` | Nom complet de l'environnement |
| `environment_abbreviation` | Abréviation de l'environnement (prd, dev, etc.) |
| `region` | Abréviation région utilisée |
| `instance` | Numéro d'instance si fourni |
| `max_length` | Longueur maximale pour ce type |
| `actual_length` | Longueur du nom généré |
| `lowercase_required` | Si ce type requiert lowercase |
| `alphanumeric_only` | Si ce type n'accepte que alphanumeric |
| `scope` | Portée d'unicité (global, resource_group, etc.) |
| `is_valid` | Validation du nom généré |
| `validation_message` | Message de validation |
| `resource_definitions` | Map complète des types supportés |
| `region_abbreviations` | Map des abréviations régions |
| `environment_abbreviations` | Map des abréviations environnements |

## Types de ressources supportés

### Foundation
| Code | Type | Max Length | Scope |
|------|------|------------|-------|
| `mg` | Management Group | 90 | tenant |
| `rg` | Resource Group | 90 | subscription |
| `sub` | Subscription | 64 | tenant |
| `policy` | Policy Definition | 128 | definition |
| `init` | Policy Initiative | 128 | definition |
| `role` | Role Definition | 64 | definition |

### Networking
| Code | Type | Max Length | Scope |
|------|------|------------|-------|
| `vnet` | Virtual Network | 64 | resource_group |
| `snet` | Subnet | 80 | vnet |
| `nsg` | Network Security Group | 80 | resource_group |
| `rt` | Route Table | 80 | resource_group |
| `pip` | Public IP | 80 | resource_group |
| `lb` | Load Balancer | 80 | resource_group |
| `nat` | NAT Gateway | 80 | resource_group |

### Security & Identity
| Code | Type | Max Length | Scope |
|------|------|------------|-------|
| `kv` | Key Vault | 24 | global |
| `id` | Managed Identity | 128 | resource_group |
| `pep` | Private Endpoint | 80 | resource_group |

### Compute
| Code | Type | Max Length | Scope |
|------|------|------------|-------|
| `vm` | Virtual Machine | 15 | resource_group |
| `vmss` | VM Scale Set | 64 | resource_group |
| `aks` | AKS Cluster | 63 | resource_group |

### Storage
| Code | Type | Max Length | Lowercase | Alphanum Only |
|------|------|------------|-----------|---------------|
| `st` | Storage Account | 24 | ✅ | ✅ |
| `dls` | Data Lake Storage | 24 | ✅ | ✅ |

### Databases
| Code | Type | Max Length | Scope |
|------|------|------------|-------|
| `sql` | SQL Server | 63 | global |
| `sqldb` | SQL Database | 128 | server |
| `cosmos` | Cosmos DB | 44 | global |

### Management
| Code | Type | Max Length | Scope |
|------|------|------------|-------|
| `log` | Log Analytics | 63 | resource_group |
| `aa` | Automation Account | 50 | resource_group |
| `rsv` | Recovery Services Vault | 50 | resource_group |

## Abréviations régions

| Région Azure | Abréviation |
|--------------|-------------|
| australiaeast | aue |
| australiasoutheast | aus |
| westeurope | weu |
| northeurope | neu |
| eastus | eus |
| westus | wus |
| ... | ... |

## Abréviations environnements

| Environnement | Abréviation |
|---------------|-------------|
| prod | prd |
| nonprod | npd |
| dev | dev |
| test | tst |
| uat | uat |
| stg | stg |
| sandbox | sbx |

## Validation

Le module valide automatiquement :
- Longueur maximale du nom
- Caractères autorisés (alphanumeric-only pour certains types)
- Casse (lowercase pour certains types)
- Format du workload et de l'instance

```hcl
# Exemple de validation
output "name_validation" {
  value = {
    name    = module.storage_name.name
    valid   = module.storage_name.is_valid
    message = module.storage_name.validation_message
    length  = "${module.storage_name.actual_length}/${module.storage_name.max_length}"
  }
}
```

## Bonnes pratiques

1. **Toujours utiliser le module** pour garantir la cohérence
2. **Ne pas utiliser custom_name** sauf pour ressources legacy
3. **Utiliser random_suffix_length** pour noms globalement uniques
4. **Vérifier is_valid** en cas de doute sur les contraintes

## Notes importantes

- Les Storage Accounts ont des contraintes strictes : 24 chars max, lowercase, alphanumeric uniquement
- Les VM sont limitées à 15 caractères (Windows) 
- Les Key Vaults sont limités à 24 caractères
- Certaines ressources ont une portée globale (nécessitent unicité mondiale)

## Changelog

### v1.0.0
- Version initiale avec 100+ types de ressources
- Support des conventions CAF Australia
- Validation intégrée
