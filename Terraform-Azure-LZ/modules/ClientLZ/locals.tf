locals {
  all_tags = merge(local.default_tags, var.tags)

  computed_dns_zone_scopes = var.deploy_managed_identity && var.uami_dns_zone_resource_group_name != null ? {
    for zone in var.uami_dns_zone_names :
    zone => "/subscriptions/${data.azurerm_client_config.hub[0].subscription_id}/resourceGroups/${var.uami_dns_zone_resource_group_name}/providers/Microsoft.Network/privateDnsZones/${zone}"
  } : {}

  default_tags = {
    ManagedBy = "Terraform"
    Module    = "ClientLZ"
    Client    = var.client_name
  }

  env_code = lookup(local.env_codes, var.environment_name, "x")

  env_codes = {
    "Development" = "n"
    "Test"        = "n"
    "Staging"     = "n"
    "Production"  = "p"
  }

  fw_app_collection_name = coalesce(
    var.firewall_app_collection_name,
    "${var.client_name}ApplicationRuleCollectionGroup"
  )

  fw_net_collection_name = coalesce(
    var.firewall_network_collection_name,
    "${upper(var.environment_key)}NetworkRuleCollectionGroup"
  )

  merged_dns_zone_scopes = merge(local.computed_dns_zone_scopes, var.uami_dns_zone_scopes)

  merged_nsg_rules = merge(var.base_nsg_rules, var.nsg_rules)

  prefix = "${var.root_id}${local.env_code}${local.region_code}2"

  region_code = lookup(local.region_codes, var.location, "xxx")

  region_codes = {
    "australiaeast"      = "aea"
    "australiasoutheast" = "asa"
    "eastus"             = "eus"
    "eastus2"            = "eu2"
    "westus"             = "wus"
    "westus2"            = "wu2"
    "westeurope"         = "weu"
    "northeurope"        = "neu"
    "uksouth"            = "uks"
    "ukwest"             = "ukw"
    "southeastasia"      = "sea"
    "centralus"          = "cus"
    "francecentral"      = "frc"
    "francesouth"        = "frs"
    "canadacentral"      = "cac"
    "canadaeast"         = "cae"
    "japaneast"          = "jpe"
    "japanwest"          = "jpw"
  }

  uami_name = coalesce(
    var.uami_name,
    "${local.prefix}idtyc${var.client_prefix}${var.instance}"
  )

  uami_rg_name = coalesce(
    var.uami_resource_group_name,
    "${local.prefix}rgc${var.client_prefix}aksnodes${var.instance}"
  )

}
