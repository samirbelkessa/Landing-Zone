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
  m06_can_deploy = var.deploy_m06_update_management && var.deploy_m01_log_analytics && var.deploy_m02_automation
  m07_can_deploy = var.deploy_m07_dcr && var.deploy_m01_log_analytics
}

# Si vous avez des subscriptions à monitorer définies comme variables:
# 
# m04_subscription_ids = compact([
#   data.azurerm_client_config.current.subscription_id,
#   var.connectivity_subscription_id,
#   var.identity_subscription_id
# ])
#
# Pour l'instant, utilise uniquement la subscription courante
#m04_subscription_ids = [data.azurerm_client_config.current.subscription_id]