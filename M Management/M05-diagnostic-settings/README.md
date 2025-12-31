# M05 - Diagnostic Settings Module

## Description

Module Terraform générique et réutilisable pour configurer les **Diagnostic Settings** sur n'importe quelle ressource Azure. Ce module permet de centraliser la configuration de la collecte des logs et métriques vers différentes destinations (Log Analytics, Storage Account, Event Hub).

## Caractéristiques

- ✅ **Générique** : Fonctionne avec n'importe quelle ressource Azure supportant les diagnostics
- ✅ **Multi-destinations** : Supporte Log Analytics, Storage Account et Event Hub simultanément
- ✅ **Auto-découverte** : Détecte automatiquement les catégories de logs/métriques disponibles
- ✅ **Filtrage flexible** : Active toutes les catégories par défaut ou sélection personnalisée
- ✅ **Rétention configurable** : Gestion de la rétention pour Storage Account (90 jours par défaut)
- ✅ **Tables dédiées** : Support du mode `Dedicated` pour Log Analytics (recommandé)
- ✅ **Validation** : Vérifie qu'au moins une destination est configurée

## Prérequis

### Dépendances

- **F02** (naming-convention) : Pour nommage cohérent
- **F03** (tags) : Pour tagging standardisé
- **M01** (log-analytics-workspace) : Workspace LA existant (optionnel)
- **M08** (diagnostics-storage-account) : Storage dédié diagnostics (optionnel)

### Permissions requises

Le principal de service Terraform doit avoir les permissions suivantes :
- `Microsoft.Insights/diagnosticSettings/write` sur la ressource cible
- `Reader` sur les destinations (LA Workspace, Storage Account, Event Hub)

### Ressources supportées

Le module fonctionne avec toutes les ressources Azure supportant les diagnostics, notamment :
- Virtual Machines
- Virtual Networks
- Network Security Groups
- Key Vaults
- Application Gateways
- Azure Firewall
- Storage Accounts
- SQL Databases
- Et bien d'autres...

## Utilisation

### Exemple basique - Envoyer vers Log Analytics

```hcl
module "vnet_diagnostics" {
  source = "../../modules/m05-diagnostic-settings"

  target_resource_id         = azurerm_virtual_network.hub.id
  log_analytics_workspace_id = module.log_analytics.workspace_id

  tags = {
    Environment = "Production"
    Owner       = "Platform Team"
    CostCenter  = "IT-OPS-001"
  }
}
```

### Exemple avancé - Multi-destinations avec sélection de catégories

```hcl
module "firewall_diagnostics" {
  source = "../../modules/m05-diagnostic-settings"

  # Ressource cible
  target_resource_id = azurerm_firewall.hub.id
  name               = "diag-azfw-hub-australiaeast"

  # Destinations multiples
  log_analytics_workspace_id = module.log_analytics.workspace_id
  storage_account_id         = module.diagnostics_storage.storage_account_id

  # Configuration Log Analytics
  log_analytics_destination_type = "Dedicated" # Tables dédiées recommandées

  # Sélection des catégories de logs
  enabled_log_categories = [
    "AzureFirewallApplicationRule",
    "AzureFirewallNetworkRule",
    "AzureFirewallDnsProxy"
  ]

  # Toutes les métriques activées par défaut
  enabled_metric_categories = null

  # Rétention pour Storage Account
  logs_retention_days    = 90  # Conforme exigence client
  metrics_retention_days = 90

  tags = {
    Environment = "Production"
    Owner       = "Network Team"
    CostCenter  = "IT-SEC-002"
    Application = "Hub Firewall"
  }
}
```

### Exemple - Désactiver les logs mais garder les métriques

```hcl
module "nsg_diagnostics" {
  source = "../../modules/m05-diagnostic-settings"

  target_resource_id         = azurerm_network_security_group.spoke.id
  log_analytics_workspace_id = module.log_analytics.workspace_id

  # Désactiver tous les logs
  enabled_log_categories = ["none"]

  # Garder toutes les métriques
  enabled_metric_categories = null

  tags = var.default_tags
}
```

### Exemple - Configuration pour projet Australie

```hcl
# ============================================================================
# DIAGNOSTIC SETTINGS - HUB VIRTUAL NETWORK
# ============================================================================

module "hub_vnet_diagnostics" {
  source = "../../modules/m05-diagnostic-settings"

  target_resource_id         = module.hub_vnet.vnet_id
  name                       = "diag-vnet-hub-australiaeast"
  log_analytics_workspace_id = module.log_analytics.workspace_id
  storage_account_id         = module.diagnostics_storage.storage_account_id

  # Tables dédiées pour meilleure requêtabilité
  log_analytics_destination_type = "Dedicated"

  # Toutes les catégories activées
  enabled_log_categories    = null
  enabled_metric_categories = null

  # Rétention 90 jours (exigence client)
  logs_retention_days    = 90
  metrics_retention_days = 90

  tags = {
    Environment = "Production"
    Owner       = "Network Team"
    CostCenter  = "IT-NET-001"
    Application = "Landing Zone Hub"
    Region      = "Australia East"
  }
}

# ============================================================================
# DIAGNOSTIC SETTINGS - AZURE FIREWALL
# ============================================================================

module "firewall_diagnostics" {
  source = "../../modules/m05-diagnostic-settings"

  target_resource_id         = module.azure_firewall.firewall_id
  name                       = "diag-azfw-hub-australiaeast"
  log_analytics_workspace_id = module.log_analytics.workspace_id
  storage_account_id         = module.diagnostics_storage.storage_account_id

  log_analytics_destination_type = "Dedicated"

  # Logs critiques pour sécurité
  enabled_log_categories = [
    "AzureFirewallApplicationRule",
    "AzureFirewallNetworkRule",
    "AzureFirewallDnsProxy",
    "AzureFirewallThreatIntelLog"
  ]

  logs_retention_days    = 90
  metrics_retention_days = 90

  tags = {
    Environment = "Production"
    Owner       = "Security Team"
    CostCenter  = "IT-SEC-001"
    Application = "Azure Firewall"
    Region      = "Australia East"
  }
}

# ============================================================================
# DIAGNOSTIC SETTINGS - KEY VAULT
# ============================================================================

module "keyvault_diagnostics" {
  source = "../../modules/m05-diagnostic-settings"

  target_resource_id         = module.key_vault.key_vault_id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  storage_account_id         = module.diagnostics_storage.storage_account_id

  log_analytics_destination_type = "Dedicated"

  # Logs d'audit pour compliance
  enabled_log_categories = [
    "AuditEvent"
  ]

  logs_retention_days    = 90
  metrics_retention_days = 90

  tags = {
    Environment = "Production"
    Owner       = "Security Team"
    CostCenter  = "IT-SEC-001"
    Application = "Key Vault"
    Region      = "Australia East"
  }
}
```

## Inputs

| Nom | Description | Type | Défaut | Requis |
|-----|-------------|------|--------|--------|
| `target_resource_id` | ID de la ressource Azure cible | `string` | - | ✅ |
| `name` | Nom du diagnostic setting (auto-généré si omis) | `string` | `null` | ❌ |
| `log_analytics_workspace_id` | ID du Log Analytics Workspace | `string` | `null` | ❌ |
| `storage_account_id` | ID du Storage Account pour archivage | `string` | `null` | ❌ |
| `eventhub_authorization_rule_id` | ID de la règle d'autorisation Event Hub | `string` | `null` | ❌ |
| `eventhub_name` | Nom de l'Event Hub | `string` | `null` | ❌ |
| `log_analytics_destination_type` | Type de destination LA (`Dedicated` ou `AzureDiagnostics`) | `string` | `"Dedicated"` | ❌ |
| `enabled_log_categories` | Liste des catégories de logs à activer (`null` = toutes, `["none"]` = aucune) | `list(string)` | `null` | ❌ |
| `enabled_metric_categories` | Liste des catégories de métriques à activer (`null` = toutes, `["none"]` = aucune) | `list(string)` | `null` | ❌ |
| `logs_retention_days` | Rétention logs en jours (0-365, 0 = illimité) | `number` | `90` | ❌ |
| `metrics_retention_days` | Rétention métriques en jours (0-365, 0 = illimité) | `number` | `90` | ❌ |
| `tags` | Tags à assigner (mergés avec tags par défaut) | `map(string)` | `{}` | ❌ |

## Outputs

| Nom | Description |
|-----|-------------|
| `id` | ID du diagnostic setting |
| `name` | Nom du diagnostic setting |
| `target_resource_id` | ID de la ressource cible |
| `log_analytics_workspace_id` | ID du LA Workspace (si configuré) |
| `storage_account_id` | ID du Storage Account (si configuré) |
| `eventhub_authorization_rule_id` | ID de la règle Event Hub (si configuré) |
| `eventhub_name` | Nom de l'Event Hub (si configuré) |
| `enabled_log_categories` | Liste des catégories de logs activées |
| `enabled_metric_categories` | Liste des catégories de métriques activées |
| `available_log_categories` | Liste de toutes les catégories de logs disponibles |
| `available_metric_categories` | Liste de toutes les catégories de métriques disponibles |
| `logs_retention_days` | Nombre de jours de rétention des logs |
| `metrics_retention_days` | Nombre de jours de rétention des métriques |
| `log_analytics_destination_type` | Type de destination Log Analytics |

## Notes importantes

### Rétention des logs

- **Rétention Storage Account** : Configurée via `logs_retention_days` (90 jours par défaut)
- **Rétention Log Analytics** : Configurée au niveau du Workspace (90 jours interactif + archive 1.1 ans)
- **Rétention Event Hub** : Gérée par le consumer

### Tables Log Analytics

Le mode `Dedicated` (recommandé) envoie les logs dans des tables spécifiques à la ressource :
- Meilleure performance des requêtes KQL
- Schéma adapté au type de ressource
- Simplifie les requêtes Azure Monitor

Le mode `AzureDiagnostics` (legacy) envoie tous les logs dans la table générique :
- Utilisé pour compatibilité avec anciennes configurations
- Peut créer des problèmes de limites de colonnes (500 max)

### Découverte automatique des catégories

Le module utilise `azurerm_monitor_diagnostic_categories` pour découvrir dynamiquement :
- Les catégories de logs disponibles pour la ressource
- Les catégories de métriques disponibles

Cela permet au module de s'adapter automatiquement à tout type de ressource.

### Multi-destinations

Vous pouvez configurer plusieurs destinations simultanément :
- Log Analytics (requêtes temps réel, alertes)
- Storage Account (archivage long terme, compliance)
- Event Hub (streaming vers SIEM externe)

**Important** : Au moins une destination doit être configurée, sinon le module génère une erreur.

## Intégration avec l'orchestrateur

### Bloc à ajouter dans `orchestrator-lza-mng`

```hcl
# ============================================================================
# DIAGNOSTIC SETTINGS (Optional)
# ============================================================================

variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings for management resources"
  type        = bool
  default     = true
}

variable "diagnostic_settings_config" {
  description = "Configuration for diagnostic settings on management resources"
  type = object({
    log_analytics_workspace_id     = string
    storage_account_id             = optional(string)
    log_analytics_destination_type = optional(string, "Dedicated")
    logs_retention_days            = optional(number, 90)
    metrics_retention_days         = optional(number, 90)
  })
  default = null
}

# Diagnostic settings for Log Analytics Workspace
module "law_diagnostics" {
  count  = var.enable_diagnostic_settings && var.diagnostic_settings_config != null ? 1 : 0
  source = "../../modules/m05-diagnostic-settings"

  target_resource_id                = module.log_analytics_workspace.workspace_id
  name                              = "diag-law-${var.location}"
  log_analytics_workspace_id        = var.diagnostic_settings_config.log_analytics_workspace_id
  storage_account_id                = var.diagnostic_settings_config.storage_account_id
  log_analytics_destination_type    = var.diagnostic_settings_config.log_analytics_destination_type
  logs_retention_days               = var.diagnostic_settings_config.logs_retention_days
  metrics_retention_days            = var.diagnostic_settings_config.metrics_retention_days

  tags = merge(var.tags, {
    Resource = "Log Analytics Workspace Diagnostics"
  })
}

# Diagnostic settings for Automation Account
module "automation_diagnostics" {
  count  = var.enable_diagnostic_settings && var.diagnostic_settings_config != null ? 1 : 0
  source = "../../modules/m05-diagnostic-settings"

  target_resource_id                = module.automation_account.automation_account_id
  name                              = "diag-aa-${var.location}"
  log_analytics_workspace_id        = var.diagnostic_settings_config.log_analytics_workspace_id
  storage_account_id                = var.diagnostic_settings_config.storage_account_id
  log_analytics_destination_type    = var.diagnostic_settings_config.log_analytics_destination_type
  logs_retention_days               = var.diagnostic_settings_config.logs_retention_days
  metrics_retention_days            = var.diagnostic_settings_config.metrics_retention_days

  tags = merge(var.tags, {
    Resource = "Automation Account Diagnostics"
  })
}
```

### Exemple d'utilisation dans tfvars

```hcl
enable_diagnostic_settings = true

diagnostic_settings_config = {
  log_analytics_workspace_id     = "/subscriptions/.../resourceGroups/rg-mng-australiaeast/providers/Microsoft.OperationalInsights/workspaces/law-mng-australiaeast"
  storage_account_id             = "/subscriptions/.../resourceGroups/rg-mng-australiaeast/providers/Microsoft.Storage/storageAccounts/stdiagaue001"
  log_analytics_destination_type = "Dedicated"
  logs_retention_days            = 90
  metrics_retention_days         = 90
}
```

## Checklist de validation

Avant de déployer le module :

### Structure ✅
- [x] versions.tf avec contraintes provider
- [x] variables.tf avec types et descriptions
- [x] locals.tf avec tags merger
- [x] main.tf avec ressources commentées
- [x] outputs.tf avec tous attributs utiles
- [x] README.md avec exemples

### Variables ✅
- [x] Toutes typées explicitement
- [x] Toutes documentées (description)
- [x] Required sans default
- [x] Validations si contraintes métier

### Ressources ✅
- [x] Nommage cohérent (this)
- [x] Tags via local.tags
- [x] dynamic blocks pour configurations optionnelles
- [x] Validation qu'au moins une destination est configurée

### Réutilisabilité ✅
- [x] Aucun hardcode spécifique projet
- [x] Defaults génériques
- [x] Prérequis documentés
- [x] Dépendances listées

## Support

Pour toute question ou problème, consulter :
- Documentation Azure : [Diagnostic Settings](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings)
- Documentation Terraform : [azurerm_monitor_diagnostic_setting](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting)
