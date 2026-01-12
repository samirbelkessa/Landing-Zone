# F00 - Terraform Backend

Simple Storage Account for centralized Terraform state files.

## Purpose

This module creates a single storage account in the **Management Subscription** where all orchestrators store their tfstate files. Each orchestrator uses a different `key` in the same container.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      Management Subscription                                 │
│                      (ef7442e9-4d15-4a28-939a-f428a3d59487)                  │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                 rg-terraform-state-aue                                 │  │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │  │
│  │  │              stlzterraformstateaue (GRS)                         │  │  │
│  │  │  ┌───────────────────────────────────────────────────────────┐  │  │  │
│  │  │  │                  tfstate container                         │  │  │  │
│  │  │  │  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐  │  │  │  │
│  │  │  │  │governance │ │management │ │connectiv. │ │ identity  │  │  │  │  │
│  │  │  │  │ .tfstate  │ │ .tfstate  │ │ .tfstate  │ │ .tfstate  │  │  │  │  │
│  │  │  │  └───────────┘ └───────────┘ └───────────┘ └───────────┘  │  │  │  │
│  │  │  └───────────────────────────────────────────────────────────┘  │  │  │
│  │  └─────────────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Usage

### 1. Deploy the backend first

```hcl
# This is a root module, not called as a child module
# Deploy directly with terraform apply

# terraform.tfvars
management_subscription_id = "ef7442e9-4d15-4a28-939a-f428a3d59487"
resource_group_name        = "rg-terraform-state-aue"
storage_account_name       = "stlzterraformstateaue"
location                   = "australiaeast"

tags = {
  Environment = "Management"
  Owner       = "Platform Team"
}
```

### 2. Configure backend in each orchestrator

After deploying the backend, configure other orchestrators:

```hcl
# versions.tf in each orchestrator
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-aue"
    storage_account_name = "stlzterraformstateaue"
    container_name       = "tfstate"
    key                  = "governance.tfstate"  # Unique per orchestrator
  }
}
```

### 3. Read other orchestrator states (optional)

```hcl
# Read governance state from connectivity orchestrator
data "terraform_remote_state" "governance" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-terraform-state-aue"
    storage_account_name = "stlzterraformstateaue"
    container_name       = "tfstate"
    key                  = "governance.tfstate"
  }
}

# Use outputs from governance
locals {
  root_mg_id = data.terraform_remote_state.governance.outputs.root_management_group_id
}
```

## State Keys Convention

| Orchestrator | Key |
|--------------|-----|
| Governance (F01, G01-G04) | `governance.tfstate` |
| Management (M01-M08) | `management.tfstate` |
| Connectivity (C01-C13) | `connectivity.tfstate` |
| Identity (I01-I04) | `identity.tfstate` |
| Security (S01-S06) | `security.tfstate` |
| Landing Zone (L01-L05) | `landingzone.tfstate` |

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| management_subscription_id | Subscription ID of the Management subscription | string | yes | - |
| resource_group_name | Name of the resource group | string | yes | - |
| storage_account_name | Name of the storage account (3-24 lowercase alphanumeric) | string | yes | - |
| location | Azure region | string | no | australiaeast |
| container_name | Name of the blob container | string | no | tfstate |
| tags | Tags to apply | map(string) | no | {} |

## Outputs

| Name | Description |
|------|-------------|
| resource_group_name | Name of the resource group |
| resource_group_id | ID of the resource group |
| storage_account_name | Name of the storage account |
| storage_account_id | ID of the storage account |
| primary_blob_endpoint | Primary blob endpoint URL |
| container_name | Name of the blob container |
| container_id | ID of the blob container |
| backend_config | Complete backend config object |

## Security Features

- **GRS replication**: Geo-redundant storage for disaster recovery
- **TLS 1.2**: Minimum TLS version enforced
- **Versioning**: Enabled for state file history
- **Soft delete**: 30 days retention for accidental deletion recovery
- **Private access**: No public blob access
- **Prevent destroy**: Lifecycle protection on storage account

## Bootstrap Process

Since this module creates the backend, it cannot use the backend itself. Deploy it with local state first:

```bash
# Initial deployment (local state)
terraform init
terraform apply

# After deployment, migrate your local state if needed
terraform init -migrate-state -backend-config="key=backend.tfstate"
```

## Why Management Subscription?

The state storage belongs in the Management subscription because:

| Reason | Explanation |
|--------|-------------|
| **Centralization** | All management resources in one place |
| **Security** | Restricted access to platform team only |
| **CAF Alignment** | Microsoft recommended practice |
| **Simplified RBAC** | Single scope for permissions |
| **Cost Tracking** | Platform costs tracked together |
