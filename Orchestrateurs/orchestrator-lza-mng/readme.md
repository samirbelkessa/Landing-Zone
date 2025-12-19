# Management Layer Orchestrator

## Description

Orchestrator for deploying the Management layer modules (M01-M08) of the Azure Landing Zone. This orchestrator follows an incremental deployment approach, allowing you to test each module before enabling the next.

## Deployment Phases

| Phase | Module | Description | Prerequisites |
|-------|--------|-------------|---------------|
| 1 | M01 | Log Analytics Workspace | None |
| 2 | M02 | Automation Account | M01 |
| 3 | M03 | Action Groups | M01 |
| 4 | M04 | Monitor Alerts | M01, M03 |
| 5 | M07 | Data Collection Rules | M01 |
| 5 | M08 | Diagnostics Storage | None |
| 6 | M06 | Update Management | M01, M02 |

## Quick Start - Phase 1 (M01)
```bash
# Initialize
cd orchestrators/management
terraform init

# Plan M01 only
terraform plan -var-file="terraform.tfvars"

# Apply M01
terraform apply -var-file="terraform.tfvars"

# Verify
terraform output m01_log_analytics_configuration
```

## Enabling Phase 2 (M02)

After validating M01:

1. Edit `terraform.tfvars`:
```hcl
deploy_m02_automation = true
```

2. Apply:
```bash
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

## Directory Structure
```
orchestrators/management/
├── versions.tf          # Terraform version constraints
├── providers.tf         # Azure provider configuration
├── variables.tf         # Input variables
├── locals.tf            # Local calculations
├── main.tf              # Module calls
├── outputs.tf           # Consolidated outputs
├── terraform.tfvars     # Australia project values
└── README.md            # This file
```

## Validation Commands
```bash
# Format check
terraform fmt -check -recursive

# Validate configuration
terraform validate

# Security scan (optional)
tfsec .

# Cost estimation (optional)
infracost breakdown --path .
```

## Outputs

After deployment, key outputs are available:
```bash
# Log Analytics Workspace ID
terraform output m01_log_analytics_id

# Workspace GUID (for agent configuration)
terraform output m01_log_analytics_workspace_id

# Full configuration
terraform output m01_log_analytics_configuration

# Deployment status
terraform output deployment_status
```

## Troubleshooting

### Module Not Deploying
Check that the enable flag is set:
```hcl
deploy_m01_log_analytics = true
```

### Dependency Errors
Modules must be enabled in order. You cannot enable M02 without M01.

### Resource Group Already Exists
Set `create_resource_group = false` and ensure the RG name matches.