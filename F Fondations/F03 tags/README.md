# Module: tags (F03)

## Description

This module standardizes tag generation for Azure Landing Zone resources following the Cloud Adoption Framework (CAF) best practices. It ensures consistent tagging across all resources for cost management, governance, security classification, and operational purposes.

The module enforces mandatory tags and provides optional tags with validation. For Sandbox environments, it enforces expiration dates to prevent orphaned resources.

## Features

- **Mandatory Tags**: Enforces required tags (Environment, Owner, CostCenter, Application, Criticality, DataClassification)
- **Validation**: Built-in validation for email formats, date formats, and allowed values
- **Sandbox Expiration**: Automatic enforcement of expiration dates for Sandbox resources
- **Category-Specific Outputs**: Filtered tag sets for security, cost, and operational purposes
- **Environment Detection**: Automatic detection of production vs non-production environments
- **Backup Recommendations**: Provides recommended backup tiers based on criticality

## Prerequisites

- Terraform >= 1.5.0
- No Azure provider required (utility module)

## Dependencies

None - This is a foundation module with no dependencies.

## Usage

### Basic Usage

```hcl
module "tags" {
  source = "../../modules/tags"

  # Required
  environment = "Production"
  owner       = "platform-team@company.com"
  cost_center = "IT-12345"
  application = "CoreInfrastructure"
}

# Use tags in resources
resource "azurerm_resource_group" "example" {
  name     = "rg-example-prd-aue"
  location = "australiaeast"
  tags     = module.tags.all_tags
}
```

### Advanced Usage with All Options

```hcl
module "tags" {
  source = "../../modules/tags"

  # Required
  environment = "Production"
  owner       = "app-team@company.com"
  cost_center = "BU-67890"
  application = "CustomerPortal"

  # Optional - Criticality and Classification
  criticality         = "Critical"
  data_classification = "Confidential"

  # Optional - Organizational
  project    = "Digital Transformation"
  department = "Customer Experience"
  compliance = "PCI-DSS, SOC2"

  # Optional - Operational
  maintenance_window = "Sun 02:00-06:00 AEST"

  # Optional - Metadata
  created_by          = "terraform-pipeline"
  terraform_workspace = terraform.workspace
  module_name         = "customer-portal"

  # Optional - Archetype
  archetype = "Online-Prod"

  # Additional custom tags
  additional_tags = {
    CostAllocation = "direct"
    SupportTier    = "premium"
  }
}
```

### Sandbox Environment with Expiration

```hcl
module "sandbox_tags" {
  source = "../../modules/tags"

  environment     = "Sandbox"
  owner           = "developer@company.com"
  cost_center     = "RD-POC"
  application     = "AIExperiment"
  criticality     = "Low"
  expiration_date = "2025-03-31"  # Required for Sandbox
  archetype       = "Sandbox"
}
```

### Using Category-Specific Tags

```hcl
module "tags" {
  source = "../../modules/tags"
  # ... configuration ...
}

# Apply only cost-related tags to a resource
resource "azurerm_storage_account" "example" {
  # ... configuration ...
  tags = module.tags.cost_tags
}

# Apply only security tags to a Key Vault
resource "azurerm_key_vault" "example" {
  # ... configuration ...
  tags = module.tags.security_tags
}
```

### Using Derived Values for Conditional Logic

```hcl
module "tags" {
  source = "../../modules/tags"
  # ... configuration ...
}

# Configure backup based on recommended tier
module "backup" {
  source = "../../modules/recovery-services-vault"

  storage_mode_type = module.tags.recommended_backup_tier  # "GRS" or "LRS"
  
  # Use criticality for retention policies
  retention_tier = module.tags.recommended_retention_tier
}

# Conditional Defender enablement
resource "azurerm_security_center_subscription_pricing" "example" {
  count         = module.tags.is_production ? 1 : 0
  tier          = "Standard"
  resource_type = "VirtualMachines"
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| environment | Environment name (Production, PreProduction, Development, Test, Sandbox, DR) | string | Yes | - |
| owner | Email address of the resource owner | string | Yes | - |
| cost_center | Cost center code for billing | string | Yes | - |
| application | Name of the application or workload | string | Yes | - |
| criticality | Business criticality level (Critical, High, Medium, Low) | string | No | "Medium" |
| data_classification | Data classification (Public, Internal, Confidential, Restricted) | string | No | "Internal" |
| expiration_date | Expiration date for temporary resources (YYYY-MM-DD) | string | No | null |
| project | Project name or code | string | No | null |
| department | Department or business unit name | string | No | null |
| compliance | Compliance frameworks (comma-separated) | string | No | null |
| maintenance_window | Preferred maintenance window | string | No | null |
| created_by | Identity that created the resource | string | No | null |
| terraform_workspace | Terraform workspace name | string | No | null |
| module_name | Name of the creating module | string | No | null |
| additional_tags | Additional custom tags | map(string) | No | {} |
| archetype | Landing Zone archetype | string | No | null |
| enforce_sandbox_expiration | Enforce expiration for Sandbox | bool | No | true |

## Outputs

| Name | Description |
|------|-------------|
| all_tags | Complete map of all tags |
| mandatory_tags | Map of mandatory tags only |
| security_tags | Security-related tags |
| cost_tags | Cost allocation tags |
| operational_tags | Operational tags |
| environment | Full environment name |
| environment_short | Short environment code (3 chars) |
| is_production | Boolean: is production-like environment |
| is_sandbox | Boolean: is Sandbox environment |
| criticality | Criticality level |
| criticality_description | Human-readable criticality description |
| is_critical | Boolean: is critical workload |
| data_classification | Data classification level |
| data_classification_description | Human-readable classification description |
| is_sensitive | Boolean: contains sensitive data |
| recommended_backup_tier | Recommended backup tier (GRS/LRS) |
| recommended_retention_tier | Recommended retention tier |
| expiration_date | Expiration date if set |
| has_expiration | Boolean: has expiration date |
| archetype | Landing Zone archetype |
| owner | Resource owner email |
| cost_center | Cost center code |
| application | Application name |
| project | Project name |
| department | Department name |
| creation_date | Date when tags were generated |

## Tag Reference

### Mandatory Tags

| Tag | Description | Example |
|-----|-------------|---------|
| Environment | Deployment environment | Production |
| Owner | Contact email | team@company.com |
| CostCenter | Billing code | IT-12345 |
| Application | Workload name | CustomerPortal |
| Criticality | Business importance | Critical |
| DataClassification | Security classification | Confidential |
| ManagedBy | IaC tool | Terraform |

### Conditional Tags

| Tag | Description | When Applied |
|-----|-------------|--------------|
| ExpirationDate | Resource expiry | Sandbox or when set |
| Project | Project name | When provided |
| Department | Business unit | When provided |
| Compliance | Frameworks | When provided |
| MaintenanceWindow | Maintenance schedule | When provided |
| CreatedBy | Creator identity | When provided |
| TerraformWorkspace | Workspace | When provided |
| Module | Module name | When provided |
| Archetype | LZ archetype | When provided |
| EnvironmentShort | Short code | Always |

### Automation Tags

| Tag | Description |
|-----|-------------|
| CreatedDate | Date of creation |

## Environment Short Codes

| Environment | Short Code |
|-------------|------------|
| Production | prd |
| PreProduction | ppd |
| Development | dev |
| Test | tst |
| Sandbox | sbx |
| DR | dr |

## Criticality Levels

| Level | Description | Backup | Monitoring |
|-------|-------------|--------|------------|
| Critical | Business critical | GRS, long retention | Full, 24/7 |
| High | High importance | GRS, standard retention | Enhanced |
| Medium | Standard | Environment-based | Standard |
| Low | Low importance | LRS, minimal retention | Basic |

## Data Classification Levels

| Level | Description | Encryption | Access |
|-------|-------------|------------|--------|
| Public | No restrictions | Optional | Open |
| Internal | Internal only | At rest | Employees |
| Confidential | Restricted access | At rest + transit | Need to know |
| Restricted | Highly restricted | Full | Strict controls |

## Best Practices

1. **Consistency**: Always use this module for tag generation across all modules
2. **Sandbox Cleanup**: Use expiration dates for all Sandbox resources
3. **Cost Tracking**: Ensure CostCenter values align with your finance system
4. **Owner Accountability**: Use team distribution lists, not individual emails
5. **Classification**: Default to higher classification when uncertain

## Integration with Azure Policy

The tags generated by this module are designed to work with Azure Policy for:
- Enforcing required tags at resource creation
- Auditing tag compliance
- Inheriting tags from resource groups
- Triggering automation based on tag values

## License

Proprietary - Internal Use Only
