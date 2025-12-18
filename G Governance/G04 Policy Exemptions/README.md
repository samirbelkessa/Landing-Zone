# Module G04: Policy Exemptions

## Description

Ce module crée les **Azure Policy Exemptions** pour le projet Landing Zone Azure CAF. Il permet de gérer les exceptions aux policies de gouvernance à différents scopes : Management Groups, Subscriptions, Resource Groups, et Resources individuelles.

Le module supporte deux types d'exemptions :

1. **Waiver** - Exception administrative temporaire :
   - Pour les cas où la conformité n'est pas encore possible
   - Doit avoir une date d'expiration (recommandé)
   - Exemple : Migration brownfield en cours

2. **Mitigated** - Conformité alternative :
   - Pour les cas où un contrôle alternatif est en place
   - Peut être permanent
   - Exemple : DDoS Standard remplacé par Cloudflare

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Policy Exemptions                                  │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                    Management Group Level                               ││
│  │  • Sandbox relaxed policies (Mitigated)                                ││
│  │  • DDoS Standard exemption (Mitigated - Cloudflare)                    ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                    Subscription Level                                   ││
│  │  • Brownfield migration exemptions (Waiver - expires)                  ││
│  │  • Legacy system exemptions (Waiver - expires)                         ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                    Resource Group Level                                 ││
│  │  • Application-specific exemptions (Waiver/Mitigated)                  ││
│  │  • Brownfield RG exemptions (Waiver - expires)                         ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                    Resource Level                                       ││
│  │  • Individual resource exemptions (granular control)                   ││
│  └─────────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────────┘
```

## Prérequis

- **Module G03** (policy-assignments) : Assignments créés pour pouvoir les exempter
- **Permissions** : `Resource Policy Contributor` au scope de l'exemption
- Terraform >= 1.5.0
- AzureRM Provider >= 3.80.0

## Dépendances

```
F01 management-groups
 └── G01 policy-definitions
      └── G02 policy-set-definitions
           └── G03 policy-assignments
                └── G04 policy-exemptions (ce module)
```

## Usage

### Basic Usage - Manual Exemptions

```hcl
module "policy_exemptions" {
  source = "./modules/policy-exemptions"

  management_group_exemptions = {
    "ddos-cloudflare-exemption" = {
      management_group_id      = "/providers/Microsoft.Management/managementGroups/contoso-root"
      policy_assignment_id     = "/providers/Microsoft.Management/managementGroups/contoso-root/providers/Microsoft.Authorization/policyAssignments/root-security-base"
      exemption_category       = "Mitigated"
      display_name             = "DDoS Standard - Cloudflare Protected"
      description              = "DDoS Standard not required - applications protected by Cloudflare WAF and DDoS protection."
      policy_definition_reference_ids = ["DdosStandardRequired"]
    }
  }

  tags = {
    Environment = "Production"
    Owner       = "Platform Team"
  }
}
```

### Brownfield Migration Configuration

```hcl
module "policy_exemptions" {
  source = "./modules/policy-exemptions"

  # Enable brownfield migration support
  enable_brownfield_exemptions  = true
  brownfield_migration_end_date = "2025-12-31T23:59:59Z"

  # Subscriptions requiring exemptions during migration
  brownfield_subscriptions = {
    "legacy-erp" = {
      subscription_id = "/subscriptions/00000000-0000-0000-0000-000000000001"
      policy_assignment_ids = [
        module.policy_assignments.mg_assignment_ids["corp-prod-initiative"],
        module.policy_assignments.mg_assignment_ids["root-security-baseline"]
      ]
      reason = "Legacy ERP - migration to private endpoints Q3 2025"
    }
    "legacy-crm" = {
      subscription_id = "/subscriptions/00000000-0000-0000-0000-000000000002"
      policy_assignment_ids = [
        module.policy_assignments.mg_assignment_ids["corp-prod-initiative"]
      ]
      reason = "Legacy CRM - vendor remediation in progress"
    }
  }

  # Resource groups requiring exemptions
  brownfield_resource_groups = {
    "rg-legacy-app" = {
      resource_group_id = "/subscriptions/xxx/resourceGroups/rg-legacy-app-prd"
      policy_assignment_ids = [
        module.policy_assignments.mg_assignment_ids["root-governance-baseline"]
      ]
      reason = "Legacy application - tagging remediation Q2 2025"
    }
  }

  tags = module.tags.all_tags
}
```

### Sandbox Exemptions

```hcl
module "policy_exemptions" {
  source = "./modules/policy-exemptions"

  # Enable Sandbox relaxed policies
  enable_sandbox_exemptions   = true
  sandbox_management_group_id = module.management_groups.sandbox_mg_id

  sandbox_exempted_policy_assignments = [
    module.policy_assignments.mg_assignment_ids["root-security-baseline"]
  ]

  tags = module.tags.all_tags
}
```

### Complete Australia Project Configuration

```hcl
module "policy_exemptions" {
  source = "./modules/policy-exemptions"

  # ═══════════════════════════════════════════════════════════════════════════
  # Brownfield Migration
  # ═══════════════════════════════════════════════════════════════════════════
  
  enable_brownfield_exemptions  = true
  brownfield_migration_end_date = "2025-12-31T23:59:59Z"

  brownfield_subscriptions = {
    "legacy-erp-subscription" = {
      subscription_id       = "/subscriptions/xxx"
      policy_assignment_ids = [module.policy_assignments.mg_assignment_ids["corp-prod-initiative"]]
      reason                = "Fortinet NGFW migration - private endpoints Q3 2025"
    }
  }

  brownfield_resource_groups = {
    "rg-fortinet-legacy" = {
      resource_group_id     = "/subscriptions/xxx/resourceGroups/rg-fortinet-prd"
      policy_assignment_ids = [module.policy_assignments.mg_assignment_ids["root-network-baseline"]]
      reason                = "Fortinet appliances pending decommission"
    }
  }

  # ═══════════════════════════════════════════════════════════════════════════
  # Sandbox
  # ═══════════════════════════════════════════════════════════════════════════
  
  enable_sandbox_exemptions   = true
  sandbox_management_group_id = module.management_groups.sandbox_mg_id
  sandbox_exempted_policy_assignments = [
    module.policy_assignments.mg_assignment_ids["root-security-baseline"]
  ]

  # ═══════════════════════════════════════════════════════════════════════════
  # Manual Exemptions
  # ═══════════════════════════════════════════════════════════════════════════
  
  management_group_exemptions = {
    "platform-ddos-cloudflare" = {
      management_group_id              = module.management_groups.root_mg_id
      policy_assignment_id             = module.policy_assignments.mg_assignment_ids["root-security-baseline"]
      exemption_category               = "Mitigated"
      display_name                     = "DDoS Standard - Cloudflare Protected"
      description                      = "All internet-facing apps protected by Cloudflare. Alternative: Cloudflare DDoS + WAF."
      policy_definition_reference_ids  = ["DdosStandardDisabled"]
    }
  }

  subscription_exemptions = {
    "shared-services-cdn" = {
      subscription_id                  = "/subscriptions/xxx"
      policy_assignment_id             = module.policy_assignments.mg_assignment_ids["root-security-baseline"]
      exemption_category               = "Mitigated"
      display_name                     = "CDN Public Access"
      description                      = "CDN requires public access. Alternative: WAF + IP restrictions."
      expires_on                       = "2026-06-30T23:59:59Z"
      policy_definition_reference_ids  = ["DenyStoragePublicAccess"]
    }
  }

  resource_exemptions = {
    "public-dataset-storage" = {
      resource_id                      = "/subscriptions/xxx/resourceGroups/rg-data/providers/Microsoft.Storage/storageAccounts/stpublicdataset"
      policy_assignment_id             = module.policy_assignments.mg_assignment_ids["root-security-baseline"]
      exemption_category               = "Mitigated"
      display_name                     = "Open Data Storage"
      description                      = "Public dataset for open data initiative. Read-only, SAS tokens, audit logging."
      expires_on                       = "2025-12-31T23:59:59Z"
      policy_definition_reference_ids  = ["DenyStoragePublicAccess"]
    }
  }

  # ═══════════════════════════════════════════════════════════════════════════
  # Validation Settings
  # ═══════════════════════════════════════════════════════════════════════════
  
  require_expiration_for_waivers = true
  max_waiver_duration_days       = 365

  tags = module.tags.all_tags

  depends_on = [module.policy_assignments]
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| `management_group_exemptions` | Map of exemptions at MG scope | `map(object)` | No | `{}` |
| `subscription_exemptions` | Map of exemptions at subscription scope | `map(object)` | No | `{}` |
| `resource_group_exemptions` | Map of exemptions at RG scope | `map(object)` | No | `{}` |
| `resource_exemptions` | Map of exemptions at resource scope | `map(object)` | No | `{}` |
| `enable_brownfield_exemptions` | Enable brownfield migration exemptions | `bool` | No | `false` |
| `brownfield_migration_end_date` | End date for brownfield exemptions (RFC3339) | `string` | No | `null` |
| `brownfield_subscriptions` | Subscriptions for brownfield exemptions | `map(object)` | No | `{}` |
| `brownfield_resource_groups` | Resource groups for brownfield exemptions | `map(object)` | No | `{}` |
| `enable_sandbox_exemptions` | Enable Sandbox relaxed exemptions | `bool` | No | `false` |
| `sandbox_management_group_id` | Sandbox MG ID | `string` | No | `""` |
| `sandbox_exempted_policy_assignments` | Policy assignments to exempt in Sandbox | `list(string)` | No | `[]` |
| `default_exemption_category` | Default category (Waiver/Mitigated) | `string` | No | `"Waiver"` |
| `require_expiration_for_waivers` | Require expiration for Waivers | `bool` | No | `true` |
| `max_waiver_duration_days` | Max waiver duration (0 = unlimited) | `number` | No | `365` |
| `tags` | Tags for resources | `map(string)` | No | `{}` |

### Exemption Object Structure

```hcl
{
  management_group_id             = string           # Scope (MG/Sub/RG/Resource ID)
  policy_assignment_id            = string           # Assignment to exempt from
  exemption_category              = string           # "Waiver" or "Mitigated"
  display_name                    = string           # Human-readable name
  description                     = optional(string) # Justification
  expires_on                      = optional(string) # RFC3339 expiration date
  policy_definition_reference_ids = optional(list)   # Specific policies in initiative
  metadata                        = optional(string) # Additional metadata JSON
}
```

## Outputs

| Name | Description |
|------|-------------|
| `mg_exemption_ids` | Map of MG exemption names to IDs |
| `mg_exemptions` | Full MG exemption attributes |
| `sub_exemption_ids` | Map of subscription exemption names to IDs |
| `sub_exemptions` | Full subscription exemption attributes |
| `rg_exemption_ids` | Map of RG exemption names to IDs |
| `rg_exemptions` | Full RG exemption attributes |
| `resource_exemption_ids` | Map of resource exemption names to IDs |
| `resource_exemptions` | Full resource exemption attributes |
| `all_exemption_ids` | All exemptions combined |
| `brownfield_exemption_ids` | Brownfield migration exemption IDs |
| `brownfield_migration_end_date` | End date for brownfield exemptions |
| `sandbox_exemption_ids` | Sandbox exemption IDs |
| `exemptions_by_category` | Exemptions organized by Waiver/Mitigated |
| `exemptions_with_expiration` | Exemptions with expiration dates |
| `waivers_without_expiration` | Compliance warning - Waivers without expiration |
| `summary` | Deployment summary |
| `audit_report` | Full audit report for compliance review |

## Exemption Categories

| Category | Use Case | Expiration | Example |
|----------|----------|------------|---------|
| **Waiver** | Temporary exception | Required (recommended) | Brownfield migration |
| **Mitigated** | Alternative compliance | Optional | Cloudflare replacing DDoS Standard |

## Best Practices

### 1. Always Document Exemptions

```hcl
description = <<-EOT
  Reason: Legacy ERP system requires public endpoint access
  Alternative Controls: WAF enabled, IP restrictions, audit logging
  Remediation Plan: Migration to private endpoints scheduled Q3 2025
  Owner: erp-team@company.com
  Ticket: JIRA-12345
EOT
```

### 2. Set Expiration for Waivers

```hcl
exemption_category = "Waiver"
expires_on         = "2025-12-31T23:59:59Z"  # Always set for Waivers
```

### 3. Use Mitigated for Permanent Alternatives

```hcl
exemption_category = "Mitigated"
description        = "Cloudflare provides equivalent DDoS protection. No expiration needed."
```

### 4. Exempt Specific Policies in Initiatives

```hcl
# Instead of exempting entire initiative, exempt specific policies
policy_definition_reference_ids = ["DenyStoragePublicAccess", "RequireHttps"]
```

### 5. Regular Audit

```bash
# Review exemptions approaching expiration
terraform output exemptions_with_expiration

# Check for Waivers without expiration (compliance warning)
terraform output waivers_without_expiration

# Full audit report
terraform output audit_report
```

## Brownfield Migration Strategy

1. **Initial Assessment**: Identify non-compliant resources
2. **Create Exemptions**: Use `enable_brownfield_exemptions = true`
3. **Set End Date**: All brownfield exemptions expire on `brownfield_migration_end_date`
4. **Track Progress**: Use Azure Policy Compliance dashboard
5. **Remediate**: Fix resources before exemption expires
6. **Remove Exemptions**: Clean up as resources become compliant

## Compliance Reporting

The `audit_report` output provides:

```hcl
audit_report = {
  management_groups = {
    "exemption-name" = {
      display_name       = "..."
      description        = "..."
      category           = "Waiver"
      expires_on         = "2025-12-31T23:59:59Z"
      policy_assignment  = "..."
      requires_attention = false  # true if Waiver without expiration
    }
  }
  subscriptions     = { ... }
  resource_groups   = { ... }
  resources         = { ... }
}
```

## Notes

### Exemption Name Limit
Azure Policy exemption names are limited to 64 characters. The module automatically truncates names.

### Initiative Policy References
When exempting from an initiative, use `policy_definition_reference_ids` to exempt specific policies rather than the entire initiative.

### Inheritance
Exemptions at a scope apply to all child resources. An exemption at Management Group level applies to all subscriptions underneath.

## License

Proprietary - Internal use only
