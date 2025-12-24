# =============================================================================
# Main - Module monitor-action-groups (M03)
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# F02 - Naming Convention Module
# ─────────────────────────────────────────────────────────────────────────────

module "naming" {
  source = "../F02-naming-convention"

  resource_type = "ag"
  workload      = var.workload
  environment   = var.environment
  region        = var.region
  instance      = var.instance
}

# ─────────────────────────────────────────────────────────────────────────────
# F03 - Tags Module
# ─────────────────────────────────────────────────────────────────────────────

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
  module_name         = "M03-monitor-action-groups"
  additional_tags     = var.additional_tags
}

# ─────────────────────────────────────────────────────────────────────────────
# Action Groups
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_monitor_action_group" "action_groups" {
  for_each = local.all_action_groups

  name                = "${local.base_name}-${each.key}"
  resource_group_name = var.resource_group_name
  short_name          = each.value.short_name
  enabled             = each.value.enabled

  tags = module.tags.all_tags

  # ───────────────────────────────────────────────────────────────────────────
  # Email Receivers
  # ───────────────────────────────────────────────────────────────────────────
  dynamic "email_receiver" {
    for_each = each.value.email_receivers
    content {
      name                    = email_receiver.value.name
      email_address           = email_receiver.value.email_address
      use_common_alert_schema = email_receiver.value.use_common_alert_schema
    }
  }

  # ───────────────────────────────────────────────────────────────────────────
  # SMS Receivers
  # ───────────────────────────────────────────────────────────────────────────
  dynamic "sms_receiver" {
    for_each = each.value.sms_receivers
    content {
      name         = sms_receiver.value.name
      country_code = sms_receiver.value.country_code
      phone_number = sms_receiver.value.phone_number
    }
  }

  # ───────────────────────────────────────────────────────────────────────────
  # Webhook Receivers
  # ───────────────────────────────────────────────────────────────────────────
  dynamic "webhook_receiver" {
    for_each = each.value.webhook_receivers
    content {
      name                    = webhook_receiver.value.name
      service_uri             = webhook_receiver.value.service_uri
      use_common_alert_schema = webhook_receiver.value.use_common_alert_schema

      dynamic "aad_auth" {
        for_each = webhook_receiver.value.aad_auth != null ? [webhook_receiver.value.aad_auth] : []
        content {
          object_id      = aad_auth.value.object_id
          identifier_uri = aad_auth.value.identifier_uri
          tenant_id      = aad_auth.value.tenant_id
        }
      }
    }
  }

  # ───────────────────────────────────────────────────────────────────────────
  # Azure Function Receivers
  # ───────────────────────────────────────────────────────────────────────────
  dynamic "azure_function_receiver" {
    for_each = each.value.azure_function_receivers
    content {
      name                     = azure_function_receiver.value.name
      function_app_resource_id = azure_function_receiver.value.function_app_resource_id
      function_name            = azure_function_receiver.value.function_name
      http_trigger_url         = azure_function_receiver.value.http_trigger_url
      use_common_alert_schema  = azure_function_receiver.value.use_common_alert_schema
    }
  }

  # ───────────────────────────────────────────────────────────────────────────
  # Logic App Receivers
  # ───────────────────────────────────────────────────────────────────────────
  dynamic "logic_app_receiver" {
    for_each = each.value.logic_app_receivers
    content {
      name                    = logic_app_receiver.value.name
      resource_id             = logic_app_receiver.value.resource_id
      callback_url            = logic_app_receiver.value.callback_url
      use_common_alert_schema = logic_app_receiver.value.use_common_alert_schema
    }
  }

  # ───────────────────────────────────────────────────────────────────────────
  # Automation Runbook Receivers
  # ───────────────────────────────────────────────────────────────────────────
  dynamic "automation_runbook_receiver" {
    for_each = each.value.automation_runbook_receivers
    content {
      name                    = automation_runbook_receiver.value.name
      automation_account_id   = automation_runbook_receiver.value.automation_account_id
      runbook_name            = automation_runbook_receiver.value.runbook_name
      webhook_resource_id     = automation_runbook_receiver.value.webhook_resource_id
      is_global_runbook       = automation_runbook_receiver.value.is_global_runbook
      service_uri             = automation_runbook_receiver.value.service_uri
      use_common_alert_schema = automation_runbook_receiver.value.use_common_alert_schema
    }
  }

  # ───────────────────────────────────────────────────────────────────────────
  # Voice Receivers
  # ───────────────────────────────────────────────────────────────────────────
  dynamic "voice_receiver" {
    for_each = each.value.voice_receivers
    content {
      name         = voice_receiver.value.name
      country_code = voice_receiver.value.country_code
      phone_number = voice_receiver.value.phone_number
    }
  }

  # ───────────────────────────────────────────────────────────────────────────
  # ARM Role Receivers
  # ───────────────────────────────────────────────────────────────────────────
  dynamic "arm_role_receiver" {
    for_each = each.value.arm_role_receivers
    content {
      name                    = arm_role_receiver.value.name
      role_id                 = arm_role_receiver.value.role_id
      use_common_alert_schema = arm_role_receiver.value.use_common_alert_schema
    }
  }

  # ───────────────────────────────────────────────────────────────────────────
  # Event Hub Receivers
  # ───────────────────────────────────────────────────────────────────────────
  dynamic "event_hub_receiver" {
    for_each = each.value.event_hub_receivers
    content {
      name                    = event_hub_receiver.value.name
      event_hub_namespace     = event_hub_receiver.value.event_hub_namespace
      event_hub_name          = event_hub_receiver.value.event_hub_name
      subscription_id         = event_hub_receiver.value.subscription_id
      tenant_id               = event_hub_receiver.value.tenant_id
      use_common_alert_schema = event_hub_receiver.value.use_common_alert_schema
    }
  }

  # ───────────────────────────────────────────────────────────────────────────
  # ITSM Receivers
  # ───────────────────────────────────────────────────────────────────────────
  dynamic "itsm_receiver" {
    for_each = each.value.itsm_receivers
    content {
      name                 = itsm_receiver.value.name
      workspace_id         = itsm_receiver.value.workspace_id
      connection_id        = itsm_receiver.value.connection_id
      ticket_configuration = itsm_receiver.value.ticket_configuration
      region               = itsm_receiver.value.region
    }
  }

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}
