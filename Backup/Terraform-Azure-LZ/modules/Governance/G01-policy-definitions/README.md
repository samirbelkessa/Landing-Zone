# G01 - Policy Definitions Module

## Description

This module creates custom Azure Policy definitions at a management group scope, aligned with the Cloud Adoption Framework (CAF) for the Australia Landing Zone project. It provides a comprehensive set of pre-built policies covering network, security, monitoring, backup, cost management, and lifecycle requirements.

The module also exposes references to commonly used built-in policy definitions and initiatives for easy integration with policy assignments.

## Features

- **Pre-built CAF Policies**: 20+ custom policy definitions aligned with CAF best practices
- **Categorized Policies**: Network, Security, Monitoring, Backup, Cost, Lifecycle
- **Flexible Configuration**: Enable/disable policy categories as needed
- **Custom Policy Support**: Add your own custom policies alongside CAF policies
- **Built-in References**: Easy access to commonly used Azure built-in policies
- **Integration Ready**: Structured outputs for policy set definitions (G02) and assignments (G03)

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Management Group (Root)                          │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │                   Custom Policy Definitions                      ││
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐            ││
│  │  │   Network    │ │   Security   │ │  Monitoring  │            ││
│  │  │   Policies   │ │   Policies   │ │   Policies   │            ││
│  │  └──────────────┘ └──────────────┘ └──────────────┘            ││
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐            ││
│  │  │    Backup    │ │     Cost     │ │  Lifecycle   │            ││
│  │  │   Policies   │ │   Policies   │ │   Policies   │            ││
│  │  └──────────────┘ └──────────────┘ └──────────────┘            ││
│  └─────────────────────────────────────────────────────────────────┘│
│                              ▼                                       │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │          Inherited by Child Management Groups                    ││
│  │    Platform │ Landing Zones │ Sandbox │ Decommissioned          ││
│  └─────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────┘
```

## Prerequisites

- **Module F01**: Management Groups must be deployed first
- **Terraform**: >= 1.5.0
- **Provider**: azurerm >= 3.80.0
- **Permissions**: Policy Contributor or Owner at management group scope

## Dependencies

| Module | Required | Purpose |
|--------|----------|---------|
| F01 management-groups | Yes | Provides management group IDs for policy scope |
| M01 log-analytics-workspace | Optional | For diagnostic settings policy parameter |

## Usage

### Basic Usage (All CAF Policies)

```hcl
module "policy_definitions" {
  source = "./modules/policy-definitions"

  management_group_id = module.management_groups.root_mg_id
}
```

### Australia Landing Zone Configuration

```hcl
module "policy_definitions" {
  source = "./modules/policy-definitions"

  # Required
  management_group_id = module.management_groups.root_mg_id

  # CAF Policies
  deploy_caf_policies = true

  # Australia-specific configuration
  allowed_regions = ["australiaeast", "australiasoutheast"]
  
  # Log Analytics integration
  log_analytics_workspace_id = module.log_analytics.workspace_id
  log_retention_days         = 90

  # Required tags for resource groups
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

  # Enable all policy categories
  enable_network_policies    = true
  enable_security_policies   = true
  enable_monitoring_policies = true
  enable_backup_policies     = true
  enable_cost_policies       = true
  enable_lifecycle_policies  = true
}
```

### Custom Policies Only

```hcl
module "policy_definitions" {
  source = "./modules/policy-definitions"

  management_group_id = module.management_groups.root_mg_id
  deploy_caf_policies = false  # Disable pre-built CAF policies

  # Define your own custom policies
  custom_policy_definitions = {
    "require-sql-auditing" = {
      name        = "Require SQL Auditing"
      description = "Ensures SQL Server auditing is enabled"
      mode        = "Indexed"
      metadata    = {
        category = "SQL"
        version  = "1.0.0"
      }
      parameters = {
        effect = {
          type          = "String"
          defaultValue  = "AuditIfNotExists"
          allowedValues = ["AuditIfNotExists", "Disabled"]
        }
      }
      policy_rule = {
        if = {
          field  = "type"
          equals = "Microsoft.Sql/servers"
        }
        then = {
          effect = "[parameters('effect')]"
          details = {
            type = "Microsoft.Sql/servers/auditingSettings"
            existenceCondition = {
              field  = "Microsoft.Sql/servers/auditingSettings/state"
              equals = "Enabled"
            }
          }
        }
      }
    }
  }
}
```

### Mixed CAF and Custom Policies

```hcl
module "policy_definitions" {
  source = "./modules/policy-definitions"

  management_group_id = module.management_groups.root_mg_id
  deploy_caf_policies = true

  # Add custom policies alongside CAF policies
  custom_policy_definitions = {
    "audit-kubernetes-network-policy" = {
      name        = "Audit AKS Network Policy"
      description = "Audits that AKS clusters have network policy enabled"
      mode        = "Indexed"
      metadata    = { category = "Kubernetes" }
      policy_rule = {
        if = {
          allOf = [
            {
              field  = "type"
              equals = "Microsoft.ContainerService/managedClusters"
            },
            {
              field  = "Microsoft.ContainerService/managedClusters/networkProfile.networkPolicy"
              exists = "false"
            }
          ]
        }
        then = {
          effect = "audit"
        }
      }
    }
  }
}
```

## CAF Policy Definitions Included

### Network Policies

| Policy Key | Effect | Description |
|------------|--------|-------------|
| audit-hub-vnet-australia-east | Audit | Hub VNet required in Australia East |
| audit-route-to-firewall | Audit | Routes must point to Azure Firewall |
| audit-firewall-premium | Audit | Azure Firewall must use Premium SKU |
| audit-private-dns-hub-link | Audit | Private DNS zones linked to Hub |
| audit-vnet-peered-to-hub | Audit | Spoke VNets peered to Hub |
| audit-public-ip-appgw-frontdoor | Audit | Public IPs only via AppGW/FrontDoor |
| disabled-ddos-standard | Disabled | DDoS Standard not required (Cloudflare) |

### Security Policies

| Policy Key | Effect | Description |
|------------|--------|-------------|
| deny-storage-public-access | Deny | Storage accounts deny public access |
| deny-sql-without-private-endpoint | Deny | SQL requires private endpoints |
| deny-cosmos-without-private-endpoint | Deny | Cosmos DB requires private endpoints |
| audit-app-service-private-endpoint | Audit | App Service private endpoints |

### Monitoring Policies

| Policy Key | Effect | Description |
|------------|--------|-------------|
| deploy-diagnostic-settings-la | DeployIfNotExists | Auto-deploy diagnostics to LA |
| audit-la-retention-minimum | Audit | 90 days minimum retention |
| audit-la-archive-enabled | Audit | Archive enabled for 1.1 years |
| audit-sentinel-connectors | Audit | Sentinel connectors enabled |

### Backup Policies

| Policy Key | Effect | Description |
|------------|--------|-------------|
| audit-backup-grs-production | Audit | GRS required for production |
| audit-backup-lrs-nonproduction | Audit | LRS acceptable for non-prod |

### Cost Policies

| Policy Key | Effect | Description |
|------------|--------|-------------|
| audit-budget-configured | Audit | Budgets required |
| deny-expensive-vm-skus-sandbox | Deny | Limited VM SKUs in Sandbox |
| deny-expensive-resources-sandbox | Deny | Block expensive resources |

### Lifecycle Policies

| Policy Key | Effect | Description |
|------------|--------|-------------|
| deny-sandbox-without-expiration | Deny | Expiration tag required |
| audit-only-sandbox | Audit | Marker for Sandbox behavior |

### Decommissioned Policies

| Policy Key | Effect | Description |
|------------|--------|-------------|
| deny-all-resource-creation | Deny | Block all resource creation |
| deny-all-resource-modification | Deny | Block all modifications |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| management_group_id | Management group ID where policies are defined | `string` | n/a | yes |
| deploy_caf_policies | Deploy pre-built CAF policy definitions | `bool` | `true` | no |
| custom_policy_definitions | Map of custom policy definitions | `map(object)` | `{}` | no |
| allowed_regions | Allowed Azure regions | `list(string)` | `["australiaeast", "australiasoutheast"]` | no |
| log_analytics_workspace_id | Central Log Analytics workspace ID | `string` | `""` | no |
| log_retention_days | Minimum log retention days | `number` | `90` | no |
| required_tags | Required tags on resource groups | `list(string)` | `["Environment", "Owner", "CostCenter", "Application"]` | no |
| allowed_vm_skus_sandbox | Allowed VM SKUs for Sandbox | `list(string)` | B-series, D2s | no |
| denied_resource_types | Resource types to deny | `list(string)` | Classic resources | no |
| expensive_resource_types | Expensive resources to deny | `list(string)` | ExpressRoute, etc. | no |
| enable_network_policies | Enable network policies | `bool` | `true` | no |
| enable_security_policies | Enable security policies | `bool` | `true` | no |
| enable_monitoring_policies | Enable monitoring policies | `bool` | `true` | no |
| enable_backup_policies | Enable backup policies | `bool` | `true` | no |
| enable_cost_policies | Enable cost policies | `bool` | `true` | no |
| enable_lifecycle_policies | Enable lifecycle policies | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| policy_definition_ids | Map of policy names to resource IDs |
| policy_definition_names | Map of policy keys to display names |
| policy_definitions | Full policy definition attributes |
| network_policy_ids | Network policy IDs |
| security_policy_ids | Security policy IDs |
| monitoring_policy_ids | Monitoring policy IDs |
| backup_policy_ids | Backup policy IDs |
| cost_policy_ids | Cost policy IDs |
| lifecycle_policy_ids | Lifecycle policy IDs |
| decommissioned_policy_ids | Decommissioned policy IDs |
| builtin_policy_ids | Built-in policy references |
| builtin_initiative_ids | Built-in initiative references |
| policy_ids_for_initiatives | Structured output for G02 integration |
| summary | Deployment summary |

## Integration with Other Modules

### With G02 (Policy Set Definitions)

```hcl
module "policy_set_definitions" {
  source = "./modules/policy-set-definitions"

  management_group_id = module.management_groups.root_mg_id
  
  # Use structured output from G01
  custom_policies = module.policy_definitions.policy_ids_for_initiatives
  builtin_policies = module.policy_definitions.builtin_policy_ids
}
```

### With G03 (Policy Assignments)

```hcl
module "policy_assignments" {
  source = "./modules/policy-assignments"

  # Assign to specific management groups
  assignments = {
    "root-allowed-locations" = {
      policy_definition_id = module.policy_definitions.builtin_policy_ids.allowed_locations
      management_group_id  = module.management_groups.root_mg_id
      parameters = {
        listOfAllowedLocations = ["australiaeast", "australiasoutheast"]
      }
    }
    
    "corp-prod-deny-public-storage" = {
      policy_definition_id = module.policy_definitions.policy_definition_ids["deny-storage-public-access"]
      management_group_id  = module.management_groups.corp_prod_mg_id
    }
  }
}
```

## Notes

### Brownfield Migration

This module is designed to harmonize with approximately 70 existing policies from Fortinet NGFW migration. When integrating:

1. Review existing policies for overlaps
2. Use `custom_policy_definitions` to add project-specific policies
3. Consider using policy exemptions (G04) for transition period

### DDoS Standard

DDoS Standard protection is intentionally disabled in this module as applications are protected by Cloudflare. The `disabled-ddos-standard` policy documents this decision.

### Backup Configuration

- **Production**: GRS with cross-region restore (Australia East → Southeast)
- **Non-Production**: LRS is acceptable to reduce costs

## Changelog

### v1.0.0

- Initial release with 20+ CAF-aligned policies
- Support for custom policy definitions
- Built-in policy references
- Categorized policy outputs

## License

Proprietary - Internal use only
