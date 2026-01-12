# Azure Management Groups Module (F01)

## Description

This module creates a Cloud Adoption Framework (CAF) aligned management group hierarchy for Azure Landing Zones. It implements the recommended structure with Platform, Landing Zones, and Decommissioned top-level groups, along with environment-specific archetypes (Corp-Prod, Corp-NonProd, Online-Prod, Online-NonProd, Sandbox).

## Architecture

```
Tenant Root Group
└── Organization Root (Intermediate)
    ├── Platform
    │   ├── Management        # Log Analytics, Automation, Defender, Sentinel
    │   ├── Connectivity      # Hub VNet, Firewall, Gateways, Bastion
    │   └── Identity          # Domain Controllers, Azure AD DS
    ├── Landing Zones
    │   ├── Corp-Prod         # Internal apps - Production
    │   ├── Corp-NonProd      # Internal apps - Dev/Test
    │   ├── Online-Prod       # Internet-facing - Production
    │   ├── Online-NonProd    # Internet-facing - Dev/Test
    │   └── Sandbox           # POC and experimentation
    └── Decommissioned        # Resources pending deletion
```

## Prerequisites

- Azure subscription with Owner or User Access Administrator role at tenant level
- Terraform >= 1.5.0
- AzureRM provider >= 3.80.0
- Tenant ID for the `root_parent_id` variable

## Dependencies

This module has **no dependencies** on other modules and should be deployed first.

## Usage

### Basic Example

```hcl
module "management_groups" {
  source = "./modules/management-groups"

  root_parent_id = data.azurerm_client_config.current.tenant_id
  root_name      = "Contoso"
  root_id        = "contoso"
}

data "azurerm_client_config" "current" {}
```

### Advanced Example - Australia Project

```hcl
module "management_groups" {
  source = "./modules/management-groups"

  # Required
  root_parent_id = data.azurerm_client_config.current.tenant_id
  root_name      = "ACME Australia"
  root_id        = "acme-au"

  # Structure options
  deploy_platform_mg         = true
  deploy_landing_zones_mg    = true
  deploy_decommissioned_mg   = true
  deploy_sandbox_mg          = true

  # Landing zone archetypes
  deploy_corp_landing_zones      = true
  deploy_online_landing_zones    = true
  deploy_prod_nonprod_separation = true  # Creates Corp-Prod, Corp-NonProd, etc.

  # Custom landing zone children
  custom_landing_zone_children = {
    "sap" = {
      display_name = "SAP Workloads"
    }
    "iot" = {
      display_name = "IoT Platform"
    }
  }

  # Initial subscription placement (brownfield migration)
  subscription_ids_by_mg = {
    "management"   = ["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]
    "connectivity" = ["ffffffff-gggg-hhhh-iiii-jjjjjjjjjjjj"]
    "corp_prod"    = [
      "11111111-2222-3333-4444-555555555555",
      "66666666-7777-8888-9999-000000000000"
    ]
  }

  # Timeouts for large hierarchies
  timeouts = {
    create = "45m"
    delete = "45m"
  }
}

data "azurerm_client_config" "current" {}
```

### Minimal Example - Without Prod/NonProd Separation

```hcl
module "management_groups" {
  source = "./modules/management-groups"

  root_parent_id = data.azurerm_client_config.current.tenant_id
  root_name      = "SmallOrg"
  root_id        = "smallorg"

  # Simplified structure
  deploy_prod_nonprod_separation = false  # Creates just Corp and Online
  deploy_sandbox_mg              = false
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| `root_parent_id` | Tenant Root Group ID or parent management group ID | `string` | Yes | - |
| `root_name` | Display name for the root intermediate management group | `string` | Yes | - |
| `root_id` | ID/Name for the root intermediate management group | `string` | Yes | - |
| `deploy_platform_mg` | Deploy Platform MG and children | `bool` | No | `true` |
| `deploy_landing_zones_mg` | Deploy Landing Zones MG and children | `bool` | No | `true` |
| `deploy_decommissioned_mg` | Deploy Decommissioned MG | `bool` | No | `true` |
| `deploy_sandbox_mg` | Deploy Sandbox MG under Landing Zones | `bool` | No | `true` |
| `deploy_corp_landing_zones` | Deploy Corp archetypes | `bool` | No | `true` |
| `deploy_online_landing_zones` | Deploy Online archetypes | `bool` | No | `true` |
| `deploy_prod_nonprod_separation` | Create separate Prod/NonProd MGs | `bool` | No | `true` |
| `custom_landing_zone_children` | Additional LZ child MGs | `map(object)` | No | `{}` |
| `custom_platform_children` | Additional Platform child MGs | `map(object)` | No | `{}` |
| `default_location` | Default Azure region | `string` | No | `"australiaeast"` |
| `subscription_ids_by_mg` | Subscriptions to associate | `map(list(string))` | No | `{}` |
| `timeouts` | Operation timeouts | `object` | No | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| `root_mg_id` | Resource ID of the root intermediate MG |
| `root_mg_name` | Name of the root intermediate MG |
| `platform_mg_id` | Resource ID of the Platform MG |
| `management_mg_id` | Resource ID of the Management MG |
| `connectivity_mg_id` | Resource ID of the Connectivity MG |
| `identity_mg_id` | Resource ID of the Identity MG |
| `landing_zones_mg_id` | Resource ID of the Landing Zones MG |
| `corp_prod_mg_id` | Resource ID of the Corp-Prod MG |
| `corp_nonprod_mg_id` | Resource ID of the Corp-NonProd MG |
| `online_prod_mg_id` | Resource ID of the Online-Prod MG |
| `online_nonprod_mg_id` | Resource ID of the Online-NonProd MG |
| `sandbox_mg_id` | Resource ID of the Sandbox MG |
| `decommissioned_mg_id` | Resource ID of the Decommissioned MG |
| `all_mg_ids` | Map of all MG names to resource IDs |
| `all_mg_names` | Map of all logical names to Azure names |
| `archetype_mg_ids` | Map of archetypes for policy assignment |
| `hierarchy` | Full hierarchy structure for documentation |

## Landing Zone Archetypes

| Archetype | Description | Key Policies |
|-----------|-------------|--------------|
| **Corp-Prod** | Internal production workloads | DENY public IPs, Private Endpoints mandatory, strict NSGs |
| **Corp-NonProd** | Internal dev/test workloads | DENY public IPs, Private Endpoints recommended |
| **Online-Prod** | Internet-facing production | WAF mandatory, HTTPS enforced, TLS 1.2 minimum |
| **Online-NonProd** | Internet-facing dev/test | WAF recommended, HTTPS enforced |
| **Sandbox** | POC and experimentation | Audit only, limited SKUs, Expiration tag required |

## Notes

### Management Group Naming

All management groups are prefixed with the `root_id` to ensure uniqueness:
- Platform → `{root_id}-platform`
- Landing Zones → `{root_id}-landing-zones`
- Corp-Prod → `{root_id}-corp-prod`

### Subscription Placement

The `subscription_ids_by_mg` variable uses the following keys:
- `root`, `platform`, `management`, `connectivity`, `identity`
- `landing_zones`, `corp_prod`, `corp_nonprod`, `online_prod`, `online_nonprod`
- `sandbox`, `decommissioned`
- Custom MG keys as defined in `custom_landing_zone_children` or `custom_platform_children`

### Brownfield Migration

For existing environments:
1. First run without `subscription_ids_by_mg` to create the hierarchy
2. Add subscriptions gradually using `subscription_ids_by_mg`
3. Use module F04 (subscription-placement) for ongoing management

### Policy Assignment Scopes

Use the `archetype_mg_ids` output to assign policies to landing zone archetypes:

```hcl
module "policy_assignments" {
  source = "./modules/policy-assignments"

  assignments = {
    for archetype, mg_id in module.management_groups.archetype_mg_ids :
    archetype => {
      scope     = mg_id
      policy_id = module.policy_definitions.archetype_policies[archetype]
    }
    if mg_id != null
  }
}
```

## Related Modules

- **F04** - subscription-placement: Manages subscription associations
- **G01** - policy-definitions: Custom Azure Policies
- **G02** - policy-set-definitions: Policy initiatives
- **G03** - policy-assignments: Assigns policies to MGs
