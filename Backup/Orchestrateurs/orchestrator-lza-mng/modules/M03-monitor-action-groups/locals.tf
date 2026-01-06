# =============================================================================
# Locals - Module monitor-action-groups (M03)
# =============================================================================

locals {
  # ───────────────────────────────────────────────────────────────────────────
  # Environment Mapping for F03 Tags
  # F02 uses lowercase short names (prod, dev), F03 uses full names (Production, Development)
  # ───────────────────────────────────────────────────────────────────────────
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

  # ───────────────────────────────────────────────────────────────────────────
  # Final Resource Name (from F02 or custom override)
  # ───────────────────────────────────────────────────────────────────────────
  base_name = var.custom_name != null ? var.custom_name : module.naming.name

  # ───────────────────────────────────────────────────────────────────────────
  # Default Action Groups Configuration
  # ───────────────────────────────────────────────────────────────────────────

  default_action_groups = var.create_default_action_groups ? {
    critical = {
      short_name = "Critical"
      enabled    = true
      email_receivers = [
        for receiver in var.default_email_receivers : {
          name                    = receiver.name
          email_address           = receiver.email_address
          use_common_alert_schema = true
        }
      ]
      sms_receivers = []
      webhook_receivers = var.default_webhook_url != null ? [{
        name                    = "DefaultWebhook"
        service_uri             = var.default_webhook_url
        use_common_alert_schema = true
        aad_auth                = null
      }] : []
      azure_function_receivers     = []
      logic_app_receivers          = []
      automation_runbook_receivers = []
      voice_receivers              = []
      arm_role_receivers           = []
      event_hub_receivers          = []
      itsm_receivers               = []
    }
    warning = {
      short_name = "Warning"
      enabled    = true
      email_receivers = [
        for receiver in var.default_email_receivers : {
          name                    = receiver.name
          email_address           = receiver.email_address
          use_common_alert_schema = true
        }
      ]
      sms_receivers                = []
      webhook_receivers            = []
      azure_function_receivers     = []
      logic_app_receivers          = []
      automation_runbook_receivers = []
      voice_receivers              = []
      arm_role_receivers           = []
      event_hub_receivers          = []
      itsm_receivers               = []
    }
    info = {
      short_name = "Info"
      enabled    = true
      email_receivers = [
        for receiver in var.default_email_receivers : {
          name                    = receiver.name
          email_address           = receiver.email_address
          use_common_alert_schema = true
        }
      ]
      sms_receivers                = []
      webhook_receivers            = []
      azure_function_receivers     = []
      logic_app_receivers          = []
      automation_runbook_receivers = []
      voice_receivers              = []
      arm_role_receivers           = []
      event_hub_receivers          = []
      itsm_receivers               = []
    }
  } : {}

  # Merge custom and default action groups
  all_action_groups = merge(local.default_action_groups, var.action_groups)
}
