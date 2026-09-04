# L02 — Spoke Virtual Network

## Overview

Deploys a complete spoke virtual network in a hub-spoke topology: resource group, VNet, subnets, NSGs with baseline rules, route tables with default-to-firewall UDR, bidirectional VNet peering, diagnostics, VNet flow logs, Private DNS Zone links, management locks, and additional VNets.

**Module path:** `modules/LandingZone/L02-Spoke/`

> **This module uses two aliased providers:** `azurerm.spoke` (spoke subscription) and `azurerm.hub` (hub subscription for peering + DNS zone links). Cross-subscription deployment is a core design requirement.

## Resources Created

| Resource | Mode | Description |
|----------|------|-------------|
| `azurerm_resource_group.this` | 1 | Spoke network resource group |
| `azurerm_virtual_network.this` | 1 | Primary spoke VNet |
| `azurerm_subnet.this` | for_each | Subnets |
| `azurerm_network_security_group.this` | for_each | Per-subnet NSGs |
| `azurerm_subnet_network_security_group_association.this` | for_each | NSG-to-subnet bindings |
| `azurerm_network_security_rule.this` | for_each | NSG rules (baseline + custom) |
| `azurerm_route_table.this` | 1 | Route table |
| `azurerm_route.default_to_firewall` | 1 | 0.0.0.0/0 → Azure Firewall |
| `azurerm_route.additional` | for_each | Custom routes |
| `azurerm_subnet_route_table_association.this` | for_each | UDR associations (selective) |
| `azurerm_virtual_network_peering.spoke_to_hub` | 1 | Spoke-to-hub peering |
| `azurerm_virtual_network_peering.hub_to_spoke` | 1 | Hub-to-spoke peering (via hub provider) |
| `azurerm_monitor_diagnostic_setting.vnet` | 1 | VNet diagnostics |
| `azurerm_monitor_diagnostic_setting.nsg` | for_each | Per-NSG diagnostics |
| `azurerm_private_dns_zone_virtual_network_link.this` | for_each | DNS zone links to hub zones |
| `azurerm_virtual_network.additional` | for_each | Additional VNets |
| `azurerm_network_watcher_flow_log.primary/additional` | count | VNet flow logs |
| `azurerm_management_lock.vnet` | count 0–1 | CanNotDelete lock |

## Inputs

### Required

| Variable | Type | Description |
|----------|------|-------------|
| `root_id` | `string` | Naming prefix (2–10 chars) |
| `workload` | `string` | Workload short name |
| `environment` | `string` | Development/Test/Staging/Production |
| `location` | `string` | Azure region |
| `address_space` | `list(string)` | VNet CIDR(s) |
| `subnets` | `map(object)` | Subnet definitions (delegation, PE policies, service endpoints) |
| `firewall_private_ip` | `string` | Azure Firewall IP for UDR and DNS |
| `hub_vnet_id` / `hub_vnet_name` / `hub_resource_group_name` | `string` | Hub VNet references |

### Key Optional

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `use_remote_gateways` | `bool` | `true` | Gateway transit for peering |
| `udr_subnet_keys` | `list(string)` | `["aks"]` | Subnets getting UDR association |
| `nsg_rules` | `map(object)` | `{}` | Custom NSG rules (merged with baseline) |
| `enable_baseline_nsg_rules` | `bool` | `true` | Bastion/ALB/VNet/Deny-all baseline |
| `private_dns_zone_links` | `map(object)` | `{}` | DNS zones to link |
| `enable_delete_lock` | `bool` | `true` | CanNotDelete lock on VNet |
| `enable_vnet_flow_logs` | `bool` | `false` | VNet-level flow logging |
| `additional_vnets` | `map(object)` | `{}` | Additional VNets with subnets and peering |

## Outputs

| Output | Description |
|--------|-------------|
| `resource_group_name` / `resource_group_id` | Spoke RG |
| `vnet_id` / `vnet_name` / `vnet_address_space` | Primary VNet |
| `subnet_ids` / `subnet_names` / `subnet_address_prefixes` | Subnet maps |
| `nsg_ids` / `route_table_id` | Security/routing |
| `peering_spoke_to_hub_id` / `peering_hub_to_spoke_id` | Peering IDs |
| `flow_log_id` / `additional_flow_log_ids` | Flow log IDs |
| `dns_zone_link_ids` | DNS zone link map |
| `lock_id` | Management lock ID |

## How to Use in the Orchestrator

L02 is **not called directly** from the orchestrator — it is wrapped by the **ClientLZ** composite module. ClientLZ adds firewall rules, UAMI, diagnostics, and policy exemptions around L02.

If you need a standalone spoke without ClientLZ features:

```hcl
module "spoke_standalone" {
  source = "git::https://github.com/samirbelkessa/Landing-Zone//Terraform-Azure-LZ/modules/LandingZone/L02-Spoke?ref=main"

  # ── Required ──
  root_id                 = var.root_id
  workload                = "myapp"
  environment             = "Development"
  location                = var.default_location
  address_space           = ["10.100.0.0/24"]
  subnets = {
    app = { address_prefixes = ["10.100.0.0/26"] }
    db  = { address_prefixes = ["10.100.0.64/26"] }
    pep = { address_prefixes = ["10.100.0.128/26"] }
  }

  # ── Hub References ──
  hub_vnet_id             = local.spoke_common.hub_vnet_id
  hub_vnet_name           = local.spoke_common.hub_vnet_name
  hub_resource_group_name = local.spoke_common.hub_resource_group_name
  firewall_private_ip     = local.spoke_common.firewall_private_ip

  # ── Peering Options ──
  use_remote_gateways    = var.enable_vpn_gateway
  allow_gateway_transit   = var.enable_vpn_gateway

  # ── Routing ──
  udr_subnet_keys               = ["app", "db"]    # Subnets routed through firewall
  disable_bgp_route_propagation = true

  # ── Security ──
  enable_baseline_nsg_rules  = true
  base_nsg_rules             = local.nsg_experteq_base_rules
  nsg_rules                  = {}    # Custom per-subnet NSG rules

  # ── DNS ──
  private_dns_zone_links = local.spoke_common_dns_zone_links

  # ── Diagnostics ──
  log_analytics_workspace_id = module.m01_log_analytics[0].id
  enable_vnet_diagnostics    = true
  enable_nsg_diagnostics     = true

  # ── Protection ──
  enable_delete_lock = true

  tags = local.spoke_common.tags

  providers = {
    azurerm.spoke = azurerm.client_dev
    azurerm.hub   = azurerm.connectivity
  }
}
```

### Options Guide

| Option | When to change | Impact |
|--------|---------------|--------|
| `use_remote_gateways = true` | VPN gateway deployed | Spokes use hub VPN gateway |
| `udr_subnet_keys = ["app"]` | Control firewall routing | Only listed subnets get UDR |
| `enable_baseline_nsg_rules = true` | Standard Bastion/ALB/Deny rules | Base security on all NSGs |
| `private_dns_zone_links = {...}` | Link hub DNS zones | Spoke resolves private endpoints |
| `additional_vnets = {...}` | Multiple VNets per spoke | Extra VNets with independent peering |
| `enable_vnet_flow_logs = true` | Network traffic logging | VNet-level flow log (replaces NSG flow logs) |
| `enable_delete_lock = true` | Production protection | CanNotDelete lock on VNet |

> **Recommended:** Use **ClientLZ** instead of calling L02 directly — it handles firewall rules, UAMI, and diagnostics automatically.

## Dependencies

- **Upstream:** F01 (root_id), AVM Connectivity (hub VNet), C14 (firewall IP)
- **Downstream:** ClientLZ (wraps this module), M05 (diagnostic settings), M09 (flow logs)

## Implementation Notes

- **Two providers required:** `azurerm.spoke` and `azurerm.hub` — cross-subscription peering and DNS zone links
- **NSG rule merging:** `local.all_nsg_rules` merges baseline + custom (key collision overwrites baseline)
- **Selective UDR:** Only subnets in `udr_subnet_keys` get firewall route; PE/PLS subnets excluded (Azure ignores UDRs on them)
- **VNet DNS servers** default to `[firewall_private_ip]` for DNS proxy resolution
- **DNS zone links** set `registration_enabled = false` — spoke VMs do not auto-register
- **Subnet naming** uses computed TAS convention via `root_id`, `workload`, `environment`
