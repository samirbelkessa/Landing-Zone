# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Main - L01 Subscription Vending                                               ║
# ║ Creates Azure Subscriptions and places them in Management Groups              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════════════════════════════════════════════════════════════════════════════
# Subscription Creation
# Uses azurerm_subscription resource (requires appropriate billing permissions)
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_subscription" "this" {
  for_each = local.subscriptions_to_create

  alias             = each.value.alias_name
  subscription_name = each.value.display_name
  billing_scope_id  = each.value.billing_scope
  workload          = each.value.workload_type

  tags = each.value.tags

  lifecycle {
    # Prevent accidental deletion of subscriptions
    prevent_destroy = false
    
    # Ignore changes to billing scope after creation
    ignore_changes = [
      billing_scope_id
    ]
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Wait for Subscription Propagation
# Azure needs time to propagate subscription across all services
# ══════════════════════════════════════════════════════════════════════════════

resource "time_sleep" "wait_for_subscription" {
  for_each = local.subscriptions_to_create

  depends_on = [azurerm_subscription.this]

  create_duration = var.wait_for_subscription_creation

  triggers = {
    subscription_id = azurerm_subscription.this[each.key].subscription_id
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Management Group Placement - New Subscriptions
# Places newly created subscriptions into their designated Management Groups
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_management_group_subscription_association" "new_subscriptions" {
  for_each = var.enable_subscription_placement ? local.subscriptions_to_create : {}

  management_group_id = each.value.management_group_id
  subscription_id     = "/subscriptions/${azurerm_subscription.this[each.key].subscription_id}"

  depends_on = [time_sleep.wait_for_subscription]
}

# ══════════════════════════════════════════════════════════════════════════════
# Management Group Placement - Existing Subscriptions (Brownfield)
# Places existing subscriptions into Management Groups without creating them
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_management_group_subscription_association" "existing_subscriptions" {
  for_each = var.enable_subscription_placement ? local.existing_subscriptions_to_place : {}

  management_group_id = each.value.management_group_id
  subscription_id     = "/subscriptions/${each.value.subscription_id}"
}

# ══════════════════════════════════════════════════════════════════════════════
# Subscription Budgets
# Creates consumption budgets with alerts for cost management
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_consumption_budget_subscription" "this" {
  for_each = local.subscription_budgets

  name            = "budget-${each.key}"
  subscription_id = "/subscriptions/${azurerm_subscription.this[each.key].subscription_id}"

  amount     = each.value.amount
  time_grain = each.value.time_grain

  time_period {
    start_date = each.value.start_date != null ? each.value.start_date : formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
    end_date   = each.value.end_date
  }

  dynamic "notification" {
    for_each = each.value.notifications != null ? each.value.notifications : {}

    content {
      enabled        = notification.value.enabled
      threshold      = notification.value.threshold
      operator       = notification.value.operator
      threshold_type = "Actual"

      contact_emails = notification.value.contact_emails
      contact_roles  = notification.value.contact_roles
    }
  }

  depends_on = [time_sleep.wait_for_subscription]

  lifecycle {
    ignore_changes = [
      time_period[0].start_date
    ]
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Default Role Assignments
# Applies default RBAC assignments to all subscriptions
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_role_assignment" "default" {
  for_each = local.role_assignments_map

  scope                = "/subscriptions/${azurerm_subscription.this[each.value.subscription_key].subscription_id}"
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
  principal_type       = each.value.principal_type

  depends_on = [time_sleep.wait_for_subscription]
}

# ══════════════════════════════════════════════════════════════════════════════
# Resource Provider Registration
# Registers essential resource providers for each subscription
# ══════════════════════════════════════════════════════════════════════════════

locals {
  # Essential resource providers to register
  essential_resource_providers = [
    "Microsoft.Compute",
    "Microsoft.Storage",
    "Microsoft.Network",
    "Microsoft.KeyVault",
    "Microsoft.ManagedIdentity",
    "Microsoft.Authorization",
    "Microsoft.Resources",
    "Microsoft.OperationalInsights",
    "Microsoft.OperationsManagement",
    "Microsoft.Insights",
    "Microsoft.Security",
    "Microsoft.Advisor",
    "Microsoft.AlertsManagement",
    "Microsoft.RecoveryServices"
  ]
}

# Note: Resource provider registration is typically handled via Azure Policy
# at the Management Group level. Uncomment below if manual registration is needed.

# resource "azapi_resource_action" "register_providers" {
#   for_each = {
#     for pair in setproduct(keys(local.subscriptions_to_create), local.essential_resource_providers) :
#     "${pair[0]}-${replace(pair[1], ".", "-")}" => {
#       subscription_key = pair[0]
#       provider_name    = pair[1]
#     }
#   }
#
#   type        = "Microsoft.Resources/subscriptions/providers@2021-04-01"
#   resource_id = "/subscriptions/${azurerm_subscription.this[each.value.subscription_key].subscription_id}/providers/${each.value.provider_name}"
#   method      = "POST"
#   action      = "register"
#
#   depends_on = [time_sleep.wait_for_subscription]
# }
