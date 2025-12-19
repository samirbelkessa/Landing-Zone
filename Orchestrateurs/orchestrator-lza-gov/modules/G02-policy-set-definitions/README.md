# Module G02: Policy Set Definitions (Initiatives)

## Description

Ce module crée les **Azure Policy Set Definitions** (Initiatives) pour le projet Landing Zone Azure CAF. Les initiatives regroupent plusieurs policies par domaine fonctionnel pour faciliter leur assignation et gestion.

Le module déploie deux types d'initiatives :

1. **Initiatives Baseline CAF** - Policies communes à toute la hiérarchie :
   - Security Baseline (TLS, HTTPS, Defender, Key Vault)
   - Network Baseline (NSG, routing, hub validation)
   - Monitoring Baseline (diagnostics, Log Analytics, AMA)
   - Governance Baseline (tags, locations, resource types)
   - Backup Baseline (GRS/LRS, cross-region restore)
   - Cost Management (budgets)
   - Identity Baseline (managed identity, Entra DS)

2. **Initiatives Archétype** - Policies spécifiques par type de Landing Zone :
   - Online-Prod (WAF obligatoire, HTTPS, GRS backup)
   - Online-NonProd (WAF recommandé, LRS backup)
   - Corp-Prod (DENY IP publiques, Private Endpoints obligatoires)
   - Corp-NonProd (DENY IP publiques, PE recommandés)
   - Sandbox (Audit only, SKUs limités, tag Expiration)
   - Decommissioned (DENY all)

## Prérequis

- **Module G01** (policy-definitions) doit être déployé en premier
- Permissions : `Policy Contributor` sur le Management Group cible
- Management Group hierarchy créée (module F01)

## Dépendances

```
G01 policy-definitions
 └── G02 policy-set-definitions (ce module)
      └── G03 policy-assignments
```

## Usage Basique

```hcl
module "policy_set_definitions" {
  source = "./modules/policy-set-definitions"

  # Required
  management_group_id   = module.management_groups.root_management_group_id
  policy_definition_ids = module.policy_definitions.policy_definition_ids

  # Optional - Pass built-in policy IDs from G01 for consistency
  builtin_policy_ids     = module.policy_definitions.builtin_policy_ids
  builtin_initiative_ids = module.policy_definitions.builtin_initiative_ids

  # Tags
  tags = {
    Environment = "Production"
    Owner       = "Platform Team"
    CostCenter  = "IT-001"
    Application = "Landing Zone"
  }
}
```

## Usage Avancé - Projet Australie

```hcl
module "policy_set_definitions" {
  source = "./modules/policy-set-definitions"

  # Required - Outputs from G01
  management_group_id   = "/providers/Microsoft.Management/managementGroups/myorg-root"
  policy_definition_ids = module.policy_definitions.policy_definition_ids

  # Optional - Built-in IDs from G01 for consistency
  builtin_policy_ids     = module.policy_definitions.builtin_policy_ids
  builtin_initiative_ids = module.policy_definitions.builtin_initiative_ids

  # CAF Baseline Initiatives
  deploy_caf_initiatives     = true
  deploy_security_initiative = true
  deploy_network_initiative  = true
  deploy_monitoring_initiative = true
  deploy_governance_initiative = true
  deploy_backup_initiative   = true
  deploy_cost_initiative     = true
  deploy_identity_initiative = true

  # Archetype-Specific Initiatives
  deploy_archetype_initiatives = true
  archetypes_to_deploy = [
    "online-prod",
    "online-nonprod",
    "corp-prod",
    "corp-nonprod",
    "sandbox",
    "decommissioned"
  ]

  # Built-in Initiatives Integration
  include_azure_security_benchmark = true
  include_vm_insights              = true
  include_nist_initiative          = false  # Enable for NIST compliance
  include_iso27001_initiative      = false  # Enable for ISO 27001 compliance

  # Parameters for Australia Project
  allowed_regions = ["australiaeast", "australiasoutheast"]
  log_analytics_workspace_id = module.log_analytics.workspace_id
  log_retention_days         = 90
  required_tags = ["Environment", "Owner", "CostCenter", "Application"]
  
  # Sandbox restrictions
  allowed_vm_skus_sandbox = [
    "Standard_B1s",
    "Standard_B1ms",
    "Standard_B2s",
    "Standard_B2ms",
    "Standard_D2s_v3",
    "Standard_D2s_v4",
    "Standard_D2s_v5"
  ]
  expensive_resource_types = [
    "Microsoft.Network/expressRouteCircuits",
    "Microsoft.Network/expressRouteGateways",
    "Microsoft.Sql/managedInstances",
    "Microsoft.Cache/redisEnterprise"
  ]

  # Custom Initiative Example
  custom_policy_set_definitions = {
    "custom-data-protection" = {
      display_name = "Data Protection Initiative"
      description  = "Custom initiative for data protection requirements"
      policy_definition_references = [
        {
          policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/..."
          reference_id         = "DataEncryption"
        }
      ]
    }
  }

  tags = {
    Environment = "Production"
    Owner       = "Platform Team"
    CostCenter  = "IT-PLATFORM-001"
    Application = "Azure Landing Zone"
  }
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| `management_group_id` | ID du Management Group où les initiatives seront définies | `string` | ✅ | - |
| `policy_definition_ids` | Map des noms de policies vers leurs IDs (output de G01) | `map(string)` | ✅ | - |
| `builtin_policy_ids` | Map des built-in policy IDs depuis G01 | `map(string)` | ❌ | `{}` |
| `builtin_initiative_ids` | Map des built-in initiative IDs depuis G01 | `map(string)` | ❌ | `{}` |
| `deploy_caf_initiatives` | Déployer les initiatives CAF baseline | `bool` | ❌ | `true` |
| `deploy_security_initiative` | Déployer l'initiative Security baseline | `bool` | ❌ | `true` |
| `deploy_network_initiative` | Déployer l'initiative Network baseline | `bool` | ❌ | `true` |
| `deploy_monitoring_initiative` | Déployer l'initiative Monitoring baseline | `bool` | ❌ | `true` |
| `deploy_governance_initiative` | Déployer l'initiative Governance baseline | `bool` | ❌ | `true` |
| `deploy_backup_initiative` | Déployer l'initiative Backup baseline | `bool` | ❌ | `true` |
| `deploy_cost_initiative` | Déployer l'initiative Cost Management | `bool` | ❌ | `true` |
| `deploy_identity_initiative` | Déployer l'initiative Identity baseline | `bool` | ❌ | `true` |
| `deploy_archetype_initiatives` | Déployer les initiatives par archétype | `bool` | ❌ | `true` |
| `archetypes_to_deploy` | Liste des archétypes à déployer | `list(string)` | ❌ | Tous les archétypes |
| `include_azure_security_benchmark` | Inclure Azure Security Benchmark | `bool` | ❌ | `true` |
| `include_vm_insights` | Inclure VM Insights initiative | `bool` | ❌ | `true` |
| `include_nist_initiative` | Inclure NIST SP 800-53 Rev. 5 | `bool` | ❌ | `false` |
| `include_iso27001_initiative` | Inclure ISO 27001:2013 | `bool` | ❌ | `false` |
| `include_cis_initiative` | Inclure CIS Azure Benchmark | `bool` | ❌ | `false` |
| `allowed_regions` | Régions Azure autorisées | `list(string)` | ❌ | `["australiaeast", "australiasoutheast"]` |
| `log_analytics_workspace_id` | ID du workspace Log Analytics central | `string` | ❌ | `""` |
| `log_retention_days` | Rétention minimum logs (30-730) | `number` | ❌ | `90` |
| `required_tags` | Tags obligatoires sur les RGs | `list(string)` | ❌ | `["Environment", "Owner", "CostCenter", "Application"]` |
| `allowed_vm_skus_sandbox` | SKUs VM autorisés en Sandbox | `list(string)` | ❌ | B-series, D2s |
| `expensive_resource_types` | Types de ressources coûteuses bloqués | `list(string)` | ❌ | ExpressRoute, Redis Enterprise |
| `custom_policy_set_definitions` | Initiatives personnalisées | `map(object)` | ❌ | `{}` |
| `tags` | Tags à appliquer | `map(string)` | ❌ | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| `caf_initiative_ids` | Map des noms d'initiatives CAF vers leurs IDs |
| `caf_initiative_names` | Map des clés d'initiatives vers leurs display names |
| `caf_initiatives` | Map complète des initiatives CAF avec tous les attributs |
| `platform_initiative_id` | ID de l'initiative Platform baseline |
| `platform_initiative` | Attributs de l'initiative Platform |
| `compliance_initiative_ids` | Map des initiatives de compliance vers leurs IDs |
| `compliance_initiatives` | Map complète des initiatives de compliance |
| `custom_initiative_ids` | Map des initiatives custom vers leurs IDs |
| `custom_initiatives` | Map complète des initiatives custom |
| `all_initiative_ids` | Map de toutes les initiatives vers leurs IDs |
| `archetype_initiative_ids` | IDs des initiatives par archétype (pour Landing Zones) |
| `baseline_initiative_ids` | IDs des initiatives baseline (pour Root/Platform) |
| `summary` | Résumé du déploiement |
| `builtin_initiative_ids` | Référence aux IDs des initiatives built-in utilisées |

## Mapping Initiatives vers Management Groups

| Initiative | Management Group Cible | Effet |
|------------|----------------------|-------|
| caf-governance-baseline | Root | Deny/Modify |
| caf-security-baseline | Root | Audit/Deny |
| caf-monitoring-baseline | Root | DeployIfNotExists |
| caf-platform-baseline | Platform | Audit |
| caf-network-baseline | Platform > Connectivity | Audit |
| caf-identity-baseline | Platform > Identity | Audit |
| caf-backup-baseline | Landing Zones | Audit |
| caf-cost-baseline | Landing Zones | Audit |
| caf-online-prod | LZ > Online-Prod | Deny/Audit |
| caf-online-nonprod | LZ > Online-NonProd | Audit |
| caf-corp-prod | LZ > Corp-Prod | Deny |
| caf-corp-nonprod | LZ > Corp-NonProd | Deny/Audit |
| caf-sandbox | LZ > Sandbox | Audit/Deny |
| caf-decommissioned | Decommissioned | Deny |

## Exemple tfvars - Projet Australie

```hcl
# terraform.tfvars

management_group_id = "/providers/Microsoft.Management/managementGroups/contoso-root"

# Toutes les initiatives CAF activées
deploy_caf_initiatives       = true
deploy_archetype_initiatives = true

# Configuration Australie
allowed_regions            = ["australiaeast", "australiasoutheast"]
log_analytics_workspace_id = "/subscriptions/xxx/resourceGroups/rg-management/providers/Microsoft.OperationalInsights/workspaces/law-central"
log_retention_days         = 90

# Tags projet
required_tags = ["Environment", "Owner", "CostCenter", "Application", "Criticality"]

# Sandbox restrictions
allowed_vm_skus_sandbox = [
  "Standard_B1s",
  "Standard_B1ms", 
  "Standard_B2s",
  "Standard_B2ms"
]

# Compliance (optionnel)
include_nist_initiative    = false
include_iso27001_initiative = false

tags = {
  Environment = "Production"
  Owner       = "Platform Team"
  CostCenter  = "IT-PLATFORM-001"
  Application = "Azure Landing Zone"
  Project     = "Australia CAF"
}
```

## Compatibilité avec Module G01

Ce module est **100% compatible** avec les outputs du module G01 (policy-definitions). Le mapping des clés est le suivant :

### Clés de Policies Custom (G01 → G02)

| Catégorie | Clé G01 (policy_definition_ids) | Usage dans G02 |
|-----------|--------------------------------|----------------|
| Network | `audit-vnet-peered-to-hub` | ✅ Direct |
| Network | `audit-route-to-firewall` | ✅ Direct |
| Network | `audit-hub-vnet-australia-east` | ✅ Direct |
| Network | `audit-firewall-premium` | ✅ Direct |
| Network | `audit-private-dns-hub-link` | ✅ Direct |
| Network | `audit-public-ip-appgw-frontdoor` | ✅ Direct |
| Network | `disabled-ddos-standard` | ✅ Direct |
| Security | `deny-storage-public-access` | ✅ Direct |
| Security | `deny-sql-without-private-endpoint` | ✅ Direct |
| Security | `deny-cosmos-without-private-endpoint` | ✅ Direct |
| Security | `audit-app-service-private-endpoint` | ✅ Direct |
| Monitoring | `deploy-diagnostic-settings-la` | ✅ Direct |
| Monitoring | `audit-la-retention-minimum` | ✅ Direct |
| Monitoring | `audit-la-archive-enabled` | ✅ Direct |
| Monitoring | `audit-sentinel-connectors` | ✅ Direct |
| Backup | `audit-backup-grs-production` | ✅ Direct |
| Backup | `audit-backup-lrs-nonproduction` | ✅ Direct |
| Cost | `audit-budget-configured` | ✅ Direct |
| Cost | `deny-expensive-vm-skus-sandbox` | ✅ Direct |
| Cost | `deny-expensive-resources-sandbox` | ✅ Direct |
| Lifecycle | `deny-sandbox-without-expiration` | ✅ Direct |
| Lifecycle | `audit-only-sandbox` | ✅ Direct |
| Decommissioned | `deny-all-resource-creation` | ✅ Direct |
| Decommissioned | `deny-all-resource-modification` | ✅ Direct |

### Intégration Recommandée

```hcl
# Module G01 - Policy Definitions
module "policy_definitions" {
  source = "./modules/policy-definitions"

  management_group_id = module.management_groups.root_management_group_id
  deploy_caf_policies = true
  # ... autres variables
}

# Module G02 - Policy Set Definitions (ce module)
module "policy_set_definitions" {
  source = "./modules/policy-set-definitions"

  management_group_id    = module.management_groups.root_management_group_id
  policy_definition_ids  = module.policy_definitions.policy_definition_ids
  builtin_policy_ids     = module.policy_definitions.builtin_policy_ids
  builtin_initiative_ids = module.policy_definitions.builtin_initiative_ids

  depends_on = [module.policy_definitions]
}

# Module G03 - Policy Assignments
module "policy_assignments" {
  source = "./modules/policy-assignments"

  initiative_ids = module.policy_set_definitions.all_initiative_ids
  # ... autres variables

  depends_on = [module.policy_set_definitions]
}
```

## Notes Importantes

### Migration Brownfield

Le projet inclut ~70 policies existantes à harmoniser. L'approche recommandée :

1. Déployer les initiatives CAF en mode **Audit** d'abord
2. Analyser les non-conformités via Azure Policy Compliance
3. Créer des **exemptions** (module G04) pour les ressources legacy
4. Basculer progressivement vers **Deny** après remediation

### DDoS Standard

Le client utilise Cloudflare pour la protection DDoS. La policy DDoS Standard est **désactivée** dans ce projet (voir initiative Network baseline).

### Backup Spécificités

- **Production** : GRS avec cross-region restore (Australia East → Australia Southeast)
- **Non-Production** : LRS suffisant

Ces règles sont implémentées dans les initiatives archétype correspondantes.

## Validation

```bash
# Formater le code
terraform fmt -recursive

# Valider la syntaxe
terraform validate

# Planifier les changements
terraform plan -var-file="terraform.tfvars"
```

## Références

- [Azure Policy Built-in Initiatives](https://learn.microsoft.com/en-us/azure/governance/policy/samples/built-in-initiatives)
- [CAF Policy Portfolio](https://github.com/Azure/Enterprise-Scale/wiki/ALZ-Policies)
- [Azure Security Benchmark](https://learn.microsoft.com/en-us/security/benchmark/azure/)
