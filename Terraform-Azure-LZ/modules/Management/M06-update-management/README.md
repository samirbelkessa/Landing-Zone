# M06 — Update Management

## Overview

Deploys Azure Update Manager Maintenance Configurations for automated OS patching of virtual machines. Supports both Windows and Linux patch schedules, static VM assignments, and dynamic scope assignments (filter-based). Integrates with F02 (naming), F03 (tags), and optionally M01/M03/M04.

**Module path:** `modules/Management/M06-update-management/`

## Resources Created

| Resource | Mode | Description |
|----------|------|-------------|
| `azurerm_maintenance_configuration.this` | for_each | Maintenance configurations (merged custom + defaults) |
| `azurerm_maintenance_assignment_virtual_machine.this` | for_each | Static VM assignments |
| `azurerm_maintenance_assignment_dynamic_scope.this` | for_each | Filter-based dynamic scope assignments |

## Inputs

### Required

| Variable | Type | Description |
|----------|------|-------------|
| `workload` | `string` | Workload name (2–10 chars) |
| `environment` | `string` | Environment code |
| `resource_group_name` | `string` | Target resource group |
| `location` | `string` | Azure region |

### Configurations

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `maintenance_configurations` | `map(object)` | `{}` | Custom maintenance configs with window schedules, patch settings |
| `create_default_windows_config` | `bool` | `false` | Default Windows config (Sunday 2AM, Critical+Security) |
| `create_default_linux_config` | `bool` | `false` | Default Linux config (Sunday 3AM, Critical+Security) |
| `default_timezone` | `string` | `"UTC"` | Default timezone |

### Assignments

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vm_assignments` | `map(object)` | `{}` | Static VM-to-config assignments |
| `dynamic_scope_assignments` | `map(object)` | `{}` | Filter-based dynamic assignments |

## Outputs

| Output | Description |
|--------|-------------|
| `maintenance_configuration_ids` / `_names` | Config IDs and names |
| `vm_assignment_ids` / `dynamic_scope_assignment_ids` | Assignment IDs |
| `outputs_for_m04` | Pre-formatted for M04 Alerts |
| `ready` | Boolean completion signal |

## How to Use in the Orchestrator

Deployed conditionally via `var.deploy_m06_update_management`.

```hcl
module "m06_update_management" {
  source = "git::https://github.com/samirbelkessa/Landing-Zone//Terraform-Azure-LZ/modules/Management/M06-update-management?ref=main"

  # ── Required ──
  workload            = var.management_project_name
  environment         = var.environment
  location            = var.default_location
  resource_group_name = try(module.l01-subscription-vending-v2.resource_groups_by_subscription["management"]["monitoring"].name, "")

  # ── Naming ──
  custom_name_prefix = var.update_management_custom_name_prefix
  region             = local.primary_region
  instance           = var.management_instance

  # ── Default Configs ──
  create_default_windows_config = var.create_default_windows_config    # true = Sunday 2AM Critical+Security
  create_default_linux_config   = var.create_default_linux_config      # true = Sunday 3AM Critical+Security
  default_timezone              = var.default_timezone                  # "AUS Eastern Standard Time"
  default_target_locations      = var.update_target_locations

  # ── Custom Configs ──
  maintenance_configurations = var.maintenance_configurations    # Custom maintenance windows

  # ── Assignments ──
  vm_assignments            = var.vm_assignments                # Static VM-to-config
  dynamic_scope_assignments = var.dynamic_scope_assignments     # Tag/subscription-based dynamic

  # ── LAW Integration ──
  log_analytics_workspace_id = var.deploy_m01_log_analytics ? module.m01_log_analytics[0].id : null

  # ── Action Groups (from M03, optional) ──
  action_group_ids = var.deploy_m03_action_groups ? {
    critical = module.m03_action_groups[0].action_group_ids["critical"]
    warning  = module.m03_action_groups[0].action_group_ids["warning"]
    info     = module.m03_action_groups[0].action_group_ids["info"]
  } : {}

  # ── Conditional ──
  count = var.deploy_m06_update_management ? 1 : 0
  tags  = local.tags_management

  depends_on = [module.l01-subscription-vending-v2, module.m01_log_analytics, module.m03_action_groups]
  providers  = { azurerm = azurerm.management }
}
```

### Options Guide

| Option | When to change | Impact |
|--------|---------------|--------|
| `create_default_windows_config = true` | Standard Windows patching | Sunday 2AM, Critical+Security updates |
| `create_default_linux_config = true` | Standard Linux patching | Sunday 3AM, Critical+Security updates |
| `default_timezone` | Different region/timezone | Changes maintenance window time zone |
| `vm_assignments = {...}` | Static VM targeting | Direct VM-to-maintenance-config binding |
| `dynamic_scope_assignments = {...}` | Tag-based targeting | Filter VMs by tags/subscription |
| `maintenance_configurations = {...}` | Custom schedules | Full control over patch windows and classifications |

## Dependencies

- **Upstream:** M02 (optional Automation Account link)
- **Downstream:** M04 (optional alerts)

## Implementation Notes

- **Tag filter limitation:** `azurerm_maintenance_assignment_dynamic_scope` does NOT support tag filters in Terraform — uses `lifecycle { ignore_changes = [filter] }` to protect manual Portal configurations
- **Dynamic `install_patches`** blocks only rendered when `scope == "InGuestPatch"`
- **Naming pattern:** `mc-{workload}-{env}-{region}-{instance}` (Maintenance Configurations lack a standard F02 type)
