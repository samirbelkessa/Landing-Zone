# Azure Subscription Vending Module (L01)

## Description

This module implements a **Subscription Vending Machine** pattern for Azure Landing Zones. It creates Azure Subscriptions and automatically places them into the correct Management Groups based on their archetype (Corp-Prod, Online-NonProd, Sandbox, etc.).

## Features

- ✅ Creates new Azure Subscriptions (EA, MCA, CSP)
- ✅ Automatic placement into Management Groups based on archetype
- ✅ Places existing subscriptions (brownfield migration)
- ✅ Creates consumption budgets with alerts
- ✅ Applies default RBAC assignments
- ✅ Tags subscriptions with archetype and environment
- ✅ Handles Azure propagation delays

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    L01 - SUBSCRIPTION VENDING                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  INPUTS                           OUTPUTS                                   │
│  ══════                           ═══════                                   │
│  • subscriptions config           • subscription_ids                        │
│  • billing_scope (EA/MCA)         • subscriptions (full details)            │
│  • management_group_ids ◄─────────• subscriptions_by_archetype              │
│    (from F01 tfstate)             • management_group_associations           │
│                                                                             │
│  PROCESS                                                                    │
│  ═══════                                                                    │
│  1. Create Subscription                                                     │
│  2. Wait for propagation (60s)                                              │
│  3. Place in Management Group                                               │
│  4. Apply RBAC & Budget                                                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ Places subscriptions
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    MANAGEMENT GROUP HIERARCHY (F01)                          │
├─────────────────────────────────────────────────────────────────────────────┤
│  Root (intelly)                                                             │
│  ├── Platform                                                               │
│  │   ├── Management     ◄── archetype: "management"                         │
│  │   ├── Connectivity   ◄── archetype: "connectivity"                       │
│  │   └── Identity       ◄── archetype: "identity"                           │
│  ├── Landing Zones                                                          │
│  │   ├── Corp-Prod      ◄── archetype: "corp_prod"                          │
│  │   ├── Corp-NonProd   ◄── archetype: "corp_nonprod"                       │
│  │   ├── Online-Prod    ◄── archetype: "online_prod"                        │
│  │   ├── Online-NonProd ◄── archetype: "online_nonprod"                     │
│  │   └── Sandbox        ◄── archetype: "sandbox"                            │
│  └── Decommissioned     ◄── archetype: "decommissioned"                     │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Prerequisites

- **Terraform**: >= 1.5.0
- **AzureRM Provider**: >= 3.80.0
- **Azure Permissions**:
  - For EA: Enrollment Account Owner or similar
  - For MCA: Invoice Section Owner or similar
- **F01 Module**: Management Groups must be deployed first

## Dependencies

| Module | Purpose |
|--------|---------|
| **F01** | Provides `management_group_ids` for subscription placement |

## Usage

### Basic Example - Create Subscriptions

```hcl
module "subscription_vending" {
  source = "./modules/Landing-Zone/L01-subscription-vending"

  # Billing configuration (EA example)
  billing_account_name = "1234567"
  billing_scope        = "/providers/Microsoft.Billing/billingAccounts/1234567/enrollmentAccounts/123456"

  # Management Group IDs from F01
  management_group_ids = module.management_groups.all_mg_ids
  # Or from remote state:
  # management_group_ids = data.terraform_remote_state.foundation.outputs.all_mg_ids

  subscriptions = {
    "app1-prod" = {
      display_name  = "App1 Production"
      archetype     = "corp_prod"
      workload_type = "Production"
    }
    "app1-dev" = {
      display_name  = "App1 Development"
      archetype     = "corp_nonprod"
      workload_type = "DevTest"
    }
  }
}
```

### Advanced Example - With Budgets and RBAC

```hcl
module "subscription_vending" {
  source = "./modules/Landing-Zone/L01-subscription-vending"

  billing_account_name = "1234567"
  billing_scope        = "/providers/Microsoft.Billing/billingAccounts/1234567/enrollmentAccounts/123456"

  management_group_ids = data.terraform_remote_state.foundation.outputs.all_mg_ids

  subscriptions = {
    # Platform Subscriptions
    "connectivity" = {
      display_name  = "Platform - Connectivity"
      archetype     = "connectivity"
      workload_type = "Production"
      budget = {
        amount = 10000
        notifications = {
          "forecast-80" = {
            threshold      = 80
            contact_emails = ["platform-team@company.com"]
          }
          "actual-100" = {
            threshold      = 100
            contact_emails = ["platform-team@company.com", "finance@company.com"]
          }
        }
      }
    }
    "management" = {
      display_name  = "Platform - Management"
      archetype     = "management"
      workload_type = "Production"
      budget = {
        amount = 5000
        notifications = {
          "actual-90" = {
            threshold      = 90
            contact_emails = ["platform-team@company.com"]
          }
        }
      }
    }

    # Landing Zone Subscriptions
    "erp-prod" = {
      display_name  = "ERP Production"
      archetype     = "corp_prod"
      workload_type = "Production"
      tags = {
        Application = "ERP"
        BusinessUnit = "Finance"
      }
      budget = {
        amount = 25000
        notifications = {
          "forecast-80" = { threshold = 80, contact_emails = ["erp-team@company.com"] }
          "actual-100"  = { threshold = 100, contact_emails = ["erp-team@company.com", "finance@company.com"] }
        }
      }
    }
    "erp-dev" = {
      display_name  = "ERP Development"
      archetype     = "corp_nonprod"
      workload_type = "DevTest"
      tags = {
        Application = "ERP"
        BusinessUnit = "Finance"
      }
      budget = {
        amount = 5000
        notifications = {
          "actual-100" = { threshold = 100, contact_emails = ["erp-team@company.com"] }
        }
      }
    }

    # Internet-facing workloads
    "web-prod" = {
      display_name  = "Web Platform Production"
      archetype     = "online_prod"
      workload_type = "Production"
      tags = {
        Application = "WebPlatform"
      }
    }

    # Sandbox for POC
    "sandbox-innovation" = {
      display_name  = "Innovation Sandbox"
      archetype     = "sandbox"
      workload_type = "DevTest"
      tags = {
        Purpose    = "Innovation"
        Expiration = "2025-12-31"
      }
      budget = {
        amount = 1000
        notifications = {
          "actual-80" = { threshold = 80, contact_emails = ["innovation@company.com"] }
        }
      }
    }
  }

  # Default RBAC for all subscriptions
  default_role_assignments = {
    "platform-readers" = {
      role_definition_name = "Reader"
      principal_id         = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"  # Platform Team Group
      principal_type       = "Group"
    }
    "security-readers" = {
      role_definition_name = "Security Reader"
      principal_id         = "ffffffff-gggg-hhhh-iiii-jjjjjjjjjjjj"  # Security Team Group
      principal_type       = "Group"
    }
  }

  default_tags = {
    ManagedBy   = "Terraform"
    CostCenter  = "IT-Platform"
    Environment = "Platform"
  }
}
```

### Brownfield Example - Place Existing Subscriptions

```hcl
module "subscription_vending" {
  source = "./modules/Landing-Zone/L01-subscription-vending"

  billing_account_name = "1234567"
  billing_scope        = "/providers/Microsoft.Billing/billingAccounts/1234567/enrollmentAccounts/123456"

  management_group_ids = data.terraform_remote_state.foundation.outputs.all_mg_ids

  # Don't create new subscriptions
  subscriptions = {}

  # Place existing subscriptions into correct MGs
  existing_subscriptions = {
    "legacy-app1" = {
      subscription_id = "11111111-2222-3333-4444-555555555555"
      archetype       = "corp_prod"
    }
    "legacy-app2" = {
      subscription_id = "66666666-7777-8888-9999-aaaaaaaaaaaa"
      archetype       = "corp_nonprod"
    }
    "old-sandbox" = {
      subscription_id = "bbbbbbbb-cccc-dddd-eeee-ffffffffffff"
      archetype       = "sandbox"
    }
  }
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| `subscriptions` | Map of subscriptions to create | `map(object)` | Yes | - |
| `billing_account_name` | Billing account name (EA/MCA) | `string` | Yes | - |
| `billing_scope` | Full billing scope ID | `string` | Yes | - |
| `management_group_ids` | MG IDs from F01 | `map(string)` | Yes | - |
| `subscription_alias_prefix` | Prefix for subscription aliases | `string` | No | `"sub"` |
| `default_tags` | Default tags for all subscriptions | `map(string)` | No | `{}` |
| `enable_subscription_placement` | Enable MG placement | `bool` | No | `true` |
| `wait_for_subscription_creation` | Wait time for propagation | `string` | No | `"60s"` |
| `default_role_assignments` | Default RBAC for all subs | `map(object)` | No | `{}` |
| `existing_subscriptions` | Existing subs to place | `map(object)` | No | `{}` |

### Subscription Object

```hcl
{
  display_name    = string              # Required: Display name
  archetype       = string              # Required: corp_prod, sandbox, etc.
  workload_type   = string              # Optional: "Production" or "DevTest"
  owner_object_id = string              # Optional: Initial owner
  tags            = map(string)         # Optional: Additional tags
  budget          = object              # Optional: Budget config
}
```

### Valid Archetypes

| Archetype | Management Group | Description |
|-----------|------------------|-------------|
| `root` | Root | Organization root |
| `platform` | Platform | Platform services |
| `management` | Management | Log Analytics, Automation |
| `connectivity` | Connectivity | Hub VNet, Firewall |
| `identity` | Identity | Domain Controllers |
| `landing_zones` | Landing Zones | Parent for all LZs |
| `corp_prod` | Corp-Prod | Internal production |
| `corp_nonprod` | Corp-NonProd | Internal dev/test |
| `online_prod` | Online-Prod | Internet-facing prod |
| `online_nonprod` | Online-NonProd | Internet-facing dev/test |
| `sandbox` | Sandbox | POC and experimentation |
| `decommissioned` | Decommissioned | Pending deletion |

## Outputs

| Name | Description |
|------|-------------|
| `subscription_ids` | Map of keys to subscription IDs |
| `subscription_names` | Map of keys to display names |
| `subscriptions` | Full subscription details |
| `subscriptions_by_archetype` | Subscription IDs grouped by archetype |
| `corp_prod_subscription_ids` | Corp-Prod subscription IDs |
| `sandbox_subscription_ids` | Sandbox subscription IDs |
| `management_group_associations` | MG placement details |
| `budget_ids` | Budget resource IDs |
| `summary` | Operation summary |

## Billing Scope Examples

### Enterprise Agreement (EA)

```hcl
billing_scope = "/providers/Microsoft.Billing/billingAccounts/{billingAccountId}/enrollmentAccounts/{enrollmentAccountId}"
```

### Microsoft Customer Agreement (MCA)

```hcl
billing_scope = "/providers/Microsoft.Billing/billingAccounts/{billingAccountId}/billingProfiles/{billingProfileId}/invoiceSections/{invoiceSectionId}"
```

## Notes

### Subscription Creation Permissions

To create subscriptions, you need one of:
- **EA**: Enrollment Account Owner
- **MCA**: Invoice Section Owner or Invoice Section Contributor
- **CSP**: Admin Agent or Sales Agent

### Propagation Delays

Azure requires time to propagate subscriptions across services. The module includes a configurable wait time (default 60s) to handle this.

### Brownfield Migration Strategy

1. First deployment: Use `existing_subscriptions` to place current subs
2. Later: Create new subs via `subscriptions` map
3. Remove from `existing_subscriptions` once migrated

## Related Modules

- **F01** - management-groups: Provides MG IDs (required)
- **L02** - spoke-virtual-network: Creates spoke VNets in subscriptions
- **L03** - landing-zone-baseline: Applies baseline configuration
- **L04** - budget-alert: Additional budget management
