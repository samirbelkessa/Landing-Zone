# Module G03: Policy Assignments

## Description

Ce module crée les **Azure Policy Assignments** pour le projet Landing Zone Azure CAF. Il permet d'assigner des policy definitions et policy set definitions (initiatives) à différents scopes : Management Groups, Subscriptions, et Resource Groups.

Le module gère automatiquement :
- Les managed identities pour les policies DeployIfNotExists et Modify
- Les role assignments nécessaires pour la remediation
- Les assignments CAF préconfigurés pour le projet Australie

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     Root Management Group                                    │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │ Assignments:                                                            ││
│  │  • CAF Governance Baseline (Deny/Modify)                               ││
│  │  • CAF Security Baseline (Audit/Deny)                                  ││
│  │  • Azure Security Benchmark (Audit)                                    ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│              │                                                               │
│    ┌─────────┴─────────┬─────────────────┐                                  │
│    ▼                   ▼                 ▼                                  │
│  Platform          Landing Zones    Decommissioned                          │
│  ┌───────────┐     ┌─────────────┐   ┌────────────┐                        │
│  │Network    │     │Backup       │   │Deny All    │                        │
│  │Identity   │     │Cost         │   │            │                        │
│  │Monitoring │     │VM Insights  │   │            │                        │
│  └───────────┘     └─────────────┘   └────────────┘                        │
│                           │                                                 │
│         ┌─────────────────┼─────────────────┐                              │
│         ▼                 ▼                 ▼                              │
│    Online-Prod       Corp-Prod         Sandbox                             │
│    ┌──────────┐     ┌──────────┐     ┌──────────┐                         │
│    │WAF/HTTPS │     │Private EP│     │SKU Limits│                         │
│    │GRS Backup│     │No Public │     │Expiration│                         │
│    └──────────┘     └──────────┘     └──────────┘                         │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Prérequis

- **Module F01** (management-groups) : Hiérarchie MG déployée
- **Module G01** (policy-definitions) : Policies custom créées
- **Module G02** (policy-set-definitions) : Initiatives créées
- **Permissions** : `Resource Policy Contributor` + `User Access Administrator` (pour role assignments)

## Dépendances

```
F01 management-groups
 └── G01 policy-definitions
      └── G02 policy-set-definitions
           └── G03 policy-assignments (ce module)
                └── G04 policy-exemptions
```

## Usage

### Basic Usage - Manual Assignments

```hcl
module "policy_assignments" {
  source = "./modules/policy-assignments"

  management_group_assignments = {
    "root-allowed-locations" = {
      management_group_id       = "/providers/Microsoft.Management/managementGroups/contoso-root"
      policy_definition_id      = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
      display_name              = "Allowed Locations - Australia"
      description               = "Restricts resource deployment to Australia regions."
      enforce                   = true
      parameters                = jsonencode({
        listOfAllowedLocations = { value = ["australiaeast", "australiasoutheast"] }
      })
      identity_type             = "None"
    }
  }

  tags = {
    Environment = "Production"
    Owner       = "Platform Team"
  }
}
```

### CAF Landing Zone Deployment

```hcl
module "policy_assignments" {
  source = "./modules/policy-assignments"

  # Enable CAF automatic assignments
  deploy_caf_assignments = true

  # Management Group IDs from F01
  caf_management_groups = {
    root           = module.management_groups.root_mg_id
    platform       = module.management_groups.platform_mg_id
    connectivity   = module.management_groups.connectivity_mg_id
    identity       = module.management_groups.identity_mg_id
    management     = module.management_groups.management_mg_id
    landing_zones  = module.management_groups.landing_zones_mg_id
    online_prod    = module.management_groups.online_prod_mg_id
    online_nonprod = module.management_groups.online_nonprod_mg_id
    corp_prod      = module.management_groups.corp_prod_mg_id
    corp_nonprod   = module.management_groups.corp_nonprod_mg_id
    sandbox        = module.management_groups.sandbox_mg_id
    decommissioned = module.management_groups.decommissioned_mg_id
  }

  # Initiative IDs from G02
  caf_initiative_ids = module.policy_set_definitions.all_initiative_ids

  # Built-in initiative IDs from G02
  caf_builtin_initiative_ids = module.policy_set_definitions.builtin_initiatives_for_assignment

  # Parameters
  default_location           = "australiaeast"
  log_analytics_workspace_id = module.log_analytics.workspace_id
  allowed_regions            = ["australiaeast", "australiasoutheast"]
  required_tags              = ["Environment", "Owner", "CostCenter", "Application"]

  # Role assignments for remediation
  create_role_assignments = true

  tags = {
    Environment = "Production"
    Owner       = "Platform Team"
    CostCenter  = "IT-PLATFORM-001"
    Application = "Azure Landing Zone"
  }
}
```

### Mixed CAF and Custom Assignments

```hcl
module "policy_assignments" {
  source = "./modules/policy-assignments"

  # Enable CAF assignments
  deploy_caf_assignments = true
  caf_management_groups  = { ... }
  caf_initiative_ids     = module.policy_set_definitions.all_initiative_ids

  # Add custom assignments alongside CAF
  management_group_assignments = {
    "custom-sql-encryption" = {
      management_group_id      = "/providers/Microsoft.Management/managementGroups/contoso-corp-prod"
      policy_definition_id     = "/providers/Microsoft.Authorization/policyDefinitions/..."
      display_name             = "Require SQL TDE"
      enforce                  = true
      identity_type            = "SystemAssigned"
      location                 = "australiaeast"
    }
  }

  # Subscription-level assignments
  subscription_assignments = {
    "sub-connectivity-defender" = {
      subscription_id          = "/subscriptions/00000000-0000-0000-0000-000000000001"
      policy_set_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/..."
      display_name             = "Enable Defender for Cloud"
      enforce                  = true
      identity_type            = "SystemAssigned"
      location                 = "australiaeast"
    }
  }
}
```

### Assignment with Non-Compliance Message

```hcl
module "policy_assignments" {
  source = "./modules/policy-assignments"

  management_group_assignments = {
    "corp-deny-public-storage" = {
      management_group_id       = "/providers/Microsoft.Management/managementGroups/contoso-corp"
      policy_definition_id      = module.policy_definitions.policy_definition_ids["deny-storage-public-access"]
      display_name              = "Deny Public Storage Access"
      enforce                   = true
      identity_type             = "None"
      non_compliance_message    = <<-EOT
        Storage accounts must not allow public blob access.
        
        Resolution:
        1. Set 'allowBlobPublicAccess' to false
        2. Use Private Endpoints for access
        3. Contact Platform Team if public access is required (exemption needed)
        
        Reference: https://wiki.company.com/storage-security
      EOT
    }
  }
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| `management_group_assignments` | Map of policy assignments at MG scope | `map(object)` | No | `{}` |
| `subscription_assignments` | Map of policy assignments at subscription scope | `map(object)` | No | `{}` |
| `resource_group_assignments` | Map of policy assignments at RG scope | `map(object)` | No | `{}` |
| `deploy_caf_assignments` | Deploy CAF automatic assignments | `bool` | No | `false` |
| `caf_management_groups` | Map of CAF MG IDs | `map(string)` | No* | `{}` |
| `caf_initiative_ids` | Map of CAF initiative IDs from G02 | `map(string)` | No* | `{}` |
| `caf_builtin_initiative_ids` | Map of built-in initiative IDs | `map(string)` | No | `{}` |
| `create_role_assignments` | Create role assignments for managed identities | `bool` | No | `true` |
| `role_definition_ids` | Map of role IDs per assignment | `map(list(string))` | No | `{}` |
| `default_role_definition_id` | Default role for identities | `string` | No | Contributor |
| `default_location` | Default location for identities | `string` | No | `australiaeast` |
| `log_analytics_workspace_id` | LA workspace ID for monitoring | `string` | No | `""` |
| `allowed_regions` | Allowed Azure regions | `list(string)` | No | `["australiaeast", "australiasoutheast"]` |
| `required_tags` | Required tag names | `list(string)` | No | `["Environment", "Owner", "CostCenter", "Application"]` |
| `tags` | Tags for resources | `map(string)` | No | `{}` |

\* Required when `deploy_caf_assignments = true`

### Assignment Object Structure

```hcl
{
  management_group_id       = string           # Full MG resource ID
  policy_definition_id      = optional(string) # Policy definition ID (exclusive with set)
  policy_set_definition_id  = optional(string) # Initiative ID (exclusive with definition)
  display_name              = string           # Human-readable name
  description               = optional(string) # Description
  enforce                   = optional(bool)   # true = enforce, false = audit only
  parameters                = optional(string) # JSON-encoded parameters
  non_compliance_message    = optional(string) # Message for non-compliant resources
  identity_type             = optional(string) # None, SystemAssigned, UserAssigned
  identity_ids              = optional(list)   # User Assigned MI IDs
  location                  = optional(string) # Location for MI
  not_scopes                = optional(list)   # Excluded scopes
  metadata                  = optional(string) # Additional metadata
}
```

## Outputs

| Name | Description |
|------|-------------|
| `mg_assignment_ids` | Map of MG assignment names to IDs |
| `mg_assignments` | Full MG assignment attributes |
| `mg_assignment_identities` | Map of MG assignments to principal IDs |
| `sub_assignment_ids` | Map of subscription assignment names to IDs |
| `sub_assignments` | Full subscription assignment attributes |
| `rg_assignment_ids` | Map of RG assignment names to IDs |
| `rg_assignments` | Full RG assignment attributes |
| `role_assignment_ids` | Map of role assignment IDs |
| `all_assignment_ids` | All assignments combined |
| `all_assignment_principal_ids` | All assignments with identities |
| `caf_assignment_ids` | CAF automatic assignment IDs |
| `caf_assignments_by_scope` | CAF assignments organized by scope |
| `summary` | Deployment summary |
| `remediation_commands` | Azure CLI remediation commands |

## CAF Automatic Assignment Mapping

| Assignment | Scope | Initiative | Effect |
|------------|-------|------------|--------|
| root-governance-baseline | Root | caf-governance-baseline | Deny/Modify |
| root-security-baseline | Root | caf-security-baseline | Audit/Deny |
| root-azure-security-benchmark | Root | Azure Security Benchmark | Audit |
| connectivity-network-baseline | Connectivity | caf-network-baseline | Audit |
| identity-baseline | Identity | caf-identity-baseline | Audit |
| management-monitoring-baseline | Management | caf-monitoring-baseline | DINE |
| platform-vm-insights | Platform | VM Insights | DINE |
| lz-backup-baseline | Landing Zones | caf-backup-baseline | Audit |
| lz-cost-baseline | Landing Zones | caf-cost-baseline | Audit |
| lz-vm-insights | Landing Zones | VM Insights | DINE |
| online-prod-initiative | Online-Prod | caf-online-prod | Deny/Audit |
| online-nonprod-initiative | Online-NonProd | caf-online-nonprod | Audit |
| corp-prod-initiative | Corp-Prod | caf-corp-prod | Deny |
| corp-nonprod-initiative | Corp-NonProd | caf-corp-nonprod | Deny/Audit |
| sandbox-initiative | Sandbox | caf-sandbox | Audit/Deny |
| decommissioned-initiative | Decommissioned | caf-decommissioned | Deny |

## Managed Identity Requirements

Policies with the following effects require a managed identity:
- **DeployIfNotExists (DINE)**: Deploys resources when non-compliant
- **Modify**: Modifies existing resources

The module automatically:
1. Creates a SystemAssigned identity when specified
2. Creates role assignments for the identity at the assignment scope
3. Grants Contributor role by default (configurable)

## Remediation

After deployment, DeployIfNotExists policies require remediation to apply to existing resources:

```bash
# View remediation commands
terraform output remediation_commands

# Run remediation (example)
az policy remediation create \
  --name "remediate-management-monitoring-baseline" \
  --policy-assignment "/providers/Microsoft.Management/managementGroups/contoso-management/providers/Microsoft.Authorization/policyAssignments/management-monitori" \
  --management-group "contoso-management"
```

## Brownfield Migration

For existing environments with ~70 policies:

1. **Audit First**: Set `enforce = false` on all new assignments
2. **Review Compliance**: Check Azure Policy Compliance dashboard
3. **Create Exemptions**: Use G04 module for legacy resources
4. **Gradual Enforcement**: Enable enforcement progressively

```hcl
# Start in audit mode
management_group_assignments = {
  "corp-deny-public-storage" = {
    ...
    enforce = false  # Audit only during migration
  }
}
```

## Validation

```bash
# Format
terraform fmt -recursive

# Validate
terraform validate

# Plan
terraform plan -var-file="terraform.tfvars"

# Apply
terraform apply -var-file="terraform.tfvars"

# Check assignments
az policy assignment list --scope "/providers/Microsoft.Management/managementGroups/contoso-root" --output table
```

## Notes

### Assignment Name Limit
Azure Policy assignment names are limited to 24 characters. The module automatically truncates names.

### Identity Location
Managed identities require a location. When `identity_type` is not "None", a location must be provided.

### Not Scopes
Use `not_scopes` to exclude specific subscriptions or resource groups from an assignment.

### Compliance State
Policy compliance state is not available immediately after assignment. Allow up to 24 hours for initial evaluation.

## License

Proprietary - Internal use only
