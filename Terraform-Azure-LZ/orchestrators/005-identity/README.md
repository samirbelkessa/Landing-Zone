# 05-Identity Orchestrator

## Overview

This orchestrator deploys **RBAC Role Assignments** and optionally **User Assigned Managed Identities** following Azure CAF best practices.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         05-IDENTITY ORCHESTRATOR                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         ROOT MG (intelly)                            │   │
│  │                                                                      │   │
│  │  intelly-platform-admins ──────► Owner                              │   │
│  │  intelly-security-admins ──────► Security Admin                     │   │
│  │  intelly-billing-readers ──────► Billing Reader                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              │                                              │
│      ┌───────────────────────┼───────────────────────┐                     │
│      ▼                       ▼                       ▼                     │
│  ┌────────────┐      ┌──────────────┐       ┌──────────────┐              │
│  │  Platform  │      │Landing Zones │       │   Sandbox    │              │
│  ├────────────┤      ├──────────────┤       ├──────────────┤              │
│  │ NetOps:    │      │   (below)    │       │ sandbox-users│              │
│  │ Network    │      │              │       │ Contributor  │              │
│  │ Contributor│      │              │       │              │              │
│  └────────────┘      └──────────────┘       └──────────────┘              │
│                              │                                              │
│      ┌───────────────────────┼───────────────────────┐                     │
│      ▼                       ▼                       ▼                     │
│  ┌────────────┐      ┌──────────────┐       ┌──────────────┐              │
│  │ Corp-Prod  │      │ Corp-NonProd │       │ Online-Prod  │              │
│  ├────────────┤      ├──────────────┤       ├──────────────┤              │
│  │ Owners     │      │ Owners       │       │ Owners       │              │
│  │ Contributors│     │ Contributors │       │ Contributors │              │
│  │ Readers    │      │              │       │ Readers      │              │
│  └────────────┘      └──────────────┘       └──────────────┘              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Prerequisites

### 1. Deployed Orchestrators

| Orchestrator | Required | Purpose |
|--------------|----------|---------|
| 01-foundation | ✅ Yes | Management Group IDs |

### 2. Entra ID Groups (Pre-created)

#### Platform Groups
| Group Name | Purpose |
|------------|---------|
| `intelly-platform-admins` | Platform administrators |
| `intelly-security-admins` | Security operations team |
| `intelly-network-admins` | Network operations team |
| `intelly-billing-readers` | Finance/FinOps team |

#### Landing Zone Groups - Corp
| Group Name | Purpose |
|------------|---------|
| `intelly-corp-prod-owners` | Corp Prod LZ owners |
| `intelly-corp-prod-contributors` | Corp Prod application teams |
| `intelly-corp-prod-readers` | Corp Prod read-only access |
| `intelly-corp-nonprod-owners` | Corp NonProd LZ owners |
| `intelly-corp-nonprod-contributors` | Corp NonProd application teams |

#### Landing Zone Groups - Online
| Group Name | Purpose |
|------------|---------|
| `intelly-online-prod-owners` | Online Prod LZ owners |
| `intelly-online-prod-contributors` | Online Prod application teams |
| `intelly-online-prod-readers` | Online Prod read-only access |
| `intelly-online-nonprod-owners` | Online NonProd LZ owners |
| `intelly-online-nonprod-contributors` | Online NonProd application teams |

#### Sandbox Groups
| Group Name | Purpose |
|------------|---------|
| `intelly-sandbox-users` | Developers for sandbox |

### 3. Permissions

The identity running Terraform requires:
- **User Access Administrator** on Root Management Group
- **Directory.Read.All** in Entra ID (to lookup groups)

## Modules Used

| Module | Source | Version |
|--------|--------|---------|
| Role Assignments | `Azure/avm-ptn-authorization-roleassignment/azurerm` | ~> 0.2 |
| Managed Identities | `Azure/avm-res-managedidentity-userassignedidentity/azurerm` | ~> 0.3 |

## Usage

### Basic Deployment (Role Assignments Only)

```bash
# Initialize
terraform init

# Plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan
```

### Enable Managed Identities

1. Update `terraform.tfvars`:

```hcl
deploy_managed_identities = true

managed_identities = {
  terraform-platform = {
    name        = "uami-terraform-platform-aue-001"
    description = "CI/CD Terraform for Landing Zone deployment"
    role_assignments = {
      owner-root = {
        scope_type = "management_group"
        scope_name = "intelly"
        role_name  = "Owner"
      }
    }
  }
}
```

2. Re-apply:

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

## Configuration

### Role Assignments

```hcl
role_assignments = {
  # Assignment key (unique identifier)
  platform-admins-root = {
    group_display_name = "intelly-platform-admins"  # Entra ID group name
    scope_type         = "management_group"         # or "subscription"
    scope_name         = "intelly"                  # MG name from foundation
    role_name          = "Owner"                    # Azure built-in role
    description        = "Platform administrators"  # Optional
  }
}
```

### Supported Scope Types

| Type | Parameter | Example |
|------|-----------|---------|
| Management Group | `scope_name` | `"intelly"`, `"intelly-platform"` |
| Subscription | `scope_id` | `"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"` |

### Azure Built-in Roles (Common)

| Role | Description |
|------|-------------|
| Owner | Full access including RBAC |
| Contributor | Manage resources (no RBAC) |
| Reader | View resources |
| Security Admin | Manage security policies |
| Network Contributor | Manage networks |
| Billing Reader | View billing information |
| User Access Administrator | Manage user access to resources |

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `tenant_id` | Azure Tenant ID | `string` | Yes |
| `identity_subscription_id` | Identity subscription ID | `string` | Yes |
| `terraform_state_subscription_id` | Terraform state subscription ID | `string` | Yes |
| `remote_state_resource_group` | Remote state resource group | `string` | Yes |
| `remote_state_storage_account` | Remote state storage account | `string` | Yes |
| `location` | Azure region | `string` | No (default: australiaeast) |
| `owner` | Owner email for tags | `string` | Yes |
| `cost_center` | Cost center for tags | `string` | Yes |
| `deploy_role_assignments` | Deploy role assignments | `bool` | No (default: true) |
| `deploy_managed_identities` | Deploy managed identities | `bool` | No (default: false) |
| `role_assignments` | Map of role assignments | `map(object)` | No |
| `managed_identities` | Map of managed identities | `map(object)` | No |

## Outputs

| Name | Description |
|------|-------------|
| `role_assignments_summary` | Summary of role assignments created |
| `role_assignments_count` | Number of role assignments |
| `managed_identity_ids` | Map of managed identity resource IDs |
| `managed_identity_principal_ids` | Map of managed identity principal IDs |
| `managed_identity_client_ids` | Map of managed identity client IDs |
| `deployment_status` | Status of each module |
| `identity_config` | Complete configuration for downstream |

## Dependencies

```
┌─────────────────┐
│  01-foundation  │
│                 │
│  Outputs:       │
│  • all_mg_ids   │
│  • root_mg_id   │
│  • etc.         │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  05-identity    │
│                 │
│  Creates:       │
│  • Role Assign. │
│  • UAMIs        │
└─────────────────┘
```

## CAF Compliance

This orchestrator follows Azure CAF recommendations:

- ✅ RBAC at Management Group level (inheritance)
- ✅ Entra ID Groups for role assignments (not individual users)
- ✅ Azure built-in roles (no custom roles unless necessary)
- ✅ Least privilege principle
- ✅ Managed Identities for workloads (optional)

## Troubleshooting

### Error: Group not found

```
Error: Could not find group with display name "intelly-platform-admins"
```

**Solution:** Ensure the Entra ID group exists and is security-enabled.

### Error: Insufficient permissions

```
Error: Authorization failed for principal
```

**Solution:** Ensure the executing identity has `User Access Administrator` on Root MG.

### Error: Management Group not found

```
Error: scope is null for assignment "platform-admins-root"
```

**Solution:** Verify `01-foundation` is deployed and MG names match in `terraform.tfvars`.
