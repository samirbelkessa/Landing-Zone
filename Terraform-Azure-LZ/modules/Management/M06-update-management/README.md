# M06 - Update Management Module (Azure Update Manager)

## Overview

This module deploys Azure Update Manager Maintenance Configurations for automated VM patching in Azure Landing Zone Architecture. It integrates with F02 (Naming Convention) and F03 (Tagging) modules to ensure consistent naming and tagging across all resources.

## 🎯 Key Features

- ✅ **Zero Hardcoding**: All values configurable via variables
- ✅ **F02 Integration**: Automatic naming convention compliance
- ✅ **F03 Integration**: Standardized tagging strategy
- ✅ **Hybrid Approach**: Terraform manages structure, Azure Portal manages tag filters
- ✅ **M01/M03/M04 Ready**: Outputs compatible with other modules
- ✅ **5 Dynamic Scopes**: Recommended configuration for most projects
- ✅ **Lifecycle Protection**: Manual Portal configurations won't be overwritten

## 🔧 Architecture

### Terraform Manages

- Maintenance Configurations (schedules, patch classifications, reboot behavior)
- Dynamic Scope Assignments (base structure: locations, OS types, resource types)
- Naming via F02 module
- Tagging via F03 module

### Azure Portal Manages

- **Tag Filters** for Dynamic Scope Assignments (configured manually after deployment)

### Why This Approach?

Due to Terraform limitations with the `tags` block structure in `azurerm_maintenance_assignment_dynamic_scope`, tag filters cannot be reliably managed via Terraform. Instead:

1. **Terraform creates** the Dynamic Scope Assignment with basic filters (location, OS)
2. **You configure** tag filters manually in Azure Portal (one-time setup)
3. **lifecycle.ignore_changes** protects your manual configurations from being overwritten

## Prerequisites

### Required

- **Terraform**: >= 1.5.0
- **Provider**: azurerm >= 3.80.0
- **Required Modules**:
  - F02 - Naming Convention (`../F02-naming-convention`)
  - F03 - Tags (`../F03-tags`)

### Optional

- M01 - Log Analytics Workspace (for enhanced logging)
- M03 - Action Groups (for alerting integration)
- M04 - Monitor Alerts (for Update Manager alerts)

### VM Configuration

All VMs must have:

```hcl
resource "azurerm_windows_virtual_machine" "example" {
  # ... other configuration ...

  # REQUIRED for Azure Update Manager
  patch_mode = "AutomaticByPlatform"
  bypass_platform_safety_checks_on_user_schedule_enabled = true
  
  # Tags for dynamic scope filtering
  tags = {
    Environment = "Production"  # Required for filtering
    Criticality = "Critical"    # Required for filtering
    Owner       = "team@company.com"
    CostCenter  = "IT-001"
  }
}
```

## Quick Start

### 1. Copy Module to Orchestrator

```bash
cp -r M06-update-management/ orchestrator-lza-mng/modules/
```

### 2. Add Module Call

In `orchestrator-lza-mng/main.tf`:

```hcl
module "m06_update_management" {
  count  = var.deploy_m06_update_management ? 1 : 0
  source = "./modules/M06-update-management"

  # F02 inputs
  workload    = var.workload
  environment = var.environment
  region      = var.region
  instance    = var.instance

  # F03 inputs
  owner       = var.owner
  cost_center = var.cost_center
  application = var.application

  # Resource placement
  resource_group_name = local.rg_name
  location            = local.primary_region

  # Configurations
  maintenance_configurations    = var.maintenance_configurations
  dynamic_scope_assignments     = var.dynamic_scope_assignments
  create_default_windows_config = true
  create_default_linux_config   = true
  default_timezone              = "AUS Eastern Standard Time"
  default_target_locations      = ["australiaeast", "australiasoutheast"]
}
```

### 3. Configure terraform.tfvars

Use the provided `terraform.tfvars.example` as a template.

### 4. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 5. Configure Tag Filters (CRITICAL POST-DEPLOYMENT STEP)

After `terraform apply` completes, configure tag filters in Azure Portal:

1. Navigate to **Azure Portal** → **Update Manager** → **Schedules**
2. Click on your maintenance configuration (e.g., `mc-platform-prd-aue-001-critical-monthly`)
3. Go to **Machines** → **Dynamic scopes**
4. Click on an assignment (e.g., `mc-platform-prd-aue-001-assignment-1-prod-critical`)
5. Click **"Edit"**
6. Scroll to **"Tags"** section
7. Configure tag filters:
   - **Tag matching**: All (or Any, depending on your needs)
   - **Add tag filter**:
     - Tag name: `Environment`
     - Tag values: `Production`
   - **Add another tag filter**:
     - Tag name: `Criticality`
     - Tag values: `Critical, High`
8. Click **"Save"**

Repeat for each dynamic scope assignment.

## Recommended Configuration: 5 Dynamic Scopes

The provided `terraform.tfvars.example` includes 5 recommended dynamic scopes:

```
1. prod-critical      → Critical production VMs (1st Sunday 1AM)
2. prod-standard      → Standard production VMs (2nd Tuesday 10PM)
3. nonprod-all        → All non-production VMs (Sunday 2AM)
4. all-windows-def    → All Windows VMs (daily definitions)
5. prod-linux         → Production Linux VMs (Wednesday 11PM)
```

This covers 95% of use cases while remaining simple and maintainable.

## Tag Filter Configuration Guide

### For Production Critical VMs

**Dynamic Scope**: `1-prod-critical`

```
Tag matching: All (must match ALL tags)

Tag filters:
├─ Environment: Production
└─ Criticality: Critical, High
```

**Result**: Only VMs with **both** `Environment=Production` AND `Criticality=Critical or High` will be assigned.

### For Production Standard VMs

**Dynamic Scope**: `2-prod-standard`

```
Tag matching: All

Tag filters:
├─ Environment: Production
└─ Criticality: Medium, Low
```

### For Non-Production VMs

**Dynamic Scope**: `3-nonprod-all`

```
Tag matching: Any (match ANY tag)

Tag filters:
└─ Environment: Development, Test, UAT, Staging
```

**Result**: VMs with **any** of these Environment values will be assigned.

### For All Windows Definitions

**Dynamic Scope**: `4-all-windows-definitions`

```
NO TAG FILTERS

Filters only by:
├─ Resource type: Virtual Machines
├─ Location: australiaeast, australiasoutheast
└─ OS type: Windows
```

**Result**: ALL Windows VMs in specified locations (no tag filtering).

## Azure Update Manager Discovery Process

### How Azure Finds VMs

1. **Azure Resource Graph** indexes all resources (including VMs and their tags)
2. **Azure Update Manager** queries Resource Graph every **15 minutes**
3. **Dynamic Scopes** evaluate VMs against filter criteria
4. **Matching VMs** are automatically assigned to Maintenance Configurations

### Timeline

```
T+0min   : You create a new VM with tags
T+1-5min : VM indexed in Azure Resource Graph
T+15min  : Azure Update Manager scans and finds the VM
           VM auto-assigned to matching Dynamic Scope
T+1-24h  : First assessment scan (checks for available updates)
T+X      : VM patched according to schedule
```

### Required VM Tags

For the 5 recommended dynamic scopes, VMs need these tags:

```hcl
# Production Critical VM
tags = {
  Environment = "Production"   # Required
  Criticality = "Critical"     # Required (or "High")
  Owner       = "team@company.com"
  CostCenter  = "IT-001"
}

# Production Standard VM
tags = {
  Environment = "Production"
  Criticality = "Medium"       # or "Low"
  # ... other tags
}

# Non-Production VM
tags = {
  Environment = "Development"  # or Test, UAT, Staging
  Criticality = "Low"
  # ... other tags
}
```

## Inputs

### F02 Naming Inputs (Required)

| Name | Description | Type | Example |
|------|-------------|------|---------|
| `workload` | Workload name for F02 | `string` | `"platform"` |
| `environment` | Environment for F02 | `string` | `"prod"` |
| `region` | Azure region abbreviation | `string` | `"aue"` |
| `instance` | Instance number | `string` | `"001"` |

### F03 Tagging Inputs (Required)

| Name | Description | Type | Example |
|------|-------------|------|---------|
| `owner` | Owner email | `string` | `"team@company.com"` |
| `cost_center` | Cost center code | `string` | `"IT-001"` |

### Module Inputs (Required)

| Name | Description | Type |
|------|-------------|------|
| `resource_group_name` | Resource group name | `string` |
| `location` | Azure region | `string` |

### Configuration Inputs (Optional)

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `maintenance_configurations` | Custom configurations | `map(object)` | `{}` |
| `dynamic_scope_assignments` | Dynamic scope assignments | `map(object)` | `{}` |
| `create_default_windows_config` | Create default Windows config | `bool` | `false` |
| `create_default_linux_config` | Create default Linux config | `bool` | `false` |
| `default_timezone` | Default timezone | `string` | `"UTC"` |

## Outputs

### Naming Outputs

| Name | Description |
|------|-------------|
| `generated_name` | Generated name from F02 |
| `naming_details` | Full F02 naming details |

### Configuration Outputs

| Name | Description |
|------|-------------|
| `maintenance_configuration_ids` | Map of config IDs |
| `maintenance_configuration_names` | Map of config names |
| `windows_configurations` | List of Windows config keys |
| `linux_configurations` | List of Linux config keys |

### Integration Outputs

| Name | Description |
|------|-------------|
| `configuration` | Full configuration summary |
| `outputs_for_m04` | Outputs for M04 integration |
| `ready` | Ready flag for dependencies |

## Examples

### Basic Example (Australia Project)

```hcl
module "m06_update_management" {
  source = "./modules/M06-update-management"

  # F02 inputs
  workload    = "platform"
  environment = "prod"
  region      = "aue"
  instance    = "001"

  # F03 inputs
  owner       = "platform-team@company.com.au"
  cost_center = "IT-PLATFORM-AUS-001"

  # Resource placement
  resource_group_name = "rg-platform-prd-aue-001"
  location            = "australiaeast"

  # 5 Dynamic Scopes (tags configured in Portal)
  dynamic_scope_assignments = {
    "1-prod-critical" = {
      maintenance_configuration_key = "critical-monthly"
      filter = {
        locations = ["australiaeast", "australiasoutheast"]
        os_types  = ["Windows"]
      }
    }
    "2-prod-standard" = {
      maintenance_configuration_key = "standard-monthly"
      filter = {
        locations = ["australiaeast", "australiasoutheast"]
        os_types  = ["Windows"]
      }
    }
    # ... see terraform.tfvars.example for complete configuration
  }
}
```

## Troubleshooting

### VMs Not Being Assigned

**Issue**: VMs not appearing in Dynamic Scope

**Solutions**:
1. Check VM has `patch_mode = "AutomaticByPlatform"`
2. Verify VM has required tags (Environment, Criticality)
3. Verify tag filters configured correctly in Portal
4. Wait 15 minutes for Azure Update Manager scan
5. Check Azure Portal → Update Manager → Machines

### Tag Filters Overwritten by Terraform

**Issue**: Manual tag filters disappear after `terraform apply`

**Solution**: Ensure `lifecycle { ignore_changes = [filter] }` is present in main.tf (already included in this module)

### Terraform Validation Errors

**Issue**: Errors about `values` attribute or blocks

**Solution**: This module intentionally does NOT include tag_filter in Terraform code. Configure tag filters manually in Portal as documented.

## Migration from Other Solutions

### From Legacy Automation Account Update Management

1. Deploy M06 alongside existing solution
2. Test with non-critical VMs first
3. Gradually migrate VMs by changing `patch_mode`
4. Decommission old solution after validation

### From Manual Patching

1. Deploy M06 with conservative schedules
2. Tag VMs progressively (start with dev/test)
3. Monitor first patching cycles
4. Expand to production after validation

## Best Practices

### Naming

- Use F02 for consistency across Landing Zone
- Keep configuration keys short and descriptive

### Tagging

- Always provide F03 required tags
- Use consistent tag values (Production vs production vs Prod - pick one!)
- Tag VMs immediately upon creation

### Patching Strategy

- **Critical VMs**: Monthly, off-hours, always reboot
- **Standard VMs**: Monthly, post-Patch-Tuesday, if-required reboot
- **Non-Prod VMs**: Weekly or monthly, flexible schedule
- **Definitions**: Daily, never reboot

### Organization

- Start with 5 scopes (covers 95% of needs)
- Add more scopes only when truly needed
- Document tag filter configurations

## Support

For issues or questions:
1. Check this README
2. Review terraform.tfvars.example
3. Consult Azure Update Manager documentation
4. Contact Platform Team

## Version

- **Module Version**: 3.0.0 (Final with Portal tag filters)
- **Last Updated**: January 1, 2025
- **Author**: Platform Team
- **Language**: English

## License

Proprietary - Internal use only
