################################################################################
# main.tf - M02 Automation Account Module
# Azure Automation Account with F02 Naming and F03 Tags
################################################################################

#-------------------------------------------------------------------------------
# F02 - Naming Convention Module
#-------------------------------------------------------------------------------

module "naming" {
  source = "../F02-naming-convention"

  resource_type = "aa"
  workload      = var.workload
  environment   = var.environment
  region        = var.region
  instance      = var.instance
}

#-------------------------------------------------------------------------------
# F03 - Tags Module
#-------------------------------------------------------------------------------

module "tags" {
  source = "../F03-tags"

  environment         = local.f03_environment
  owner               = var.owner
  cost_center         = var.cost_center
  application         = var.application
  criticality         = var.criticality
  data_classification = var.data_classification
  project             = var.project
  department          = var.department
  module_name         = "M02-automation-account"
  additional_tags     = var.additional_tags
}

#-------------------------------------------------------------------------------
# Automation Account
#-------------------------------------------------------------------------------

resource "azurerm_automation_account" "this" {
  name                          = local.automation_account_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku_name                      = var.sku_name
  public_network_access_enabled = var.public_network_access_enabled
  local_authentication_enabled  = var.local_authentication_enabled

  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = local.identity_ids
    }
  }

  tags = module.tags.all_tags

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }
}

#-------------------------------------------------------------------------------
# Log Analytics Linked Service
# Required for Update Management, Change Tracking, and Inventory
#-------------------------------------------------------------------------------

resource "azurerm_log_analytics_linked_service" "this" {
  count = var.create_la_linked_service ? 1 : 0

  resource_group_name = var.resource_group_name
  workspace_id        = var.log_analytics_workspace_id
  read_access_id      = azurerm_automation_account.this.id
}

#-------------------------------------------------------------------------------
# Runbooks
#-------------------------------------------------------------------------------

resource "azurerm_automation_runbook" "runbooks" {
  for_each = var.runbooks

  name                    = each.key
  resource_group_name     = var.resource_group_name
  location                = var.location
  automation_account_name = azurerm_automation_account.this.name
  runbook_type            = each.value.runbook_type
  description             = each.value.description
  log_verbose             = false
  log_progress            = false
  content                 = each.value.content

  dynamic "publish_content_link" {
    for_each = each.value.uri != null ? [1] : []
    content {
      uri     = each.value.uri
      version = each.value.version

      dynamic "hash" {
        for_each = each.value.hash_value != null ? [1] : []
        content {
          algorithm = "SHA256"
          value     = each.value.hash_value
        }
      }
    }
  }

  tags = merge(module.tags.all_tags, each.value.tags)
}

#-------------------------------------------------------------------------------
# Schedules
#-------------------------------------------------------------------------------

resource "azurerm_automation_schedule" "schedules" {
  for_each = var.schedules

  name                    = each.key
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  description             = each.value.description
  start_time              = each.value.start_time
  frequency               = each.value.frequency
  interval                = each.value.interval
  timezone                = each.value.timezone
  week_days               = length(each.value.week_days) > 0 ? each.value.week_days : null
  month_days              = length(each.value.month_days) > 0 ? each.value.month_days : null
  expiry_time             = each.value.expiry_time
}

#-------------------------------------------------------------------------------
# Credentials
#-------------------------------------------------------------------------------

resource "azurerm_automation_credential" "credentials" {
  for_each = nonsensitive(toset(keys(var.credentials)))

  name                    = each.key
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  username                = var.credentials[each.key].username
  password                = var.credentials[each.key].password
  description             = var.credentials[each.key].description
}

#-------------------------------------------------------------------------------
# Variables - String
#-------------------------------------------------------------------------------

resource "azurerm_automation_variable_string" "variables" {
  for_each = var.variables_string

  name                    = each.key
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  value                   = each.value.value
  encrypted               = each.value.encrypted
  description             = each.value.description
}

#-------------------------------------------------------------------------------
# Variables - Integer
#-------------------------------------------------------------------------------

resource "azurerm_automation_variable_int" "variables" {
  for_each = var.variables_int

  name                    = each.key
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  value                   = each.value.value
  encrypted               = each.value.encrypted
  description             = each.value.description
}

#-------------------------------------------------------------------------------
# Variables - Boolean
#-------------------------------------------------------------------------------

resource "azurerm_automation_variable_bool" "variables" {
  for_each = var.variables_bool

  name                    = each.key
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  value                   = each.value.value
  encrypted               = each.value.encrypted
  description             = each.value.description
}

#-------------------------------------------------------------------------------
# PowerShell Modules
#-------------------------------------------------------------------------------

resource "azurerm_automation_module" "modules" {
  for_each = var.powershell_modules

  name                    = each.key
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.this.name

  module_link {
    uri = each.value.uri
  }
}

#-------------------------------------------------------------------------------
# DSC Configurations
#-------------------------------------------------------------------------------

resource "azurerm_automation_dsc_configuration" "configurations" {
  for_each = var.dsc_configurations

  name                    = each.key
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  location                = var.location
  content_embedded        = each.value.content_embedded
  description             = each.value.description

  tags = module.tags.all_tags
}

#-------------------------------------------------------------------------------
# Webhooks
#-------------------------------------------------------------------------------

resource "azurerm_automation_webhook" "webhooks" {
  for_each = nonsensitive(toset(keys(var.webhooks)))

  name                    = each.key
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  runbook_name            = var.webhooks[each.key].runbook_name
  expiry_time             = var.webhooks[each.key].expiry_time
  enabled                 = var.webhooks[each.key].enabled
  parameters              = var.webhooks[each.key].parameters
  run_on_worker_group     = var.webhooks[each.key].run_on_worker_group

  depends_on = [azurerm_automation_runbook.runbooks]
}

#-------------------------------------------------------------------------------
# Diagnostic Settings
#-------------------------------------------------------------------------------

# Attendre que les politiques Azure aient fini
resource "time_sleep" "wait_for_policies" {
  depends_on = [azurerm_automation_account.this]
  
  create_duration = "120s" # Attendre 2 minutes
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  depends_on = [time_sleep.wait_for_policies]
  count = var.enable_diagnostic_settings ? 1 : 0

  name                       = "diag-${local.automation_account_name}"
  target_resource_id         = azurerm_automation_account.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  storage_account_id         = var.diagnostic_storage_account_id

  dynamic "enabled_log" {
    for_each = local.diagnostic_logs
    content {
      category = enabled_log.value.category
    }
  }

  dynamic "metric" {
    for_each = local.diagnostic_metrics
    content {
      category = metric.value.category
      enabled  = metric.value.enabled
    }
  }
}
