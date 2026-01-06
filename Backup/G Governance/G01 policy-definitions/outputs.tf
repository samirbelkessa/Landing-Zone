################################################################################
# Custom Policy Definition Outputs
################################################################################

output "policy_definition_ids" {
  description = "Map of custom policy definition names to their resource IDs."
  value = {
    for k, v in azurerm_policy_definition.policies : k => v.id
  }
}

output "policy_definition_names" {
  description = "Map of custom policy definition keys to their display names."
  value = {
    for k, v in azurerm_policy_definition.policies : k => v.display_name
  }
}

output "policy_definitions" {
  description = "Full map of custom policy definitions with all attributes."
  value = {
    for k, v in azurerm_policy_definition.policies : k => {
      id               = v.id
      name             = v.name
      display_name     = v.display_name
      description      = v.description
      policy_type      = v.policy_type
      mode             = v.mode
      management_group = v.management_group_id
    }
  }
}

################################################################################
# Policy Definitions by Category
################################################################################

output "network_policy_ids" {
  description = "Map of network-related policy definition IDs."
  value = {
    for k, v in azurerm_policy_definition.policies : k => v.id
    if can(regex("network|vnet|firewall|dns|route|ddos|ip", lower(k)))
  }
}

output "security_policy_ids" {
  description = "Map of security-related policy definition IDs."
  value = {
    for k, v in azurerm_policy_definition.policies : k => v.id
    if can(regex("security|storage|sql|cosmos|private|endpoint", lower(k)))
  }
}

output "monitoring_policy_ids" {
  description = "Map of monitoring-related policy definition IDs."
  value = {
    for k, v in azurerm_policy_definition.policies : k => v.id
    if can(regex("monitor|diagnostic|log|sentinel|retention|archive", lower(k)))
  }
}

output "backup_policy_ids" {
  description = "Map of backup-related policy definition IDs."
  value = {
    for k, v in azurerm_policy_definition.policies : k => v.id
    if can(regex("backup|recovery|grs|lrs", lower(k)))
  }
}

output "cost_policy_ids" {
  description = "Map of cost management policy definition IDs."
  value = {
    for k, v in azurerm_policy_definition.policies : k => v.id
    if can(regex("cost|budget|sku|expensive", lower(k)))
  }
}

output "lifecycle_policy_ids" {
  description = "Map of lifecycle management policy definition IDs."
  value = {
    for k, v in azurerm_policy_definition.policies : k => v.id
    if can(regex("lifecycle|expiration|sandbox|audit-only", lower(k)))
  }
}

output "decommissioned_policy_ids" {
  description = "Map of decommissioned management policy definition IDs."
  value = {
    for k, v in azurerm_policy_definition.policies : k => v.id
    if can(regex("deny-all", lower(k)))
  }
}

################################################################################
# Built-in Policy Definition References
################################################################################

output "builtin_policy_ids" {
  description = "Map of commonly used built-in policy definition IDs for reference."
  value = {
    allowed_locations         = data.azurerm_policy_definition.allowed_locations.id
    allowed_locations_rg      = data.azurerm_policy_definition.allowed_locations_rg.id
    not_allowed_resource_types = data.azurerm_policy_definition.not_allowed_resource_types.id
    require_tag_rg            = data.azurerm_policy_definition.require_tag_rg.id
    inherit_tag_rg            = data.azurerm_policy_definition.inherit_tag_rg.id
    ama_installed             = data.azurerm_policy_definition.ama_installed.id
    defender_enabled          = data.azurerm_policy_definition.defender_enabled.id
    secure_transfer_storage   = data.azurerm_policy_definition.secure_transfer_storage.id
    vm_encryption_host        = data.azurerm_policy_definition.vm_encryption_host.id
    backup_vms                = data.azurerm_policy_definition.backup_vms.id
    subnet_nsg                = data.azurerm_policy_definition.subnet_nsg.id
    nsg_flow_logs             = data.azurerm_policy_definition.nsg_flow_logs.id
    keyvault_rbac             = data.azurerm_policy_definition.keyvault_rbac.id
    keyvault_soft_delete      = data.azurerm_policy_definition.keyvault_soft_delete.id
    keyvault_purge_protection = data.azurerm_policy_definition.keyvault_purge_protection.id
    waf_appgw                 = data.azurerm_policy_definition.waf_appgw.id
    waf_frontdoor             = data.azurerm_policy_definition.waf_frontdoor.id
    webapp_https              = data.azurerm_policy_definition.webapp_https.id
    tls_minimum               = data.azurerm_policy_definition.tls_minimum.id
    deny_public_ip            = data.azurerm_policy_definition.deny_public_ip.id
    managed_identity          = data.azurerm_policy_definition.managed_identity.id
    allowed_vm_skus           = data.azurerm_policy_definition.allowed_vm_skus.id
  }
}

################################################################################
# Built-in Policy Set (Initiative) References
################################################################################

output "builtin_initiative_ids" {
  description = "Map of commonly used built-in policy set (initiative) IDs for reference."
  value = {
    azure_security_benchmark = data.azurerm_policy_set_definition.azure_security_benchmark.id
    vm_insights              = data.azurerm_policy_set_definition.vm_insights.id
  }
}

################################################################################
# Summary Output
################################################################################

output "summary" {
  description = "Summary of deployed policy definitions."
  value = {
    total_custom_policies = length(azurerm_policy_definition.policies)
    management_group      = var.management_group_id
    caf_policies_enabled  = var.deploy_caf_policies
    categories = {
      network      = var.enable_network_policies
      security     = var.enable_security_policies
      monitoring   = var.enable_monitoring_policies
      backup       = var.enable_backup_policies
      cost         = var.enable_cost_policies
      lifecycle    = var.enable_lifecycle_policies
    }
  }
}

################################################################################
# For Integration with G02 (Policy Set Definitions)
################################################################################

output "policy_ids_for_initiatives" {
  description = "Structured output for creating policy set definitions (initiatives) in module G02."
  value = {
    # Network Initiative policies
    network = {
      for k, v in azurerm_policy_definition.policies : k => {
        id           = v.id
        display_name = v.display_name
        parameters   = try(jsondecode(v.parameters), {})
      }
      if can(regex("network|vnet|firewall|dns|route|ddos|ip|peered", lower(k)))
    }
    
    # Security Initiative policies
    security = {
      for k, v in azurerm_policy_definition.policies : k => {
        id           = v.id
        display_name = v.display_name
        parameters   = try(jsondecode(v.parameters), {})
      }
      if can(regex("security|storage|sql|cosmos|private|endpoint|deny-.*-without", lower(k)))
    }
    
    # Monitoring Initiative policies
    monitoring = {
      for k, v in azurerm_policy_definition.policies : k => {
        id           = v.id
        display_name = v.display_name
        parameters   = try(jsondecode(v.parameters), {})
      }
      if can(regex("monitor|diagnostic|log|sentinel|retention|archive", lower(k)))
    }
    
    # Backup Initiative policies
    backup = {
      for k, v in azurerm_policy_definition.policies : k => {
        id           = v.id
        display_name = v.display_name
        parameters   = try(jsondecode(v.parameters), {})
      }
      if can(regex("backup|recovery|grs|lrs", lower(k)))
    }
    
    # Sandbox Initiative policies
    sandbox = {
      for k, v in azurerm_policy_definition.policies : k => {
        id           = v.id
        display_name = v.display_name
        parameters   = try(jsondecode(v.parameters), {})
      }
      if can(regex("sandbox|expiration|expensive|allowed.*sku", lower(k)))
    }
    
    # Decommissioned Initiative policies
    decommissioned = {
      for k, v in azurerm_policy_definition.policies : k => {
        id           = v.id
        display_name = v.display_name
        parameters   = try(jsondecode(v.parameters), {})
      }
      if can(regex("deny-all", lower(k)))
    }
  }
}
