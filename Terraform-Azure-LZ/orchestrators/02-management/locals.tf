################################################################################
# locals.tf - Management Layer Orchestrator
################################################################################

locals {
  #-----------------------------------------------------------------------------
  # Location Abbreviations for F02
  #-----------------------------------------------------------------------------
  location_abbrev = {
    "australiaeast"      = "aue"
    "australiasoutheast" = "aus"
    "westeurope"         = "weu"
    "northeurope"        = "neu"
    "eastus"             = "eus"
    "westus2"            = "wus2"
  }

  primary_region   = lookup(local.location_abbrev, var.primary_location, "aue")
  secondary_region = lookup(local.location_abbrev, var.secondary_location, "aus")

  #-----------------------------------------------------------------------------
  # Environment Mapping for F03 Tags
  #-----------------------------------------------------------------------------
  environment_mapping = {
    "prod"    = "Production"
    "nonprod" = "PreProduction"
    "dev"     = "Development"
    "test"    = "Test"
    "uat"     = "PreProduction"
    "stg"     = "PreProduction"
    "sandbox" = "Sandbox"
  }

  f03_environment = local.environment_mapping[var.environment]

  #-----------------------------------------------------------------------------
  # Resource Group
  #-----------------------------------------------------------------------------
  rg_name     = var.resource_group_name
  rg_location = var.primary_location

  #-----------------------------------------------------------------------------
  # Default Runbooks for M02
  #-----------------------------------------------------------------------------
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

  #-----------------------------------------------------------------------------
  # Default Schedules for M02
  #-----------------------------------------------------------------------------
  default_schedules = var.deploy_default_schedules ? tomap({
    "weekday-start-7am-aest" = {
      description = "Start VMs at 7 AM AEST weekdays"
      start_time  = "2026-01-05T07:00:00+10:00"
      frequency   = "Week"
      interval    = 1
      timezone    = "Australia/Sydney"
      week_days   = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
      month_days  = []
      expiry_time = null
    }
    "weekday-stop-7pm-aest" = {
      description = "Stop VMs at 7 PM AEST weekdays"
      start_time  = "2026-01-05T19:00:00+10:00"
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

  #-----------------------------------------------------------------------------
  # Dependency Validation
  #-----------------------------------------------------------------------------
  m02_can_deploy = var.deploy_m02_automation && var.deploy_m01_log_analytics
  m03_can_deploy = var.deploy_m03_action_groups
  m04_can_deploy = var.deploy_m04_alerts && var.deploy_m01_log_analytics && var.deploy_m03_action_groups
  m06_can_deploy = var.deploy_m06_update_management
  m07_can_deploy = var.deploy_m07_dcr && var.deploy_m01_log_analytics
  m08_can_deploy = var.deploy_m08_diagnostics_storage
  m08_self_diagnostics_can_deploy = var.deploy_m08_diagnostics_storage && var.deploy_m01_log_analytics && var.enable_m08_self_diagnostics
  #===============================================================================
  # M07 - DATA COLLECTION RULES - LOCAL CONFIGURATIONS
  #===============================================================================
  
  # Resource group name for DCRs (same as M01)
  dcr_resource_group_name = local.rg_name
  
  # Location from M01
  dcr_location = var.deploy_m01_log_analytics ? module.m01_log_analytics[0].outputs_for_m07.location : var.primary_location
  
  # Workspace resource ID from M01
  dcr_workspace_resource_id = var.deploy_m01_log_analytics ? module.m01_log_analytics[0].outputs_for_m07.workspace_resource_id : null
  
  # Tags merged from M01
  dcr_tags = var.deploy_m01_log_analytics ? merge(
    module.m01_log_analytics[0].tags,
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
    var.dcr_additional_tags
  )
  
  #-----------------------------------------------------------------------------
  # KQL Transformations for Cost Optimization
  #-----------------------------------------------------------------------------
  
 # Security events - Filter for Critical/Error/Warning only
  dcr_security_transform_kql = var.enable_dcr_cost_optimization ? (<<-EOT
source
| where EventLevelName in ("Critical", "Error", "Warning")
| extend Environment = "${local.f03_environment}"
| extend CostCenter = "${var.cost_center}"
EOT
  ) : null
  
  #-----------------------------------------------------------------------------
  # 10 RECOMMENDED DCR CONFIGURATIONS
  #-----------------------------------------------------------------------------
  
  recommended_dcr_configurations = var.disable_default_dcrs ? tomap({}) : {
    
    #===========================================================================
    # DCR #1: Windows Performance Counters (ALL ARCHETYPES)
    #===========================================================================
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
            "\\LogicalDisk(_Total)\\Disk Transfers/sec",
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
    
    #===========================================================================
    # DCR #2: Windows Security Events (ALL ARCHETYPES)
    #===========================================================================
    "dcr-windows-events-security" = {
      location            = local.dcr_location
      resource_group_name = local.dcr_resource_group_name
      description         = "Security event logs for all Windows VMs - CAF Security Baseline"
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
        streams       = ["Microsoft-WindowsEvent"]
        destinations  = ["central-workspace"]
        transform_kql = local.dcr_security_transform_kql
      }]
      
      data_sources = {
        windows_event_log = [{
          streams = ["Microsoft-WindowsEvent"]
          x_path_queries = [
            # Logon events
            "Security!*[System[(EventID=4624 or EventID=4625 or EventID=4648)]]",
            # Account management
            "Security!*[System[(EventID=4720 or EventID=4722 or EventID=4723 or EventID=4724)]]",
            # Privilege use
            "Security!*[System[(EventID=4672)]]",
            # All Critical/Error/Warning
            "Security!*[System[(Level=1 or Level=2 or Level=3)]]",
            # System events
            "System!*[System[(Level=1 or Level=2 or Level=3)]]"
          ]
          name = "securityEventsDataSource"
        }]
      }
      
      tags = {
        DCRType    = "Security"
        OSType     = "Windows"
        Archetypes = "All"
      }
    }
    
    #===========================================================================
    # DCR #3: Linux Performance Counters (ALL ARCHETYPES)
    #===========================================================================
    "dcr-linux-performance" = {
      location            = local.dcr_location
      resource_group_name = local.dcr_resource_group_name
      description         = "Performance counters for all Linux VMs across all archetypes"
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
        streams      = ["Microsoft-Perf"]
        destinations = ["central-workspace"]
      }]
      
      data_sources = {
        performance_counter = [{
          streams                       = ["Microsoft-Perf"]
          sampling_frequency_in_seconds = var.dcr_linux_perf_sampling_frequency
          counter_specifiers = [
            "Processor(*)\\% Processor Time",
            "Processor(*)\\% Privileged Time",
            "Processor(*)\\% User Time",
            "Memory(*)\\Available MBytes Memory",
            "Memory(*)\\% Used Memory",
            "Logical Disk(*)\\% Free Space",
            "Logical Disk(*)\\Disk Transfers/sec",
            "Network(*)\\Total Bytes Transmitted",
            "Network(*)\\Total Bytes Received"
          ]
          name = "perfCounterDataSource"
        }]
      }
      
      tags = {
        DCRType    = "Performance"
        OSType     = "Linux"
        Archetypes = "All"
      }
    }
    
    #===========================================================================
    # DCR #4: Linux Syslog Security (ALL ARCHETYPES)
    #===========================================================================
    "dcr-linux-syslog-security" = {
      location            = local.dcr_location
      resource_group_name = local.dcr_resource_group_name
      description         = "Syslog security and system logs for Linux VMs - CAF Security Baseline"
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
        streams      = ["Microsoft-Syslog"]
        destinations = ["central-workspace"]
      }]
      
      data_sources = {
        syslog = [{
          streams = ["Microsoft-Syslog"]
          facility_names = [
            "auth",
            "authpriv",
            "cron",
            "daemon",
            "kern",
            "syslog"
          ]
          log_levels = ["Alert", "Critical", "Emergency", "Error", "Warning"]
          name       = "syslogDataSource"
        }]
      }
      
      tags = {
        DCRType    = "Security"
        OSType     = "Linux"
        Archetypes = "All"
      }
    }
    
    #===========================================================================
    # DCR #5: VM Insights Windows (REQUIRED FOR G03 POLICY)
    #===========================================================================
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
          counter_specifiers = [
            "\\VmInsights\\DetailedMetrics"
          ]
          name = "VMInsightsPerfCounters"
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
    
    #===========================================================================
    # DCR #6: VM Insights Linux (REQUIRED FOR G03 POLICY)
    #===========================================================================
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
          counter_specifiers = [
            "\\VmInsights\\DetailedMetrics"
          ]
          name = "VMInsightsPerfCounters"
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
    
    #===========================================================================
    # DCR #7: Windows IIS Logs (ONLINE ARCHETYPES)
    #===========================================================================
    "dcr-windows-iis-logs" = {
      location            = local.dcr_location
      resource_group_name = local.dcr_resource_group_name
      description         = "IIS logs for Online archetype web servers"
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
        streams      = ["Microsoft-W3CIISLog"]
        destinations = ["central-workspace"]
      }]
      
      data_sources = {
        iis_log = [{
          streams         = ["Microsoft-W3CIISLog"]
          log_directories = var.dcr_iis_log_directories
          name            = "iisLogsDataSource"
        }]
      }
      
      tags = {
        DCRType    = "ApplicationLogs"
        OSType     = "Windows"
        Archetypes = "Online-Prod,Online-NonProd"
      }
    }
    
    #===========================================================================
    # DCR #8: Windows Application Events (PRODUCTION)
    #===========================================================================
    "dcr-windows-events-application" = {
      location            = local.dcr_location
      resource_group_name = local.dcr_resource_group_name
      description         = "Application event logs for Production environments"
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
        streams      = ["Microsoft-WindowsEvent"]
        destinations = ["central-workspace"]
      }]
      
      data_sources = {
        windows_event_log = [{
          streams = ["Microsoft-WindowsEvent"]
          x_path_queries = [
            "Application!*[System[(Level=1 or Level=2)]]",
            "Microsoft-Windows-PowerShell/Operational!*[System[(Level=1 or Level=2 or Level=3)]]"
          ]
          name = "applicationEventsDataSource"
        }]
      }
      
      tags = {
        DCRType    = "ApplicationLogs"
        OSType     = "Windows"
        Archetypes = "Online-Prod,Corp-Prod"
      }
    }
    
    #===========================================================================
    # DCR #9: Linux Application Syslog (PRODUCTION)
    #===========================================================================
    "dcr-linux-syslog-application" = {
      location            = local.dcr_location
      resource_group_name = local.dcr_resource_group_name
      description         = "Application syslog for Production Linux VMs"
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
        streams      = ["Microsoft-Syslog"]
        destinations = ["central-workspace"]
      }]
      
      data_sources = {
        syslog = [{
          streams = ["Microsoft-Syslog"]
          facility_names = [
            "local0",
            "local1",
            "local2",
            "local3",
            "local4",
            "local5",
            "local6",
            "local7"
          ]
          log_levels = ["Alert", "Critical", "Emergency", "Error", "Warning", "Notice"]
          name       = "appSyslogDataSource"
        }]
      }
      
      tags = {
        DCRType    = "ApplicationLogs"
        OSType     = "Linux"
        Archetypes = "Online-Prod,Corp-Prod"
      }
    }
    
  }
  
  #-----------------------------------------------------------------------------
  # Final DCR Configurations (merge recommended + custom)
  #-----------------------------------------------------------------------------
  
  all_dcr_configurations = merge(
    local.recommended_dcr_configurations,
    var.dcr_custom_configurations
  )

}