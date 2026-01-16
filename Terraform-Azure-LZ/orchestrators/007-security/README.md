# 007-Security Orchestrator

## Overview

This orchestrator deploys **platform security components** following Azure CAF best practices:

- **S01 - Microsoft Defender for Cloud** - Threat protection across all subscriptions
- **S02 - Microsoft Sentinel** - SIEM/SOAR solution on Log Analytics
- **S03 - Azure Key Vault** - Centralized secrets management with Private Endpoint
- **S05 - Network Security Group** - Baseline NSG rules for shared services

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         007-SECURITY ORCHESTRATOR                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  📍 Management Subscription                                                 │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  rg-security-aue-001                                                 │   │
│  │  └── kv-intelly-platform-aue (S03 - AVM)                            │   │
│  │      ├── RBAC Authorization ✅                                      │   │
│  │      ├── Purge Protection ✅                                        │   │
│  │      ├── Private Endpoint → Hub VNet (S04 - Integrated)             │   │
│  │      └── Diagnostic Settings → Log Analytics                        │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Microsoft Sentinel (S02 - Custom Module)                            │   │
│  │  ├── Onboarding to Log Analytics Workspace                          │   │
│  │  ├── Data Connector: Azure Activity                                 │   │
│  │  ├── Data Connector: Defender for Cloud                             │   │
│  │  └── Data Connector: Threat Intelligence                            │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Microsoft Defender for Cloud (S01 - Custom Module)                  │   │
│  │  ├── Servers (P2 with EDR)                                          │   │
│  │  ├── Storage Accounts                                               │   │
│  │  ├── SQL Servers                                                    │   │
│  │  ├── App Services                                                   │   │
│  │  ├── Key Vaults                                                     │   │
│  │  ├── ARM (Management Plane)                                         │   │
│  │  ├── Containers                                                     │   │
│  │  └── Cloud Posture (CSPM)                                           │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  📍 Connectivity Subscription                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  nsg-shared-services-prod-aue (S05 - AVM)                            │   │
│  │  ├── Baseline Rules (14 rules from NSGRulesBase.json)               │   │
│  │  ├── Custom Rules (optional)                                        │   │
│  │  └── Diagnostic Settings → Log Analytics                            │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Components

| Code | Component | Type | Source |
|------|-----------|------|--------|
| S01 | Defender for Cloud | Custom Module | `modules/Security/S01-defender-for-cloud` |
| S02 | Microsoft Sentinel | Custom Module | `modules/Security/S02-sentinel` |
| S03 | Azure Key Vault | AVM Direct | `Azure/avm-res-keyvault-vault v0.10.2` |
| S04 | Private Endpoint | Integrated | (Integrated in S03 AVM) |
| S05 | Network Security Group | AVM Direct | `Azure/avm-res-network-networksecuritygroup v0.5.1` |

## Prerequisites

### 1. Deployed Orchestrators (Remote State)

| Orchestrator | Required | Outputs Used |
|--------------|----------|--------------|
| 01-foundation | Optional | Management Group IDs |
| 03-management | ✅ **Yes** | Log Analytics Workspace ID, Name |
| 04-connectivity | ✅ **Yes** | Hub VNet, Subnet IDs, Private DNS Zones |

### 2. Permissions

The executing identity requires:
- **Owner** on Management, Connectivity, Identity subscriptions (for Defender)
- **Security Admin** on subscriptions
- **Key Vault Administrator** (for Key Vault creation)

### 3. Remote State Storage

```hcl
remote_state_config = {
  resource_group_name  = "rg-terraform-state-aue"
  storage_account_name = "stlzterraformstateaue"
  container_name       = "tfstate"
}
```

## Usage

### 1. Initialize

```bash
cd orchestrators/007-security
terraform init
```

### 2. Create tfvars file

```hcl
# terraform.tfvars

# Subscription IDs
tenant_id                    = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
management_subscription_id   = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
connectivity_subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
identity_subscription_id     = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Location
location = "australiaeast"

# Naming
organization = "intelly"
environment  = "prod"

# Remote State
remote_state_config = {
  resource_group_name  = "rg-terraform-state-aue"
  storage_account_name = "stlzterraformstateaue"
  container_name       = "tfstate"
}

# Security Contact
security_contact_email = "security@intelly.com.au"

# Tags
owner       = "platform-team@intelly.com.au"
cost_center = "IT-Platform"

# Feature Flags
deploy_resource_group = true
deploy_key_vault      = true
deploy_sentinel       = true
deploy_defender       = true
deploy_nsg_baseline   = true

# NSG Configuration
enable_nsg_baseline_rules = true

# Key Vault Configuration
key_vault_sku                   = "standard"
key_vault_enable_purge_protection = true
key_vault_enable_private_endpoint = true
key_vault_public_network_access   = false

# Sentinel Data Connectors
sentinel_data_connectors = {
  azure_active_directory       = false  # Requires AAD P1/P2 license
  azure_activity               = true
  defender_for_cloud           = true
  threat_intelligence          = true
  microsoft_cloud_app_security = false
  office_365                   = false
  microsoft_365_defender       = false
  azure_advanced_threat_protection = false
}
```

### 3. Review Plan

```bash
terraform plan -out=tfplan
```

### 4. Apply

```bash
terraform apply tfplan
```

## Inputs

### Required

| Name | Description | Type |
|------|-------------|------|
| `tenant_id` | Azure Tenant ID | `string` |
| `management_subscription_id` | Management subscription ID | `string` |
| `connectivity_subscription_id` | Connectivity subscription ID | `string` |
| `identity_subscription_id` | Identity subscription ID | `string` |
| `security_contact_email` | Email for security alerts | `string` |
| `remote_state_config` | Remote state configuration | `object` |
| `owner` | Owner email for tags | `string` |
| `cost_center` | Cost center for tags | `string` |

### Optional

| Name | Description | Default |
|------|-------------|---------|
| `location` | Azure region | `australiaeast` |
| `environment` | Environment name | `prod` |
| `deploy_key_vault` | Deploy Key Vault | `true` |
| `deploy_sentinel` | Deploy Sentinel | `true` |
| `deploy_defender` | Deploy Defender | `true` |
| `deploy_nsg_baseline` | Deploy baseline NSG | `true` |
| `enable_nsg_baseline_rules` | Enable baseline rules | `true` |

## Outputs

| Name | Description |
|------|-------------|
| `resource_group_name` | Security resource group name |
| `key_vault_id` | Key Vault resource ID |
| `key_vault_uri` | Key Vault URI |
| `sentinel_onboarding_id` | Sentinel onboarding ID |
| `defender_enabled_plans` | List of enabled Defender plans |
| `nsg_id` | NSG resource ID |
| `deployment_status` | Status of each component |
| `security_config` | Complete configuration summary |

## NSG Baseline Rules

The orchestrator includes 14 baseline NSG rules from `nsg-baseline-rules.tf`:

### Inbound Rules

| Rule | Priority | Source | Destination | Ports | Action |
|------|----------|--------|-------------|-------|--------|
| Azure_LoadBalancer_InBound | 1001 | AzureLoadBalancer | * | 80,443,8080 | Allow |
| Azure_ServiceFabric_InBound | 1002 | ServiceFabric | * | * | Allow |
| EXPDC_Infrastructure_DC_Shared_InBound | 1010 | On-prem ranges | VirtualNetwork | * | Allow |
| Default_Deny_InBound_Override | 4096 | * | * | * | **Deny** |

### Outbound Rules

| Rule | Priority | Source | Destination | Ports | Action |
|------|----------|--------|-------------|-------|--------|
| Qualys_Datacenter_OutBound | 880 | VirtualNetwork | Qualys IPs | 443 | Allow |
| Azure_Storage_AustraliaEast_OutBound | 1000 | VirtualNetwork | Storage.AUE | 80,443,445 | Allow |
| Azure_Storage_AustraliaSouthEast_OutBound | 1001 | VirtualNetwork | Storage.AUSE | 80,443,445 | Allow |
| Azure_ActiveDirectory_OutBound | 1002 | VirtualNetwork | AAD | 443,636,389,5986 | Allow |
| Azure_Storage_OutBound | 1008 | VirtualNetwork | Storage | 80,443,445 | Allow |
| Azure_SiteRecovery_OutBound | 1009 | VirtualNetwork | AzureSiteRecovery | 443 | Allow |
| Azure_EventHub_AustraliaEast_OutBound | 1010 | VirtualNetwork | EventHub.AUE | 443 | Allow |
| Azure_EventHub_AustraliaSouthEast_OutBound | 1011 | VirtualNetwork | EventHub.AUSE | 443 | Allow |
| EXPDC_Infrastructure_DC_Shared_OutBound | 1040 | VirtualNetwork | On-prem ranges | * | Allow |
| Default_Deny_OutBound_Override | 4096 | * | * | * | **Deny** |

## Cost Estimation

| Component | Estimated Cost |
|-----------|----------------|
| Defender Servers P2 | ~$15/VM/month |
| Defender Storage | ~$0.02/10k transactions |
| Sentinel ingestion | ~$2.76/GB |
| Key Vault operations | ~$0.03/10k ops |
| Private Endpoint | ~$7.30/month |

## Troubleshooting

### Error: Remote state not found

```
Error: Unable to find remote state
```

**Solution:** Ensure management and connectivity orchestrators are deployed first.

### Error: Key Vault name already exists

```
Error: Key Vault with name 'xxx' already exists
```

**Solution:** Key Vault names are globally unique. Change `key_vault_name` in tfvars.

### Error: InvalidLicense for Sentinel connector

```
Error: The data connector requires license
```

**Solution:** Disable the connector or ensure appropriate license is active.

## CAF Compliance

This orchestrator implements:

- ✅ Centralized security monitoring (Defender + Sentinel)
- ✅ Secrets management with RBAC (Key Vault)
- ✅ Private connectivity (Private Endpoints)
- ✅ Network micro-segmentation (NSG baseline rules)
- ✅ Audit logging (Diagnostic Settings)
- ✅ Multi-subscription security baseline

## Related Documentation

- [Azure Verified Modules - Key Vault](https://registry.terraform.io/modules/Azure/avm-res-keyvault-vault)
- [Azure Verified Modules - NSG](https://registry.terraform.io/modules/Azure/avm-res-network-networksecuritygroup)
- [Microsoft Defender for Cloud](https://docs.microsoft.com/azure/defender-for-cloud/)
- [Microsoft Sentinel](https://docs.microsoft.com/azure/sentinel/)

## License

This orchestrator is part of the Azure Landing Zone CAF project.
