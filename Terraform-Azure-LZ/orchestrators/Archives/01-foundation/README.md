# Orchestrator: LZA Governance (orchestrator-lza-gov)

## Description

This orchestrator module deploys the complete **Governance Foundation** for an Azure Landing Zone following the Cloud Adoption Framework (CAF). It manages a single Terraform state file while deploying five interconnected modules in the correct sequence:

1. **F01 - Management Groups**: Creates the CAF-aligned management group hierarchy
2. **G01 - Policy Definitions**: Deploys custom Azure Policy definitions
3. **G02 - Policy Set Definitions**: Creates policy initiatives grouping policies by domain
4. **G03 - Policy Assignments**: Assigns policies and initiatives to management groups
5. **G04 - Policy Exemptions**: Manages exemptions for brownfield migration and legitimate exceptions

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    orchestrator-lza-gov                                      │
│                    (Single State File)                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ F01 Management Groups                                                │   │
│  │ Creates: Root → Platform → Landing Zones → Decommissioned           │   │
│  └──────────────────────────────┬──────────────────────────────────────┘   │
│                                 │                                           │
│                                 ▼                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ G01 Policy Definitions                                               │   │
│  │ Creates: 20+ custom CAF policies at root MG                         │   │
│  └──────────────────────────────┬──────────────────────────────────────┘   │
│                                 │                                           │
│                                 ▼                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ G02 Policy Set Definitions (Initiatives)                             │   │
│  │ Creates: Baseline + Archetype initiatives                           │   │
│  └──────────────────────────────┬──────────────────────────────────────┘   │
│                                 │                                           │
│                                 ▼                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ G03 Policy Assignments                                               │   │
│  │ Assigns: Initiatives to appropriate MG scopes                       │   │
│  └──────────────────────────────┬──────────────────────────────────────┘   │
│                                 │                                           │
│                                 ▼                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ G04 Policy Exemptions                                                │   │
│  │ Creates: Brownfield + Sandbox + Manual exemptions                   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Prerequisites

- **Terraform**: >= 1.5.0
- **AzureRM Provider**: >= 3.80.0
- **Permissions**: 
  - Owner or User Access Administrator at tenant root level
  - Policy Contributor at management group scope
- **Azure AD Tenant ID**: Required for `root_parent_id`

## Module Structure

```
orchestrator-lza-gov/
├── versions.tf                    # Terraform and provider constraints
├── variables.tf                   # All input variables
├── locals.tf                      # Helper locals and tag merging
├── main.tf                        # Module orchestration
├── outputs.tf                     # Aggregated outputs
├── provider.tf                    # Provider configuration
├── terraform.tfvars.example       # Example configuration
├── README.md                      # This file
└── modules/
    ├── F01-management-groups/     # Management group hierarchy
    ├── G01-policy-definitions/    # Custom policy definitions
    ├── G02-policy-set-definitions/# Policy initiatives
    ├── G03-policy-assignments/    # Policy assignments
    └── G04-policy-exemptions/     # Policy exemptions
```

## Quick Start

### 1. Clone and Setup

```bash
# Clone the repository
git clone <your-repo-url>
cd orchestrator-lza-gov

# Copy example configuration
cp terraform.tfvars.example terraform.tfvars
```

### 2. Configure Variables

Edit `terraform.tfvars` with your values:

```hcl
# Required
root_parent_id = "your-tenant-id"
root_name      = "Your Organization"
root_id        = "your-org"

# Common parameters
default_location = "australiaeast"
allowed_regions  = ["australiaeast", "australiasoutheast"]

tags = {
  Environment = "Production"
  Owner       = "platform-team@company.com"
  CostCenter  = "IT-PLATFORM-001"
  Application = "Azure Landing Zone"
}
```

### 3. Initialize and Deploy

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan -out=tfplan

# Apply the configuration
terraform apply tfplan
```

## Usage Examples

### Basic Deployment

```hcl
module "lza_governance" {
  source = "./orchestrator-lza-gov"

  # Required
  root_parent_id = data.azurerm_client_config.current.tenant_id
  root_name      = "Contoso"
  root_id        = "contoso"

  # Use defaults for everything else
}

data "azurerm_client_config" "current" {}
```

### Australia Project Configuration

```hcl
module "lza_governance" {
  source = "./orchestrator-lza-gov"

  # Management Groups
  root_parent_id = data.azurerm_client_config.current.tenant_id
  root_name      = "Contoso Australia"
  root_id        = "contoso-au"

  # Full CAF structure
  deploy_platform_mg             = true
  deploy_landing_zones_mg        = true
  deploy_decommissioned_mg       = true
  deploy_sandbox_mg              = true
  deploy_corp_landing_zones      = true
  deploy_online_landing_zones    = true
  deploy_prod_nonprod_separation = true

  # All CAF policies and initiatives
  deploy_caf_policies    = true
  deploy_caf_initiatives = true
  deploy_caf_assignments = true
  deploy_exemptions      = true

  # Australia-specific settings
  default_location = "australiaeast"
  allowed_regions  = ["australiaeast", "australiasoutheast"]

  # Log Analytics (update after M01 deployment)
  log_analytics_workspace_id = "/subscriptions/xxx/resourceGroups/rg-management/providers/Microsoft.OperationalInsights/workspaces/law-central"
  log_retention_days         = 90

  # Required tags
  required_tags = ["Environment", "Owner", "CostCenter", "Application", "Criticality"]

  tags = {
    Environment = "Production"
    Owner       = "platform-team@contoso.com"
    CostCenter  = "IT-PLATFORM-001"
    Application = "Azure Landing Zone"
    Project     = "Australia CAF"
  }
}
```

### With Brownfield Migration

```hcl
module "lza_governance" {
  source = "./orchestrator-lza-gov"

  # ... base configuration ...

  # Enable brownfield exemptions
  enable_brownfield_exemptions  = true
  brownfield_migration_end_date = "2025-12-31T23:59:59Z"

  brownfield_subscriptions = {
    "legacy-erp" = {
      subscription_id       = "/subscriptions/xxx"
      policy_assignment_ids = ["corp-prod-initiative", "root-security-baseline"]
      reason                = "Legacy ERP - migration to private endpoints Q3 2025"
    }
    "legacy-crm" = {
      subscription_id       = "/subscriptions/yyy"
      policy_assignment_ids = ["corp-prod-initiative"]
      reason                = "Legacy CRM - vendor remediation in progress"
    }
  }

  brownfield_resource_groups = {
    "rg-fortinet-legacy" = {
      resource_group_id     = "/subscriptions/xxx/resourceGroups/rg-fortinet-prd"
      policy_assignment_ids = ["connectivity-network-baseline"]
      reason                = "Fortinet appliances pending decommission"
    }
  }
}
```

### Minimal Deployment (No Exemptions)

```hcl
module "lza_governance" {
  source = "./orchestrator-lza-gov"

  root_parent_id = data.azurerm_client_config.current.tenant_id
  root_name      = "SmallOrg"
  root_id        = "smallorg"

  # Simplified structure
  deploy_prod_nonprod_separation = false
  deploy_sandbox_mg              = false
  
  # Skip exemptions module
  deploy_exemptions = false
}
```

## Inputs

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `root_parent_id` | Tenant ID or parent management group ID | `string` |
| `root_name` | Display name for root management group | `string` |
| `root_id` | ID/Name for root management group | `string` |

### Management Groups (F01)

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `deploy_platform_mg` | Deploy Platform MG | `bool` | `true` |
| `deploy_landing_zones_mg` | Deploy Landing Zones MG | `bool` | `true` |
| `deploy_decommissioned_mg` | Deploy Decommissioned MG | `bool` | `true` |
| `deploy_sandbox_mg` | Deploy Sandbox MG | `bool` | `true` |
| `deploy_corp_landing_zones` | Deploy Corp archetypes | `bool` | `true` |
| `deploy_online_landing_zones` | Deploy Online archetypes | `bool` | `true` |
| `deploy_prod_nonprod_separation` | Separate Prod/NonProd MGs | `bool` | `true` |
| `custom_landing_zone_children` | Custom LZ child MGs | `map(object)` | `{}` |
| `subscription_ids_by_mg` | Subscription placement | `map(list(string))` | `{}` |

### Policy Definitions (G01)

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `deploy_caf_policies` | Deploy CAF policies | `bool` | `true` |
| `enable_network_policies` | Enable network policies | `bool` | `true` |
| `enable_security_policies` | Enable security policies | `bool` | `true` |
| `enable_monitoring_policies` | Enable monitoring policies | `bool` | `true` |
| `enable_backup_policies` | Enable backup policies | `bool` | `true` |
| `enable_cost_policies` | Enable cost policies | `bool` | `true` |
| `enable_lifecycle_policies` | Enable lifecycle policies | `bool` | `true` |
| `custom_policy_definitions` | Custom policies | `map(object)` | `{}` |

### Policy Initiatives (G02)

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `deploy_caf_initiatives` | Deploy CAF initiatives | `bool` | `true` |
| `deploy_archetype_initiatives` | Deploy archetype initiatives | `bool` | `true` |
| `archetypes_to_deploy` | Archetypes to deploy | `list(string)` | All |
| `include_azure_security_benchmark` | Include ASB | `bool` | `true` |
| `include_vm_insights` | Include VM Insights | `bool` | `true` |
| `include_nist_initiative` | Include NIST | `bool` | `false` |
| `include_iso27001_initiative` | Include ISO 27001 | `bool` | `false` |

### Policy Assignments (G03)

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `deploy_caf_assignments` | Deploy CAF assignments | `bool` | `true` |
| `create_role_assignments` | Create role assignments | `bool` | `true` |
| `management_group_assignments` | Manual MG assignments | `map(object)` | `{}` |
| `subscription_assignments` | Subscription assignments | `map(object)` | `{}` |

### Policy Exemptions (G04)

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `deploy_exemptions` | Deploy exemptions module | `bool` | `true` |
| `enable_brownfield_exemptions` | Enable brownfield | `bool` | `false` |
| `brownfield_migration_end_date` | End date (RFC3339) | `string` | `null` |
| `brownfield_subscriptions` | Brownfield subs | `map(object)` | `{}` |
| `enable_sandbox_exemptions` | Enable sandbox exemptions | `bool` | `false` |
| `require_expiration_for_waivers` | Require expiration | `bool` | `true` |

### Common Parameters

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `default_location` | Default Azure region | `string` | `australiaeast` |
| `allowed_regions` | Allowed regions | `list(string)` | `["australiaeast", "australiasoutheast"]` |
| `log_analytics_workspace_id` | LA workspace ID | `string` | `""` |
| `log_retention_days` | Log retention days | `number` | `90` |
| `required_tags` | Required tag names | `list(string)` | See defaults |
| `tags` | Resource tags | `map(string)` | `{}` |

## Outputs

### Management Groups

| Name | Description |
|------|-------------|
| `root_mg_id` | Root MG resource ID |
| `all_mg_ids` | All MG IDs map |
| `archetype_mg_ids` | Archetype MG IDs |
| `hierarchy` | Full hierarchy structure |

### Policy Definitions

| Name | Description |
|------|-------------|
| `policy_definition_ids` | Custom policy IDs |
| `builtin_policy_ids` | Built-in policy IDs |
| `policy_definitions_summary` | Deployment summary |

### Policy Initiatives

| Name | Description |
|------|-------------|
| `caf_initiative_ids` | CAF initiative IDs |
| `all_initiative_ids` | All initiative IDs |
| `archetype_initiative_ids` | Archetype initiative IDs |

### Policy Assignments

| Name | Description |
|------|-------------|
| `mg_assignment_ids` | MG assignment IDs |
| `caf_assignment_ids` | CAF assignment IDs |
| `remediation_commands` | CLI remediation commands |

### Policy Exemptions

| Name | Description |
|------|-------------|
| `all_exemption_ids` | All exemption IDs |
| `brownfield_exemption_ids` | Brownfield exemption IDs |
| `waivers_without_expiration` | Compliance warnings |
| `audit_report` | Full audit report |

### Summary

| Name | Description |
|------|-------------|
| `orchestrator_summary` | Complete deployment summary |
| `quick_reference` | Commonly needed IDs |

## Post-Deployment Steps

### 1. Trigger Remediation for DINE Policies

```bash
# Get remediation commands
terraform output remediation_commands

# Example remediation
az policy remediation create \
  --name "remediate-monitoring-baseline" \
  --policy-assignment "/providers/Microsoft.Management/managementGroups/contoso-management/providers/Microsoft.Authorization/policyAssignments/management-monitori" \
  --management-group "contoso-management"
```

### 2. Review Compliance

```bash
# Check overall compliance
az policy state summarize --management-group "contoso-au"

# List non-compliant resources
az policy state list --filter "complianceState eq 'NonCompliant'" --management-group "contoso-au"
```

### 3. Review Exemptions

```bash
# List exemptions without expiration (compliance warning)
terraform output waivers_without_expiration

# Full audit report
terraform output audit_report
```

## Integration with Other Modules

This orchestrator is typically deployed first, followed by:

1. **M01 - Log Analytics Workspace**: Create central logging
2. **M02 - Automation Account**: Link to Log Analytics
3. **S01 - Defender for Cloud**: Enable security features
4. **S02 - Microsoft Sentinel**: Enable SIEM
5. **C01 - Hub Virtual Network**: Deploy hub networking

Update `log_analytics_workspace_id` after M01 deployment:

```hcl
# After M01 deployment, update the orchestrator
log_analytics_workspace_id = module.log_analytics.workspace_id
```

## Troubleshooting

### Management Group Creation Timeout

```hcl
mg_timeouts = {
  create = "45m"
  delete = "45m"
}
```

### Policy Assignment Name Too Long

Azure Policy assignment names are limited to 24 characters. The modules automatically truncate names.

### Missing Policy Definition

Ensure G01 is fully deployed before G02:

```bash
terraform apply -target=module.policy_definitions
terraform apply
```

### Exemption Without Assignment

Policy assignments must exist before creating exemptions:

```bash
terraform apply -target=module.policy_assignments
terraform apply
```

## Changelog

### v1.0.0

- Initial release
- Full CAF governance foundation
- F01, G01, G02, G03, G04 integration
- Brownfield migration support
- Sandbox exemptions support

## License

Proprietary - Internal use only
