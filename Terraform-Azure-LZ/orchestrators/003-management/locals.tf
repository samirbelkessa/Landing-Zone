# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Locals - Orchestrator 03-Management                                           ║
# ║ Uses outputs from foundation.tfstate and governance.tfstate                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

locals {
  # ════════════════════════════════════════════════════════════════════════════
  # Foundation Outputs (from remote state)
  # ════════════════════════════════════════════════════════════════════════════
  module_ref = "c4ed1ec2172950bba7bcabacf70187e0ddab5533"
  module_repo = "git::https://github.com/samirbelkessa/Landing-Zone.git"
  foundation  = data.terraform_remote_state.foundation.outputs
  governance  = data.terraform_remote_state.governance.outputs

  # Locations from foundation
  primary_location   = local.foundation.primary_location
  secondary_location = local.foundation.secondary_location
  allowed_regions    = local.foundation.allowed_regions

  # Tags from foundation
  common_tags = local.foundation.common_tags

  # Tenant info
  tenant_id = local.foundation.tenant_id
  root_id   = local.foundation.root_id

  # ════════════════════════════════════════════════════════════════════════════
  # Location Abbreviations for F02
  # ════════════════════════════════════════════════════════════════════════════

  location_abbrev = {
    "australiaeast"      = "aue"
    "australiasoutheast" = "aus"
    "westeurope"         = "weu"
    "northeurope"        = "neu"
    "eastus"             = "eus"
    "westus2"            = "wus2"
  }

  # Derived from foundation
  primary_region   = lookup(local.location_abbrev, local.primary_location, "aue")
  secondary_region = lookup(local.location_abbrev, local.secondary_location, "aus")

  # ════════════════════════════════════════════════════════════════════════════
  # Environment Mapping for F03 Tags
  # ════════════════════════════════════════════════════════════════════════════

  environment_mapping = {
    "prod"    = "Production"
    "nonprod" = "PreProduction"
    "dev"     = "Development"
    "test"    = "Test"
    "uat"     = "PreProduction"
    "stg"     = "PreProduction"
    "sandbox" = "Sandbox"
  }

  f03_environment = lookup(local.environment_mapping, var.environment, "Production")

  # ════════════════════════════════════════════════════════════════════════════
  # Resource Group
  # ════════════════════════════════════════════════════════════════════════════

  rg_name     = var.resource_group_name
  rg_location = local.primary_location

  # ════════════════════════════════════════════════════════════════════════════
  # Default Runbooks for M02
  # ════════════════════════════════════════════════════════════════════════════

  default_runbooks = var.deploy_default_runbooks ? {
    "Start-TaggedVMs" = {
      runbook_type = "PowerShell"
      description  = "Start VMs with AutoStart=true tag"
      content      = <<-EOT
        param(
          [string]$TagName = "AutoStart",
          [string]$TagValue = "true"
        )
        Connect-AzAccount -Identity
        $VMs = Get-AzVM | Where-Object { $_.Tags[$TagName] -eq $TagValue }
        foreach ($VM in $VMs) {
          Write-Output "Starting VM: $($VM.Name)"
          Start-AzVM -Name $VM.Name -ResourceGroupName $VM.ResourceGroupName -NoWait
        }
        Write-Output "Start command sent to $($VMs.Count) VMs"
      EOT
    }
    "Stop-TaggedVMs" = {
      runbook_type = "PowerShell"
      description  = "Stop VMs with AutoStop=true tag"
      content      = <<-EOT
        param(
          [string]$TagName = "AutoStop",
          [string]$TagValue = "true"
        )
        Connect-AzAccount -Identity
        $VMs = Get-AzVM | Where-Object { $_.Tags[$TagName] -eq $TagValue }
        foreach ($VM in $VMs) {
          Write-Output "Stopping VM: $($VM.Name)"
          Stop-AzVM -Name $VM.Name -ResourceGroupName $VM.ResourceGroupName -Force -NoWait
        }
        Write-Output "Stop command sent to $($VMs.Count) VMs"
      EOT
    }
    "Cleanup-OldSnapshots" = {
      runbook_type = "PowerShell72"
      description  = "Remove snapshots older than 30 days"
      content      = <<-EOT
        param([int]$RetentionDays = 30)
        Connect-AzAccount -Identity
        $threshold = (Get-Date).AddDays(-$RetentionDays)
        $snapshots = Get-AzSnapshot | Where-Object { $_.TimeCreated -lt $threshold }
        Write-Output "Found $($snapshots.Count) snapshots older than $RetentionDays days"
        foreach ($snap in $snapshots) {
          Write-Output "Removing snapshot: $($snap.Name)"
          Remove-AzSnapshot -ResourceGroupName $snap.ResourceGroupName -SnapshotName $snap.Name -Force
        }
        Write-Output "Cleanup complete"
      EOT
    }
  } : {}

  # ════════════════════════════════════════════════════════════════════════════
  # Default Schedules for M02
  # ════════════════════════════════════════════════════════════════════════════

  default_schedules = var.deploy_default_schedules ? tomap({
    "weekday-start-7am-aest" = {
      description = "Start VMs at 7 AM AEST weekdays"
      start_time  = "2026-01-19T07:00:00+10:00"
      frequency   = "Week"
      interval    = 1
      timezone    = "Australia/Sydney"
      week_days   = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
      month_days  = []
      expiry_time = null
    }
    "weekday-stop-7pm-aest" = {
      description = "Stop VMs at 7 PM AEST weekdays"
      start_time  = "2026-01-19T19:00:00+10:00"
      frequency   = "Week"

      interval    = 1
      timezone    = "Australia/Sydney"
      week_days   = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
      month_days  = []
      expiry_time = null
    }
    "monthly-cleanup-1st" = {
      description = "Monthly cleanup on 1st day at 2 AM AEST"
      start_time  = "2026-02-01T02:00:00+10:00"
      frequency   = "Month"
      interval    = 1
      timezone    = "Australia/Sydney"
      week_days   = []
      month_days  = [1]
      expiry_time = null
    }
  }) : tomap({})

  # ════════════════════════════════════════════════════════════════════════════
  # Dependency Validation
  # ════════════════════════════════════════════════════════════════════════════

  m02_can_deploy                  = var.deploy_m02_automation && var.deploy_m01_log_analytics
  m03_can_deploy                  = var.deploy_m03_action_groups
  m04_can_deploy                  = var.deploy_m04_alerts && var.deploy_m01_log_analytics && var.deploy_m03_action_groups
  m06_can_deploy                  = var.deploy_m06_update_management
  m07_can_deploy                  = var.deploy_m07_dcr && var.deploy_m01_log_analytics
  m08_can_deploy                  = var.deploy_m08_diagnostics_storage
  m08_self_diagnostics_can_deploy = var.deploy_m08_diagnostics_storage && var.deploy_m01_log_analytics && var.enable_m08_self_diagnostics

  # ════════════════════════════════════════════════════════════════════════════
  # M07 - DATA COLLECTION RULES - LOCAL CONFIGURATIONS
  # ════════════════════════════════════════════════════════════════════════════

  # Resource group name for DCRs (same as M01)
  dcr_resource_group_name = local.rg_name

  # Location from M01 or foundation
  dcr_location = var.deploy_m01_log_analytics ? module.m01_log_analytics[0].outputs_for_m07.location : local.primary_location

  # Workspace resource ID from M01
  dcr_workspace_resource_id = var.deploy_m01_log_analytics ? module.m01_log_analytics[0].outputs_for_m07.workspace_resource_id : null

  # Tags merged from M01 and foundation
  dcr_tags = var.deploy_m01_log_analytics ? merge(
    module.m01_log_analytics[0].tags,
    local.common_tags,
    var.dcr_additional_tags
  ) : merge(
    {
      Environment        = local.f03_environment
      Owner              = var.owner
      CostCenter         = var.cost_center
      Application        = var.application
      Criticality        = var.criticality
      DataClassification = var.data_classification
      ManagedBy          = "Terraform"
      Module             = "M07"
    },
    local.common_tags,
    var.dcr_additional_tags
  )

  # ════════════════════════════════════════════════════════════════════════════
  # KQL Transformations for Cost Optimization
  # ════════════════════════════════════════════════════════════════════════════

  dcr_security_transform_kql = var.enable_dcr_cost_optimization ? (<<-EOT
source
| where EventLevelName in ("Critical", "Error", "Warning")
| extend Environment = "${local.f03_environment}"
| extend CostCenter = "${var.cost_center}"
EOT
  ) : null

  # ════════════════════════════════════════════════════════════════════════════
  # 10 RECOMMENDED DCR CONFIGURATIONS
  # ════════════════════════════════════════════════════════════════════════════

  recommended_dcr_configurations = var.disable_default_dcrs ? tomap({}) : {
    
    # DCR #1: Windows Performance Counters
    "dcr-windows-performance" = {
      location            = local.dcr_location
      resource_group_name = local.dcr_resource_group_name
      description         = "Performance counters for all Windows VMs across all archetypes"
      kind                = "Windows"
      
      destinations = {
        log_analytics = {
          "central-workspace" = {
            workspace_resource_id = local.dcr_workspace_resource_id
            name                  = "central-workspace"
          }
        }
      }
      
      data_flow = [{
        streams      = ["Microsoft-Perf"]
        destinations = ["central-workspace"]
      }]
      
      data_sources = {
        performance_counter = [{
          streams                       = ["Microsoft-Perf"]
          sampling_frequency_in_seconds = var.dcr_windows_perf_sampling_frequency
          counter_specifiers = [
            "\\Processor(_Total)\\% Processor Time",
            "\\Processor(_Total)\\% Privileged Time",
            "\\Memory\\Available MBytes",
            "\\Memory\\% Committed Bytes In Use",
            "\\LogicalDisk(_Total)\\% Free Space",
            "\\LogicalDisk(_Total)\\Avg. Disk sec/Read",
            "\\LogicalDisk(_Total)\\Avg. Disk sec/Write",
            "\\Network Interface(*)\\Bytes Total/sec"
          ]
          name = "perfCounterDataSource"
        }]
      }
      
      tags = {
        DCRType    = "Performance"
        OSType     = "Windows"
        Archetypes = "All"
      }
    }

    # DCR #5: VM Insights Windows
    "dcr-vm-insights-windows" = {
      location            = local.dcr_location
      resource_group_name = local.dcr_resource_group_name
      description         = "VM Insights for Windows - Required for Azure Policy G03 VM Insights assignment"
      kind                = "Windows"
      
      destinations = {
        log_analytics = {
          "central-workspace" = {
            workspace_resource_id = local.dcr_workspace_resource_id
            name                  = "central-workspace"
          }
        }
      }
      
      data_flow = [{
        streams      = ["Microsoft-InsightsMetrics"]
        destinations = ["central-workspace"]
      }]
      
      data_sources = {
        performance_counter = [{
          streams                       = ["Microsoft-InsightsMetrics"]
          sampling_frequency_in_seconds = 60
          counter_specifiers            = ["\\VmInsights\\DetailedMetrics"]
          name                          = "VMInsightsPerfCounters"
        }]
        
        extension = [{
          streams        = ["Microsoft-InsightsMetrics"]
          extension_name = "DependencyAgent"
          name           = "DependencyAgentDataSource"
        }]
      }
      
      tags = {
        DCRType    = "VMInsights"
        OSType     = "Windows"
        Archetypes = "All"
        PolicyG03  = "Required"
      }
    }

    # DCR #6: VM Insights Linux
    "dcr-vm-insights-linux" = {
      location            = local.dcr_location
      resource_group_name = local.dcr_resource_group_name
      description         = "VM Insights for Linux - Required for Azure Policy G03 VM Insights assignment"
      kind                = "Linux"
      
      destinations = {
        log_analytics = {
          "central-workspace" = {
            workspace_resource_id = local.dcr_workspace_resource_id
            name                  = "central-workspace"
          }
        }
      }
      
      data_flow = [{
        streams      = ["Microsoft-InsightsMetrics"]
        destinations = ["central-workspace"]
      }]
      
      data_sources = {
        performance_counter = [{
          streams                       = ["Microsoft-InsightsMetrics"]
          sampling_frequency_in_seconds = 60
          counter_specifiers            = ["\\VmInsights\\DetailedMetrics"]
          name                          = "VMInsightsPerfCounters"
        }]
        
        extension = [{
          streams        = ["Microsoft-InsightsMetrics"]
          extension_name = "DependencyAgent"
          name           = "DependencyAgentDataSource"
        }]
      }
      
      tags = {
        DCRType    = "VMInsights"
        OSType     = "Linux"
        Archetypes = "All"
        PolicyG03  = "Required"
      }
    }
  }

  # Final DCR Configurations (merge recommended + custom)
  all_dcr_configurations = merge(
    local.recommended_dcr_configurations,
    var.dcr_custom_configurations
  )

  link_storage_to_la = var.enable_la_linked_storage && var.deploy_m01_log_analytics && var.deploy_m08_diagnostics_storage

  # ════════════════════════════════════════════════════════════════════════════
  # Deployment Summary
  # ════════════════════════════════════════════════════════════════════════════

  deployment_summary = {
    # From foundation remote state
    primary_location   = local.primary_location
    secondary_location = local.secondary_location
    allowed_regions    = local.allowed_regions
    tenant_id          = local.tenant_id
    root_id            = local.root_id

    # Management configuration
    resource_group_name = local.rg_name
    environment         = var.environment
    f03_environment     = local.f03_environment

    # Module deployment flags
    modules = {
      m01_log_analytics       = var.deploy_m01_log_analytics
      m02_automation          = local.m02_can_deploy
      m03_action_groups       = local.m03_can_deploy
      m04_alerts              = local.m04_can_deploy
      m06_update_management   = local.m06_can_deploy
      m07_dcr                 = local.m07_can_deploy
      m08_diagnostics_storage = local.m08_can_deploy
    }
  }
}
