# Orchestrator: 01-Foundation

## Description

This orchestrator deploys the **Management Group hierarchy** (module F01) for an Azure Landing Zone following the Cloud Adoption Framework (CAF).

**This orchestrator creates `foundation.tfstate` which is read by ALL other orchestrators.**

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         01-FOUNDATION                                        │
│                         (foundation.tfstate)                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ F01 - Management Groups                                              │   │
│   │                                                                      │   │
│   │ Creates:                                                             │   │
│   │ ├── Root (intelly)                                                   │   │
│   │ │   ├── Platform                                                     │   │
│   │ │   │   ├── Management                                               │   │
│   │ │   │   ├── Connectivity                                             │   │
│   │ │   │   └── Identity                                                 │   │
│   │ │   ├── Landing Zones                                                │   │
│   │ │   │   ├── Corp-Prod                                                │   │
│   │ │   │   ├── Corp-NonProd                                             │   │
│   │ │   │   ├── Online-Prod                                              │   │
│   │ │   │   ├── Online-NonProd                                           │   │
│   │ │   │   └── Sandbox                                                  │   │
│   │ │   └── Decommissioned                                               │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ Outputs (via tfstate)
                                    │
          ┌─────────────────────────┼─────────────────────────┐
          │                         │                         │
          ▼                         ▼                         ▼
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  02-governance   │     │  03-management   │     │  04-connectivity │
│  (reads tfstate) │     │  (reads tfstate) │     │  (reads tfstate) │
└──────────────────┘     └──────────────────┘     └──────────────────┘
```

## Prerequisites

- **Terraform**: >= 1.5.0
- **AzureRM Provider**: >= 3.80.0
- **Permissions**: Owner or User Access Administrator at tenant root level
- **Azure AD Tenant ID**: Required for `root_parent_id`

## Usage

### 1. Configure Backend (Optional but Recommended)

Edit `versions.tf` to configure your backend:

```hcl
backend "azurerm" {
  resource_group_name  = "rg-terraform-state"
  storage_account_name = "stterraformstate"
  container_name       = "tfstate"
  key                  = "foundation.tfstate"
}
```

### 2. Create terraform.tfvars

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
root_parent_id = "your-tenant-id"
root_name      = "Your Organization"
root_id        = "yourorg"
```

### 3. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 4. Verify Outputs

```bash
terraform output all_mg_ids
terraform output deployment_flags
```

## Outputs

| Output | Description | Used By |
|--------|-------------|---------|
| `root_mg_id` | Root management group ID | 02-governance |
| `all_mg_ids` | Map of all MG IDs | 02-governance, 04-connectivity |
| `deployment_flags` | Static boolean flags | 02-governance (for G03) |
| `primary_location` | Primary Azure region | 03-management, 04-connectivity |
| `root_id` | Organization ID prefix | All orchestrators (naming) |

## Files

```
01-foundation/
├── versions.tf              # Terraform and provider constraints
├── provider.tf              # Azure provider configuration
├── variables.tf             # Input variables
├── main.tf                  # Calls module F01
├── outputs.tf               # Outputs for other orchestrators
├── terraform.tfvars.example # Example configuration
└── README.md                # This file
```

## Next Steps

After deploying Foundation, deploy the other orchestrators in order:

```bash
# 1. Foundation (this orchestrator) - DONE
cd orchestrators/01-foundation && terraform apply

# 2. Governance (policies)
cd ../02-governance && terraform apply

# 3. Management (Log Analytics, etc.)
cd ../03-management && terraform apply

# 4. Connectivity (Hub network)
cd ../04-connectivity && terraform apply
```

## Related Modules

- **F01** - management-groups: Creates the MG hierarchy (called by this orchestrator)

## Related Orchestrators

- **02-governance**: Deploys G01-G04 (reads `foundation.tfstate`)
- **03-management**: Deploys M01-M08 (reads `foundation.tfstate`)
- **04-connectivity**: Deploys C01-C13 (reads `foundation.tfstate` + `management.tfstate`)
