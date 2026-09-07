# G01 — Policy Definitions

## Overview

Creates **custom Azure Policy definitions** at management group scope and references **21 built-in policies** and **2 built-in initiatives** for downstream use. Acts as the policy catalogue for the entire Landing Zone, producing structured outputs consumed by G02 (initiatives) and G03 (assignments).

**Module path:** `modules/Governance/G01-policy-definitions/`

## Resources Created

| Resource | Mode | Description |
|----------|------|-------------|
| `azurerm_policy_definition.policies` | for_each | Custom policy definitions at MG scope |
| 21× `data.azurerm_policy_definition.*` | data | Built-in policies: allowed locations, allowed VM SKUs, tags, AMA, Defender, secure storage, encryption, backup, NSG, Key Vault, WAF, HTTPS, TLS, deny public IP, managed identity |
| 2× `data.azurerm_policy_set_definition.*` | data | Built-in initiatives: Azure Security Benchmark, VM Insights with AMA |

## Inputs

### Required

| Variable | Type | Description |
|----------|------|-------------|
| `management_group_id` | `string` | MG resource ID where policies are defined (ARM ID validated) |

### Policy Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `custom_policy_definitions` | `map(object)` | `{}` | User-provided custom policy definitions |
| `deploy_caf_policies` | `bool` | `true` | Toggle CAF-aligned custom policies |
| `allowed_regions` | `list(string)` | `var.allowed_regions` | Allowed Azure regions |
| `log_analytics_workspace_id` | `string` | `""` | Central LAW ID for diagnostic policies |
| `log_retention_days` | `number` | `90` | Minimum log retention (30–730) |
| `law_total_retention_days` | `number` | `401` | Total LAW retention (30–2556) |
| `required_tags` | `list(string)` | `["Environment", "Owner", "CostCenter", "Application"]` | Required tag names |
| `denied_resource_types` | `list(string)` | Classic compute/network/storage | Denied resource types |
| `expensive_resource_types` | `list(string)` | ExpressRoute, VPN, SQL MI, Redis Enterprise | Denied in Sandbox |

### Category Toggles

| Variable | Default | Description |
|----------|---------|-------------|
| `enable_network_policies` | `true` | Network-related custom policies |
| `enable_security_policies` | `true` | Security-related custom policies |
| `enable_monitoring_policies` | `true` | Monitoring-related custom policies |
| `enable_backup_policies` | `true` | Backup-related custom policies |
| `enable_cost_policies` | `true` | Cost management custom policies |
| `enable_lifecycle_policies` | `true` | Lifecycle management policies |

## Outputs

| Output | Description |
|--------|-------------|
| `policy_definition_ids` | Map of custom policy keys to resource IDs |
| `policy_definitions` | Full map with all attributes (id, name, display_name, description, mode) |
| `network_policy_ids` / `security_policy_ids` / `monitoring_policy_ids` / `backup_policy_ids` / `cost_policy_ids` | Category-filtered policy ID maps |
| `builtin_policy_ids` | Map of 21 built-in policy IDs |
| `builtin_initiative_ids` | Map of 2 built-in initiative IDs |
| `policy_ids_for_initiatives` | Structured output by category — direct input for G02 |
| `summary` | Deployment summary with counts and enabled categories |

## How to Use in the Orchestrator

```hcl
module "policy_definitions" {
  source = "git::https://github.com/samirbelkessa/Landing-Zone.git//...G01-policy-definitions?ref=main"

  # ── Required (from F01) ──
  management_group_id = module.management_groups.root_mg_id

  # ── Policy configuration ──
  deploy_caf_policies        = var.deploy_caf_policies        # true = deploy CAF policies
  allowed_regions            = var.allowed_regions
  log_analytics_workspace_id = var.log_analytics_workspace_id
  log_retention_days         = var.log_retention_days
  law_total_retention_days   = var.law_total_retention_days
  required_tags              = var.required_tags                # ["Environment", "Owner", ...]
  denied_resource_types      = var.denied_resource_types        # Classic resources
  expensive_resource_types   = var.expensive_resource_types     # Denied in Sandbox

  # ── Category toggles (all default true) ──
  enable_security_policies   = var.enable_security_policies
  enable_network_policies    = var.enable_network_policies
  enable_monitoring_policies = var.enable_monitoring_policies
  enable_lifecycle_policies  = var.enable_lifecycle_policies
  enable_cost_policies       = var.enable_cost_policies
  enable_backup_policies     = var.enable_backup_policies

  # ── Custom policies (optional) ──
  custom_policy_definitions = var.custom_policy_definitions     # {} = none
  allowed_vm_skus_sandbox   = var.allowed_vm_skus_sandbox       # Restricted SKUs for Sandbox

  depends_on = [time_sleep.wait_for_policy_rbac]
}
```

### Options Guide

| Option | When to change | Impact |
|--------|---------------|--------|
| `enable_*_policies = false` | Disable a category of custom policies | Reduces policy count |
| `deploy_caf_policies = false` | Only use custom policies | No CAF pre-built definitions |
| `custom_policy_definitions` | Add your own custom policies | Merged with CAF policies |
| `allowed_regions` | Multi-region or different geography | Controls allowed-locations policy |

## Dependencies

- **Upstream:** F01 (provides `management_group_id`)
- **Downstream:** G02 (consumes `policy_definition_ids`, `builtin_policy_ids`, `policy_ids_for_initiatives`)

## Implementation Notes

- **Category-based filtering** uses regex matching on policy keys (e.g. `regex("network|vnet|firewall|dns", lower(k))`)
- Policy keys must follow naming convention for categorisation to work
- `prevent_destroy = false` — allows policy definitions to be destroyed
- Merges CAF pre-built policies with user `custom_policy_definitions` in locals
