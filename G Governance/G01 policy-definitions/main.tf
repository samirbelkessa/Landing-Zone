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

  # Metadata - includes category, version, and any custom metadata
  metadata = jsonencode(merge(
    {
      category = try(each.value.metadata.category, "General")
      version  = try(each.value.metadata.version, "1.0.0")
    },
    local.module_tags,
    try(each.value.metadata, {})
  ))

  # Parameters schema - supports both HCL objects and JSON strings
  parameters = can(tostring(each.value.parameters)) ? each.value.parameters : (
    length(keys(each.value.parameters)) > 0 ? jsonencode(each.value.parameters) : null
  )

  # Policy rule - supports both HCL objects and JSON strings
  policy_rule = can(tostring(each.value.policy_rule)) ? each.value.policy_rule : jsonencode(each.value.policy_rule)

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
  display_name = "Allowed locations"
}

data "azurerm_policy_definition" "allowed_locations_rg" {
  display_name = "Allowed locations for resource groups"
}

data "azurerm_policy_definition" "not_allowed_resource_types" {
  display_name = "Not allowed resource types"
}

data "azurerm_policy_definition" "require_tag_rg" {
  display_name = "Require a tag on resource groups"
}

data "azurerm_policy_definition" "inherit_tag_rg" {
  display_name = "Inherit a tag from the resource group"
}

data "azurerm_policy_definition" "ama_installed" {
  display_name = "Azure Monitor Agent should be installed on virtual machines"
}

data "azurerm_policy_definition" "defender_enabled" {
  display_name = "Azure Defender for servers should be enabled"
}

data "azurerm_policy_definition" "secure_transfer_storage" {
  display_name = "Secure transfer to storage accounts should be enabled"
}

data "azurerm_policy_definition" "vm_encryption_host" {
  display_name = "Virtual machines should have encryption at host enabled"
}

data "azurerm_policy_definition" "backup_vms" {
  display_name = "Azure Backup should be enabled for Virtual Machines"
}

data "azurerm_policy_definition" "subnet_nsg" {
  display_name = "Subnets should have a Network Security Group"
}

data "azurerm_policy_definition" "nsg_flow_logs" {
  display_name = "Flow logs should be enabled for every network security group"
}

data "azurerm_policy_definition" "keyvault_rbac" {
  display_name = "Azure Key Vault should use RBAC permission model"
}

data "azurerm_policy_definition" "keyvault_soft_delete" {
  display_name = "Key vaults should have soft delete enabled"
}

data "azurerm_policy_definition" "keyvault_purge_protection" {
  display_name = "Key vaults should have purge protection enabled"
}

data "azurerm_policy_definition" "waf_appgw" {
  display_name = "Web Application Firewall (WAF) should be enabled for Application Gateway"
}

data "azurerm_policy_definition" "waf_frontdoor" {
  display_name = "Azure Web Application Firewall should be enabled for Azure Front Door entry-points"
}

data "azurerm_policy_definition" "webapp_https" {
  display_name = "Web Application should only be accessible over HTTPS"
}

data "azurerm_policy_definition" "tls_minimum" {
  display_name = "Latest TLS version should be used in your API App"
}

data "azurerm_policy_definition" "deny_public_ip" {
  display_name = "Network interfaces should not have public IPs"
}

data "azurerm_policy_definition" "managed_identity" {
  display_name = "Managed identity should be used in your Function App"
}

data "azurerm_policy_definition" "allowed_vm_skus" {
  display_name = "Allowed virtual machine size SKUs"
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
