################################################################################
# Azure Policy Definitions
################################################################################

# Custom Policy Definitions
# Creates policy definitions at the specified management group scope
resource "azurerm_policy_definition" "policies" {
  for_each = local.all_policy_definitions

  name                = each.key
  display_name        = each.value.name
  description         = each.value.description
  policy_type         = "Custom"
  mode                = each.value.mode
  management_group_id = var.management_group_id

  # Already JSON-encoded in locals.tf
  metadata    = each.value.metadata
  parameters  = each.value.parameters
  policy_rule = each.value.policy_rule

  lifecycle {
    # Prevent destruction of policies that may be in use
    prevent_destroy = false
  }
}

################################################################################
# Data Sources - Built-in Policy Definitions
################################################################################

# Reference commonly used built-in policies for documentation and integration
# These can be used by other modules (like G03 policy-assignments) to create assignments

data "azurerm_policy_definition" "allowed_locations" {
  name = "e56962a6-4747-49cd-b67b-bf8b01975c4c"
}

data "azurerm_policy_definition" "allowed_locations_rg" {
  name = "e765b5de-1225-4ba3-bd56-1ac6695af988"
}

data "azurerm_policy_definition" "not_allowed_resource_types" {
  name = "6c112d4e-5bc7-47ae-a041-ea2d9dccd749"
}

data "azurerm_policy_definition" "require_tag_rg" {
  name = "96670d01-0a4d-4649-9c89-2d3abc0a5025"
}

data "azurerm_policy_definition" "inherit_tag_rg" {
  name = "ea3f2387-9b95-492a-a190-fcdc54f7b070"
}

data "azurerm_policy_definition" "ama_installed" {
  name = "845857af-0333-4c5d-bbbc-6076697da122"
}

data "azurerm_policy_definition" "defender_enabled" {
  name = "4da35fc9-c9e7-4960-aec9-797fe7d9051d"
}

data "azurerm_policy_definition" "secure_transfer_storage" {
  name = "404c3081-a854-4457-ae30-26a93ef643f9"
}

data "azurerm_policy_definition" "vm_encryption_host" {
  name = "fc4d8e41-e223-45ea-9bf5-eada37891d87"
}

data "azurerm_policy_definition" "backup_vms" {
  name = "013e242c-8828-4970-87b3-ab247555486d"
}

data "azurerm_policy_definition" "subnet_nsg" {
  name = "e71308d3-144b-4262-b144-efdc3cc90517"
}

data "azurerm_policy_definition" "nsg_flow_logs" {
  name = "27960feb-a23c-4577-8d36-ef8b5f35e0be"
}

data "azurerm_policy_definition" "keyvault_rbac" {
  name = "12d4fa5e-1f9f-4c21-97a9-b99b3c6611b5"
}

data "azurerm_policy_definition" "keyvault_soft_delete" {
  name = "1e66c121-a66a-4b1f-9b83-0fd99bf0fc2d"
}

data "azurerm_policy_definition" "keyvault_purge_protection" {
  name = "0b60c0b2-2dc2-4e1c-b5c9-abbed971de53"
}

data "azurerm_policy_definition" "waf_appgw" {
  name = "564feb30-bf6a-4854-b4bb-0d2d2d1e6c66"
}

data "azurerm_policy_definition" "waf_frontdoor" {
  name = "055aa869-bc98-4af8-bafc-23f1ab6ffe2c"
}

data "azurerm_policy_definition" "webapp_https" {
  name = "a4af4a39-4135-47fb-b175-47fbdf85311d"
}

data "azurerm_policy_definition" "tls_minimum" {
  name = "f0e6e85b-9b9f-4a4b-b67b-f730d42f1b0b"
}

data "azurerm_policy_definition" "deny_public_ip" {
  name = "83a86a26-fd1f-447c-b59d-e51f44264114"
}

data "azurerm_policy_definition" "managed_identity" {
  name = "0da106f2-4ca3-48e8-bc85-c638fe6aea8f"
}

data "azurerm_policy_definition" "allowed_vm_skus" {
  name = "cccc23c7-8427-4f53-ad12-b6a63eb452b3"
}

################################################################################
# Data Sources - Built-in Policy Set Definitions (Initiatives)
################################################################################

data "azurerm_policy_set_definition" "azure_security_benchmark" {
  display_name = "Microsoft cloud security benchmark"
}

data "azurerm_policy_set_definition" "vm_insights" {
  display_name = "Enable Azure Monitor for VMs with Azure Monitoring Agent(AMA)"
}
