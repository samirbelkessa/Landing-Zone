# 07-Security Orchestrator

## Overview

This orchestrator deploys **platform security components** following Azure CAF best practices:

- **Microsoft Defender for Cloud** - Threat protection across all subscriptions
- **Microsoft Sentinel** - SIEM/SOAR solution on Log Analytics
- **Azure Key Vault** - Centralized secrets management

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         07-SECURITY ORCHESTRATOR                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  📍 Management Subscription                                                 │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  rg-security-aue-001                                                 │   │
│  │  └── kv-intelly-platform-aue                                        │   │
│  │      ├── RBAC Authorization ✅                                      │   │
│  │      ├── Purge Protection ✅                                        │   │
│  │      ├── Private Endpoint → Hub VNet                                │   │
│  │      └── Diagnostic Settings → Log Analytics                        │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Microsoft Sentinel (on law-intelly-management-aue-001)              │   │
│  │  ├── Data Connector: Azure Active Directory                         │   │
│  │  ├── Data Connector: Defender for Cloud                             │   │
│  │  └── Data Connector: Threat Intelligence                            │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  📍 ALL Platform Subscriptions (Management, Connectivity, Identity)        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Microsoft Defender for Cloud                                        │   │
│  │  ├── Servers (P2 with EDR)                                          │   │
│  │  ├── Storage Accounts                                               │   │
│  │  ├── SQL Servers                                                    │   │
│  │  ├── App Services                                                   │   │
│  │  ├── Key Vaults                                                     │   │
│  │  ├── ARM (Management Plane)                                         │   │
│  │  ├── Containers                                                     │   │
│  │  └── DNS                                                            │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Prerequisites

### 1. Deployed Orchestrators (Remote State)

| Orchestrator | Required | Outputs Used |
|--------------|----------|--------------|
| 01-foundation | ✅ Yes | Management Group IDs |
| 03-management | ✅ Yes | Log Analytics Workspace ID |
| 04-connectivity | ✅ Yes | Hub VNet, Subnet IDs, Private DNS Zones |

### 2. Permissions

The executing identity requires:
- **Owner** on Management, Connectivity, Identity subscriptions (for Defender)
- **Security Admin** on subscriptions
- **Key Vault Administrator** (for Key Vault creation)

## Modules Deployed

| Module | Resource | Provider |
|--------|----------|----------|
| S01 | Microsoft Defender for Cloud | Native `azurerm_security_center_*` |
| S02 | Microsoft Sentinel | Native `azurerm_sentinel_*` |
| S03 | Azure Key Vault | Native `azurerm_key_vault` |

## Usage

### 1. Initialize

```bash
cd orchestrators/07-security
terraform init
```

### 2. Review Plan

```bash
terraform plan -out=tfplan
```

### 3. Apply

```bash
terraform apply tfplan
```

## Configuration

### Key Vault Settings

```hcl
key_vault_sku                        = "standard"  # or "premium" for HSM
key_vault_soft_delete_retention_days = 90
key_vault_enable_purge_protection    = true
key_vault_enable_private_endpoint    = true        # Recommended
key_vault_public_network_access      = false       # Recommended
```

### Defender Plans

```hcl
defender_plans = {
  virtual_machines = {
    enabled = true
    subplan = "P2"  # P1 = basic, P2 = with EDR
  }
  storage_accounts = {
    enabled = true
    subplan = "DefenderForStorageV2"
  }
  # ... other plans
}
```

### Sentinel Data Connectors

```hcl
sentinel_data_connectors = {
  azure_active_directory = true   # Entra ID audit/sign-in logs
  azure_activity         = true   # Azure activity logs
  defender_for_cloud     = true   # Defender alerts
  threat_intelligence    = true   # TI indicators
}
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `tenant_id` | Azure Tenant ID | `string` | Yes |
| `management_subscription_id` | Management subscription ID | `string` | Yes |
| `connectivity_subscription_id` | Connectivity subscription ID | `string` | Yes |
| `identity_subscription_id` | Identity subscription ID | `string` | Yes |
| `location` | Azure region | `string` | No (default: australiaeast) |
| `security_contact_email` | Email for security alerts | `string` | Yes |
| `deploy_key_vault` | Deploy Key Vault | `bool` | No (default: true) |
| `deploy_sentinel` | Deploy Sentinel | `bool` | No (default: true) |
| `deploy_defender` | Deploy Defender | `bool` | No (default: true) |

## Outputs

| Name | Description |
|------|-------------|
| `key_vault_id` | Key Vault resource ID |
| `key_vault_uri` | Key Vault URI |
| `sentinel_workspace_id` | Sentinel workspace ID |
| `defender_plans_enabled` | List of enabled Defender plans |
| `deployment_status` | Status of each component |

## Dependencies

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  01-foundation  │     │  03-management  │     │ 04-connectivity │
│                 │     │                 │     │                 │
│  MG IDs         │     │  LAW ID         │     │  Hub VNet       │
│  Sub IDs        │     │  RG Name        │     │  Subnet IDs     │
│                 │     │                 │     │  DNS Zones      │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                                 ▼
                         ┌───────────────┐
                         │  07-security  │
                         │               │
                         │  Defender     │
                         │  Sentinel     │
                         │  Key Vault    │
                         └───────────────┘
```

## Cost Estimation

| Component | Estimated Cost |
|-----------|----------------|
| Defender Servers P2 | ~$15/VM/month |
| Defender Storage | ~$0.02/10k transactions |
| Defender other plans | Variable |
| Sentinel ingestion | ~$2.76/GB |
| Key Vault operations | ~$0.03/10k ops |
| Private Endpoint | ~$7.30/month |

## Troubleshooting

### Error: Insufficient permissions for Defender

```
Error: authorization failed
```

**Solution:** Ensure the executing identity has **Owner** or **Security Admin** role on all target subscriptions.

### Error: Key Vault name already exists

```
Error: Key Vault with name 'xxx' already exists
```

**Solution:** Key Vault names are globally unique. Change `key_vault_name` in tfvars.

### Error: Private Endpoint subnet not found

```
Error: local.private_endpoint_subnet_id is null
```

**Solution:** Verify 04-connectivity is deployed and outputs `hub_subnet_ids` with a SharedServices subnet.

## CAF Compliance

This orchestrator implements:

- ✅ Centralized security monitoring (Defender + Sentinel)
- ✅ Secrets management with RBAC (Key Vault)
- ✅ Private connectivity (Private Endpoints)
- ✅ Audit logging (Diagnostic Settings)
- ✅ Multi-subscription security baseline
