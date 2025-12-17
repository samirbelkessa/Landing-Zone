# G03 - Policy Assignments

## Description

This module assigns Azure Policies and Policy Initiatives (Policy Sets) to Management Groups following the Cloud Adoption Framework (CAF) Landing Zone architecture. It implements a hierarchical policy assignment strategy where policies flow down from the root management group to child scopes.

### Key Features

- **Hierarchical Assignments**: Assigns policies at appropriate levels (Root, Platform, Landing Zones, Archetypes)
- **CAF Alignment**: Implements CAF baseline policy assignments and archetype-specific policies
- **Built-in Initiative Support**: Assigns Azure Security Benchmark, VM Insights, NIST, and ISO 27001 initiatives
- **Managed Identity for Remediation**: Creates and configures identities for DeployIfNotExists and Modify effects
- **Enforcement Mode Control**: Supports audit-only mode for brownfield migration
- **Non-Compliance Messages**: Provides clear messages for policy violations
- **Custom Assignments**: Allows additional custom policy assignments beyond CAF defaults

## Prerequisites

### Required Modules

- **F01 - management-groups**: Management Group hierarchy must exist
- **G01 - policy-definitions**: Custom policy definitions must be created
- **G02 - policy-set-definitions**: Policy initiatives must be created

### Required Permissions

- `Microsoft.Authorization/policyAssignments/*` on target Management Groups
- `Microsoft.ManagedIdentity/userAssignedIdentities/*` (if creating remediation identity)
- `Microsoft.Authorization/roleAssignments/*` for remediation role assignments

## Usage

### Basic Example

```hcl
module "policy_assignments" {
  source = "./modules/policy-assignments"

  # Required: Management Group hierarchy from F01
  management_group_hierarchy = {
    root           = module.management_groups.root_mg_id
    platform       = module.management_groups.platform_mg_id
    management     = module.management_groups.management_mg_id
    connectivity   = module.management_groups.connectivity_mg_id
    identity       = module.management_groups.identity_mg_id
    landing_zones  = module.management_groups.landing_zones_mg_id
    corp_prod      = module.management_groups.corp_prod_mg_id
    corp_nonprod   = module.management_groups.corp_nonprod_mg_id
    online_prod    = module.management_groups.online_prod_mg_id
    online_nonprod = module.management_groups.online_nonprod_mg_id
    sandbox        = module.management_groups.sandbox_mg_id
    decommissioned = module.management_groups.decommissioned_mg_id
  }

  # Required: Initiative IDs from G02
  initiative_ids = module.policy_set_definitions.all_initiative_ids

  # Optional: Log Analytics workspace for monitoring policies
  log_analytics_workspace_id = module.log_analytics.workspace_id

  tags = {
    Environment = "Production"
    Owner       = "Platform Team"
    CostCenter  = "IT-001"
    Application = "Landing Zone"
  }
}
```

### Advanced Example (Australia Project)

```hcl
module "policy_assignments" {
  source = "./modules/policy-assignments"

  # Management Group hierarchy
  management_group_hierarchy = {
    root           = module.management_groups.root_mg_id
    platform       = module.management_groups.platform_mg_id
    management     = module.management_groups.management_mg_id
    connectivity   = module.management_groups.connectivity_mg_id
    identity       = module.management_groups.identity_mg_id
    landing_zones  = module.management_groups.landing_zones_mg_id
    corp_prod      = module.management_groups.corp_prod_mg_id
    corp_nonprod   = module.management_groups.corp_nonprod_mg_id
    online_prod    = module.management_groups.online_prod_mg_id
    online_nonprod = module.management_groups.online_nonprod_mg_id
    sandbox        = module.management_groups.sandbox_mg_id
    decommissioned = module.management_groups.decommissioned_mg_id
  }

  # Initiative IDs from G02
  initiative_ids = module.policy_set_definitions.all_initiative_ids

  # Assignment configuration
  deploy_root_assignments          = true
  deploy_platform_assignments      = true
  deploy_landing_zone_assignments  = true
  deploy_decommissioned_assignments = true

  # Built-in initiative assignments
  assign_azure_security_benchmark = true
  assign_vm_insights              = true
  assign_nist_sp_800_53           = false  # Optional compliance
  assign_iso_27001                = false  # Optional compliance

  # Australia-specific parameters
  allowed_locations = ["australiaeast", "australiasoutheast"]
  
  log_analytics_workspace_id = module.log_analytics.workspace_id
  log_retention_days         = 90  # 90 days interactive

  required_tags = ["Environment", "Owner", "CostCenter", "Application"]

  allowed_vm_skus_sandbox = [
    "Standard_B1s",
    "Standard_B1ms",
    "Standard_B2s",
    "Standard_B2ms",
    "Standard_D2s_v3",
    "Standard_D2s_v4",
    "Standard_D2s_v5"
  ]

  backup_geo_redundancy_regions = {
    "australiaeast" = "australiasoutheast"
  }

  # Managed identity for remediation
  create_remediation_identity         = true
  remediation_identity_name           = "policy-remediation-identity"
  remediation_identity_resource_group = "rg-management-aue-001"
  remediation_identity_location       = "australiaeast"

  # Non-compliance message prefix
  non_compliance_message_prefix = "[CAF Australia]"

  tags = {
    Environment = "Production"
    Owner       = "platform-team@contoso.com"
    CostCenter  = "IT-PLATFORM-001"
    Application = "Landing Zone"
  }
}
```

### Brownfield Migration (Audit-Only Mode)

```hcl
module "policy_assignments" {
  source = "./modules/policy-assignments"

  management_group_hierarchy = module.management_groups.all_mg_ids
  initiative_ids             = module.policy_set_definitions.all_initiative_ids

  # Enable audit-only mode for all assignments during migration
  enforcement_mode_override = "DoNotEnforce"

  # ... other configuration
}
```

### Custom Policy Assignments

```hcl
module "policy_assignments" {
  source = "./modules/policy-assignments"

  management_group_hierarchy = module.management_groups.all_mg_ids
  initiative_ids             = module.policy_set_definitions.all_initiative_ids

  # Add custom assignments beyond CAF defaults
  custom_policy_assignments = {
    "custom-network-restriction" = {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/xxx"
      management_group_id  = module.management_groups.landing_zones_mg_id
      display_name         = "Custom Network Restriction"
      description          = "Custom policy for network restrictions"
      enforcement_mode     = "Default"
      parameters = {
        allowedSubnets = ["10.0.0.0/8"]
      }
      non_compliance_message = "Resource violates custom network restrictions."
      identity_type          = "None"
    }
    
    "deploy-custom-diagnostic" = {
      policy_definition_id = module.policy_definitions.policy_definition_ids["custom-diagnostic"]
      management_group_id  = module.management_groups.platform_mg_id
      display_name         = "Deploy Custom Diagnostic Settings"
      description          = "Deploy diagnostic settings to custom destination"
      enforcement_mode     = "Default"
      parameters = {
        workspaceId = module.log_analytics.workspace_id
      }
      identity_type = "SystemAssigned"  # Required for DeployIfNotExists
    }
  }
}
```

## Policy Assignment Strategy

### Hierarchy and Inheritance

```
Root MG ─────────────────── Global policies (locations, tags, monitoring baseline)
├── Platform MG ─────────── Security benchmark, VM Insights, network baseline
│   ├── Management ──────── Log retention, Sentinel connectors
│   ├── Connectivity ────── NSG requirements, hub validation
│   └── Identity ────────── Managed identity requirements
├── Landing Zones MG ────── Key Vault policies, backup baseline, cost baseline
│   ├── Online-Prod ─────── WAF required, HTTPS enforced, TLS 1.2, GRS backup
│   ├── Online-NonProd ──── HTTPS enforced, LRS backup acceptable
│   ├── Corp-Prod ───────── Deny public IPs, private endpoints required, GRS
│   ├── Corp-NonProd ────── Deny public IPs, private endpoints recommended
│   └── Sandbox ─────────── VM SKU limits, expiration tag required, audit mode
└── Decommissioned MG ───── Deny all resource creation/modification
```

### Assignment Details by Scope

| Scope | Policies | Effect |
|-------|----------|--------|
| **Root** | Allowed locations, Required tags, AMA installed, Defender enabled | Deny/Audit |
| **Platform** | Azure Security Benchmark, VM Insights, Security baseline | Audit/Deploy |
| **Connectivity** | Subnet NSG, Hub validation, Firewall routing | Audit |
| **Landing Zones** | Key Vault (RBAC, soft delete, purge), NSG flow logs, Backup/Cost baseline | Audit/Deploy |
| **Online-Prod** | WAF required, HTTPS, TLS 1.2, GRS backup | Deny/Audit |
| **Online-NonProd** | HTTPS required, LRS backup acceptable | Deny/Audit |
| **Corp-Prod** | Deny public IPs, Private endpoints required, GRS backup | Deny |
| **Corp-NonProd** | Deny public IPs, Private endpoints recommended | Deny/Audit |
| **Sandbox** | VM SKU limits, Expiration tag, Audit-only mode | Deny/Audit |
| **Decommissioned** | Deny all creation/modification | Deny |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| management_group_hierarchy | Map of MG names to resource IDs from F01 | `map(string)` | n/a | yes |
| initiative_ids | Map of initiative names to IDs from G02 | `map(string)` | n/a | yes |
| deploy_root_assignments | Deploy assignments at root MG | `bool` | `true` | no |
| deploy_platform_assignments | Deploy assignments at Platform MG | `bool` | `true` | no |
| deploy_landing_zone_assignments | Deploy assignments at Landing Zones | `bool` | `true` | no |
| deploy_decommissioned_assignments | Deploy deny-all at Decommissioned MG | `bool` | `true` | no |
| assign_azure_security_benchmark | Assign Azure Security Benchmark | `bool` | `true` | no |
| assign_vm_insights | Assign VM Insights initiative | `bool` | `true` | no |
| assign_nist_sp_800_53 | Assign NIST SP 800-53 R5 (compliance) | `bool` | `false` | no |
| assign_iso_27001 | Assign ISO 27001:2013 (compliance) | `bool` | `false` | no |
| allowed_locations | Allowed Azure regions | `list(string)` | `["australiaeast", "australiasoutheast"]` | no |
| log_analytics_workspace_id | LA workspace ID for monitoring policies | `string` | `""` | no |
| log_retention_days | Minimum log retention (30-730) | `number` | `90` | no |
| required_tags | Required tags on resource groups | `list(string)` | `["Environment", "Owner", "CostCenter", "Application"]` | no |
| allowed_vm_skus_sandbox | Allowed VM SKUs in Sandbox | `list(string)` | B-series, D2s | no |
| backup_geo_redundancy_regions | Primary to DR region mapping | `map(string)` | `{"australiaeast" = "australiasoutheast"}` | no |
| create_remediation_identity | Create managed identity for remediation | `bool` | `true` | no |
| remediation_identity_name | Name of remediation identity | `string` | `"policy-remediation-identity"` | no |
| remediation_identity_resource_group | RG for remediation identity | `string` | `""` | no |
| remediation_identity_location | Location for remediation identity | `string` | `"australiaeast"` | no |
| custom_policy_assignments | Custom policy assignments | `map(object)` | `{}` | no |
| enforcement_mode_override | Override enforcement mode globally | `string` | `null` | no |
| non_compliance_message_prefix | Prefix for non-compliance messages | `string` | `"[CAF Landing Zone]"` | no |
| assignment_metadata | Additional metadata for assignments | `map(string)` | `{createdBy = "Terraform"}` | no |
| tags | Tags for resources created by module | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| policy_assignment_ids | Map of policy assignment names to IDs |
| initiative_assignment_ids | Map of initiative assignment names to IDs |
| custom_assignment_ids | Map of custom assignment names to IDs |
| all_assignment_ids | Map of all assignment names to IDs |
| assignments_by_scope | Assignments organized by management group |
| policy_assignments_detailed | Detailed info about policy assignments |
| initiative_assignments_detailed | Detailed info about initiative assignments |
| remediation_identity | Remediation managed identity details |
| system_assigned_identities | Map of assignments to their identity principal IDs |
| role_assignments | Role assignment IDs for remediation |
| assignments_requiring_remediation | Assignments with DeployIfNotExists/Modify effects |
| summary | Summary of all assignments |
| assignments_for_exemptions | Structured output for G04 exemptions |
| archetype_assignments_status | Status of archetype-specific assignments |

## Managed Identity for Remediation

Policies with `DeployIfNotExists` or `Modify` effects require a managed identity with appropriate permissions to remediate non-compliant resources. This module:

1. **Creates a User Assigned Managed Identity** (optional) for consistent remediation across assignments
2. **Assigns System Assigned Identities** to specific policy assignments that require remediation
3. **Grants Role Assignments** at the root management group scope:
   - Contributor (for general remediation)
   - Monitoring Contributor (for monitoring policies)
   - Log Analytics Contributor (for diagnostic settings)

### Triggering Remediation

After policy assignments are created, non-compliant resources can be remediated:

```bash
# Create a remediation task for a specific assignment
az policy remediation create \
  --name "remediate-monitoring-baseline" \
  --policy-assignment "/providers/Microsoft.Management/managementGroups/root/providers/Microsoft.Authorization/policyAssignments/root-monitoring-bas" \
  --management-group "root"
```

## Dependencies

```
F01 management-groups
 └── G01 policy-definitions
      └── G02 policy-set-definitions
           └── G03 policy-assignments (this module)
                └── G04 policy-exemptions
```

## Notes

### Brownfield Migration

For brownfield environments with existing resources:

1. Set `enforcement_mode_override = "DoNotEnforce"` initially
2. Review compliance reports in Azure Policy
3. Remediate non-compliant resources
4. Gradually enable enforcement per scope (Sandbox → NonProd → Prod)
5. Remove the override when ready

### Policy Inheritance

- Policies assigned at parent scopes automatically apply to children
- More restrictive policies at child scopes override less restrictive parent policies
- Use exemptions (G04) for legitimate exceptions

### Assignment Name Limitations

Azure Policy assignment names are limited to 24 characters. This module automatically truncates names while maintaining uniqueness.

### Compliance Reporting

Built-in initiatives (Azure Security Benchmark, NIST, ISO) are assigned in `DoNotEnforce` mode by default for compliance reporting without blocking resources.

## Related Modules

- [F01 - Management Groups](../management-groups/README.md)
- [G01 - Policy Definitions](../policy-definitions/README.md)
- [G02 - Policy Set Definitions](../policy-set-definitions/README.md)
- [G04 - Policy Exemptions](../policy-exemptions/README.md)
