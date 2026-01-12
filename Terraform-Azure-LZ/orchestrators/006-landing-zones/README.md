# 🏗️ Azure Landing Zone - Landing Zones Orchestrator (06)

## 📋 Overview

This orchestrator deploys **Landing Zone subscriptions** using the Azure Verified Module (AVM) [avm-ptn-alz-sub-vending](https://registry.terraform.io/modules/Azure/avm-ptn-alz-sub-vending/azure/latest).

### 🔄 Deployment Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| **🌱 Greenfield** | Create NEW Azure subscriptions | New projects, clean deployments |
| **🏭 Brownfield** | Use EXISTING Azure subscriptions | Migrations, existing workloads |

Both modes can be mixed in the same deployment!

### What Each Landing Zone Gets

- **[Greenfield]** New subscription creation OR **[Brownfield]** Existing subscription
- Subscription placement in Management Group (by archetype)
- Virtual Network (Spoke) with configurable subnets
- Bi-directional peering to Hub VNet
- UDR routing through Azure Firewall
- DNS configuration (Hub DNS Resolver)
- Private DNS Zone links
- Resource Groups
- RBAC assignments
- Budget alerts

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           LANDING ZONES                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────────┐  ┌──────────────────────┐  ┌───────────────────┐ │
│  │  🌱 GREENFIELD       │  │  🏭 BROWNFIELD       │  │ 🌱 GREENFIELD     │ │
│  │  webapp-online-prod  │  │  erp-corp-prod       │  │ innovation-sandbox│ │
│  │  ─────────────────── │  │  ────────────────    │  │ ───────────────── │ │
│  │  NEW Subscription    │  │  Existing Sub        │  │ NEW Sub (DevTest) │ │
│  │  10.10.0.0/24        │  │  10.11.0.0/23        │  │ 10.100.0.0/24     │ │
│  └──────────┬───────────┘  └──────────┬───────────┘  └─────────┬─────────┘ │
│             │                         │                        │           │
│             └─────────────────────────┼────────────────────────┘           │
│                                       │ Peering                            │
│                                       ▼                                    │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │                       HUB VNET (10.0.0.0/22)                          │ │
│  │  Azure Firewall │ VPN Gateway │ Bastion │ Private DNS Zones          │ │
│  └──────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 📁 File Structure

```
06-landing-zones/
├── versions.tf          # Terraform and provider constraints
├── providers.tf         # Azure provider configuration
├── data.tf              # Remote state references
├── variables.tf         # Input variables (Greenfield + Brownfield)
├── locals.tf            # Computed values and transformations
├── main.tf              # AVM lz-vending module
├── dns_links.tf         # Private DNS Zone VNet links
├── outputs.tf           # Orchestrator outputs
├── terraform.tfvars     # Landing Zone configurations
└── README.md            # This documentation
```

## 🚀 Deployment Guide

### Prerequisites

1. **Terraform** >= 1.5.0
2. **Azure CLI** authenticated with appropriate permissions
3. **For Greenfield**: Billing Account Owner or Enrollment Account Owner
4. **Deployed orchestrators:**
   - ✅ 01-foundation (Management Groups)
   - ✅ 02-governance (Policies)
   - ✅ 03-management (Log Analytics)
   - ✅ 04-connectivity (Hub VNets, Firewall, DNS)

### Permissions Required

| Mode | Required Permissions |
|------|---------------------|
| **Greenfield** | Owner on Billing Scope (EA Enrollment Account or MCA Billing Profile) |
| **Brownfield** | Owner on target subscription |
| **Both** | Management Group Contributor for MG placement |

### Deployment Steps

```bash
# Navigate to orchestrator directory
cd orchestrators/06-landing-zones

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan -out=tfplan

# Apply deployment
terraform apply tfplan
```

## ⚙️ Configuration

### 🌱 Greenfield Mode (Create New Subscription)

```hcl
landing_zones = {
  "new-app-prod" = {
    # GREENFIELD: Create new subscription
    create_subscription       = true
    subscription_alias        = "sub-newapp-prod-aue"
    subscription_display_name = "NewApp Production Australia"
    subscription_workload     = "Production"  # or "DevTest"
    # subscription_billing_scope = "..."      # Optional, uses default_billing_scope

    # Archetype determines Management Group and policies
    archetype     = "online-prod"
    location      = "australiaeast"
    address_space = ["10.10.0.0/24"]
    
    subnets = {
      app = { address_prefix = "10.10.0.0/26" }
      # ...
    }
    
    tags = {
      Application = "New App"
      Owner       = "team@company.com"
      CostCenter  = "IT-001"
    }
  }
}
```

### 🏭 Brownfield Mode (Use Existing Subscription)

```hcl
landing_zones = {
  "existing-app-prod" = {
    # BROWNFIELD: Use existing subscription
    subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

    archetype     = "corp-prod"
    location      = "australiaeast"
    address_space = ["10.11.0.0/24"]
    
    subnets = {
      app = { address_prefix = "10.11.0.0/26" }
      # ...
    }
    
    tags = {
      Application = "Existing App"
      Owner       = "team@company.com"
      CostCenter  = "IT-002"
    }
  }
}
```

### Billing Scope Configuration (Greenfield)

```hcl
# Global default billing scope
default_billing_scope = "/providers/Microsoft.Billing/billingAccounts/1234567/enrollmentAccounts/123456"

# Or per Landing Zone override
landing_zones = {
  "app1" = {
    create_subscription        = true
    subscription_billing_scope = "/providers/Microsoft.Billing/billingAccounts/7654321/enrollmentAccounts/654321"
    # ...
  }
}
```

### Billing Scope Formats

| Agreement | Format |
|-----------|--------|
| **EA** | `/providers/Microsoft.Billing/billingAccounts/{billingAccountId}/enrollmentAccounts/{enrollmentAccountId}` |
| **MCA** | `/providers/Microsoft.Billing/billingAccounts/{billingAccountId}/billingProfiles/{billingProfileId}/invoiceSections/{invoiceSectionId}` |
| **MPA** | `/providers/Microsoft.Billing/billingAccounts/{billingAccountId}/customers/{customerId}` |

## 📊 Landing Zone Archetypes

| Archetype | Management Group | Key Policies | Backup |
|-----------|------------------|--------------|--------|
| `online-prod` | intelly-online-prod | WAF required, HTTPS enforced | GRS |
| `online-nonprod` | intelly-online-nonprod | WAF recommended, HTTPS enforced | LRS |
| `corp-prod` | intelly-corp-prod | No public IPs, Private Endpoints required | GRS |
| `corp-nonprod` | intelly-corp-nonprod | No public IPs | LRS |
| `sandbox` | intelly-sandbox | Audit only, Limited SKUs, Expiration tag | LRS |

## 📤 Outputs

### Key Outputs

| Output | Description |
|--------|-------------|
| `deployment_summary` | Count of Greenfield vs Brownfield LZs |
| `greenfield_subscriptions` | Newly created subscription details |
| `brownfield_subscriptions` | Existing subscription details |
| `subscription_ids` | All subscription IDs (unified) |
| `virtual_network_ids` | VNet resource IDs |
| `subnet_ids` | Subnet resource IDs by Landing Zone |
| `workload_deployment_info` | Info for workload teams |

### Getting Subscription IDs

```hcl
# After deployment, get all subscription IDs
output "all_subscriptions" {
  value = module.landing_zones.subscription_ids
}

# Output example:
# {
#   "webapp-online-prod"    = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"  # NEW
#   "erp-corp-prod"         = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"  # Existing
#   "dataplatform-corp-prod"= "cccccccc-cccc-cccc-cccc-cccccccccccc"  # NEW
# }
```

## 🔗 Subnet Configuration Options

| Option | Description | Default |
|--------|-------------|---------|
| `address_prefix` | Subnet CIDR | Required |
| `private_endpoint_network_policies` | `Enabled` or `Disabled` | `Enabled` |
| `service_endpoints` | List of service endpoints | `[]` |
| `delegation` | Subnet delegation config | `null` |
| `route_table_id` | Override route table | Hub UDR |
| `network_security_group_id` | Associate NSG | `null` |

### Delegation Example

```hcl
subnets = {
  databricks_public = {
    address_prefix = "10.20.0.0/24"
    delegation = {
      name         = "databricks-delegation"
      service_name = "Microsoft.Databricks/workspaces"
      actions      = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}
```

## 📊 IP Address Allocation

| Landing Zone | Mode | Address Space | Region |
|--------------|------|---------------|--------|
| Hub Primary | - | 10.0.0.0/22 | australiaeast |
| Hub DR | - | 10.1.0.0/22 | australiasoutheast |
| webapp-online-prod | 🌱 Greenfield | 10.10.0.0/24 | australiaeast |
| erp-corp-prod | 🏭 Brownfield | 10.11.0.0/23 | australiaeast |
| dataplatform-corp-prod | 🌱 Greenfield | 10.20.0.0/22 | australiaeast |
| erp-corp-nonprod | 🏭 Brownfield | 10.12.0.0/24 | australiaeast |
| innovation-sandbox | 🌱 Greenfield | 10.100.0.0/24 | australiaeast |

## ⚠️ Important Notes

### Greenfield Mode

1. **Billing Scope Required**: You must have Owner permissions on the billing scope
2. **Subscription Alias**: Must be unique across your tenant
3. **Workload Type**: `Production` or `DevTest` (DevTest has discounted pricing)
4. **Subscription Creation Time**: May take 1-5 minutes

### Brownfield Mode

1. **Subscription Must Exist**: The subscription_id must be valid
2. **Permissions**: You need Owner on the subscription
3. **Existing Resources**: The module will manage new resources, not modify existing ones

### Both Modes

1. **Management Group Placement**: Subscriptions are moved to the archetype MG
2. **Policies Inherited**: Policies from the MG hierarchy are automatically applied
3. **Hub Peering**: Bi-directional peering is created with the Hub VNet
4. **DNS**: Spoke VNets use Hub DNS servers automatically

## 🔄 Adding New Landing Zones

1. Add new entry to `landing_zones` map in `terraform.tfvars`
2. Choose mode: `create_subscription = true` (Greenfield) or `subscription_id = "..."` (Brownfield)
3. Select appropriate archetype
4. Define address space (no overlap!)
5. Configure subnets based on workload requirements
6. Run `terraform plan` and `terraform apply`

## 🗑️ Removing Landing Zones

### Brownfield
```bash
# Simply remove from terraform.tfvars and apply
terraform apply
```

### Greenfield (Subscription Deletion)
⚠️ **Warning**: Deleting a Greenfield subscription will:
1. Cancel the subscription (moves to "Disabled" state)
2. After 90 days, permanently delete all resources

```bash
# Remove from terraform.tfvars
# Then apply with target to remove specific LZ
terraform apply
```

## 📚 References

- [AVM Subscription Vending Module](https://registry.terraform.io/modules/Azure/avm-ptn-alz-sub-vending/azure/latest)
- [Azure Subscription Creation](https://docs.microsoft.com/azure/cost-management-billing/manage/programmatically-create-subscription)
- [Azure Landing Zone Architecture](https://aka.ms/alz)
- [Hub-Spoke Network Topology](https://docs.microsoft.com/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
