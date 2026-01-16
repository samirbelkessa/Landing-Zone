
resource "azurerm_resource_group" "management" {
  tags     = module.tags_rg.all_tags
  name     = var.resource_group_name
  location = local.primary_location
  count    = var.create_resource_group ? 1 : 0
}

module "m02_automation_account" {
  source = "git::https://github.com/samirbelkessa/Landing-Zone//Terraform-Azure-LZ/modules/Management/M02-automation-account?ref=756f63f259dad5507e86b03dcce20b69f23879c6"

  workload                      = var.project_name
  schedules                     = local.default_schedules
  runbooks                      = local.default_runbooks
  resource_group_name           = local.rg_name
  region                        = local.primary_region
  public_network_access_enabled = var.automation_public_access
  project                       = var.project
  owner                         = var.owner
  log_analytics_workspace_id    = module.m01_log_analytics[0].id
  location                      = local.rg_location
  local_authentication_enabled  = true
  instance                      = "001"
  identity_type                 = "SystemAssigned"
  environment                   = var.environment
  enable_diagnostic_settings    = false
  department                    = var.department
  data_classification           = var.data_classification
  custom_name                   = var.automation_custom_name
  criticality                   = var.criticality
  create_la_linked_service      = true
  count                         = local.m02_can_deploy ? 1 : 0
  cost_center                   = var.cost_center
  application                   = var.application

  depends_on = [
    module.m01_log_analytics,
  ]


}

module "m03_action_groups" {
  source = "git::https://github.com/samirbelkessa/Landing-Zone//Terraform-Azure-LZ/modules/Management/M03-monitor-action-groups?ref=756f63f259dad5507e86b03dcce20b69f23879c6"

  workload                     = var.project_name
  resource_group_name          = local.rg_name
  region                       = local.primary_region
  project                      = var.project
  owner                        = var.owner
  instance                     = "001"
  environment                  = var.environment
  department                   = var.department
  default_webhook_url          = var.default_webhook_url
  default_email_receivers      = var.default_email_receivers
  data_classification          = var.data_classification
  custom_name                  = var.action_groups_custom_name
  criticality                  = var.criticality
  create_default_action_groups = var.create_default_action_groups
  count                        = local.m03_can_deploy ? 1 : 0
  cost_center                  = var.cost_center
  application                  = var.application
  action_groups                = var.custom_action_groups

  depends_on = [
    azurerm_resource_group.management,
  ]


}

module "m04_monitor_alerts" {
  source = "git::https://github.com/samirbelkessa/Landing-Zone//Terraform-Azure-LZ/modules/Management/M04-monitor-alerts?ref=756f63f259dad5507e86b03dcce20b69f23879c6"

  workload                           = var.project_name
  severity_action_group_mapping      = var.severity_action_group_mapping
  service_health_alert_config        = var.service_health_alert_config
  resource_health_alert_config       = var.resource_health_alert_config
  resource_group_name                = local.rg_name
  region                             = local.location_abbrev[local.primary_location]
  project                            = var.project
  owner                              = var.owner
  log_analytics_workspace_id         = module.m01_log_analytics[0].id
  instance                           = "001"
  environment                        = var.environment
  department                         = var.department
  data_classification                = var.data_classification
  custom_name_prefix                 = var.alerts_custom_name_prefix
  custom_metric_alerts               = var.custom_metric_alerts
  custom_log_query_alerts            = var.custom_log_query_alerts
  custom_activity_log_alerts         = var.custom_activity_log_alerts
  criticality                        = var.criticality
  create_default_alerts              = var.create_default_alerts
  count                              = local.m04_can_deploy ? 1 : 0
  cost_center                        = var.cost_center
  application                        = var.application
  activity_log_security_alert_config = var.activity_log_security_alert_config
  activity_log_admin_alert_config    = var.activity_log_admin_alert_config
  action_group_ids                   = module.m03_action_groups[0].outputs_for_m04.action_group_ids

  subscription_ids = [
  ]

  depends_on = [
    module.m01_log_analytics,
    module.m03_action_groups,
  ]

  additional_tags = {
  }


}

module "law_diagnostics" {
  source = "git::https://github.com/samirbelkessa/Landing-Zone//Terraform-Azure-LZ/modules/Management/M05-diagnostic-settings?ref=756f63f259dad5507e86b03dcce20b69f23879c6"

  target_resource_id             = module.m01_log_analytics[0].id
  tags                           = module.m01_log_analytics[0].tags
  storage_account_id             = var.deploy_m08_diagnostics_storage ? module.m08_diagnostics_storage[0].id : var.diagnostic_settings_config.storage_account_id
  name                           = "diag-${module.m01_log_analytics[0].name}"
  metrics_retention_days         = var.diagnostic_settings_config.metrics_retention_days
  logs_retention_days            = var.diagnostic_settings_config.logs_retention_days
  log_analytics_workspace_id     = module.m01_log_analytics[0].id
  log_analytics_destination_type = var.diagnostic_settings_config.log_analytics_destination_type
  count                          = var.enable_diagnostic_settings && var.diagnostic_settings_config != null ? 1 : 0

  depends_on = [
    module.m01_log_analytics,
    module.m08_diagnostics_storage,
  ]


}

module "automation_diagnostics" {
  source = "git::https://github.com/samirbelkessa/Landing-Zone//Terraform-Azure-LZ/modules/Management/M05-diagnostic-settings?ref=756f63f259dad5507e86b03dcce20b69f23879c6"

  target_resource_id             = module.m02_automation_account[0].id
  tags                           = module.m02_automation_account[0].tags
  storage_account_id             = var.diagnostic_settings_config.storage_account_id
  name                           = "diag-${module.m02_automation_account[0].name}"
  metrics_retention_days         = var.diagnostic_settings_config.metrics_retention_days
  logs_retention_days            = var.diagnostic_settings_config.logs_retention_days
  log_analytics_workspace_id     = module.m01_log_analytics[0].id
  log_analytics_destination_type = var.diagnostic_settings_config.log_analytics_destination_type
  count                          = var.enable_diagnostic_settings && var.diagnostic_settings_config != null ? 1 : 0

  depends_on = [
    module.m02_automation_account,
  ]


}

module "m06_update_management" {
  source = "git::https://github.com/samirbelkessa/Landing-Zone//Terraform-Azure-LZ/modules/Management/M06-update-management?ref=756f63f259dad5507e86b03dcce20b69f23879c6"

  workload                      = var.project_name
  vm_assignments                = var.vm_assignments
  resource_group_name           = local.rg_name
  region                        = local.primary_region
  project                       = var.project
  owner                         = var.owner
  maintenance_configurations    = var.maintenance_configurations
  log_analytics_workspace_id    = var.deploy_m01_log_analytics ? module.m01_log_analytics[0].id : null
  location                      = local.primary_location
  instance                      = var.instance
  environment                   = var.environment
  dynamic_scope_assignments     = var.dynamic_scope_assignments
  department                    = var.department
  default_timezone              = var.default_timezone
  default_target_locations      = var.update_target_locations
  data_classification           = var.data_classification
  custom_name_prefix            = var.update_management_custom_name_prefix
  criticality                   = var.criticality
  create_default_windows_config = var.create_default_windows_config
  create_default_linux_config   = var.create_default_linux_config
  count                         = var.deploy_m06_update_management ? 1 : 0
  cost_center                   = var.cost_center
  application                   = var.application
  additional_tags               = var.update_management_additional_tags
  action_group_ids = var.deploy_m03_action_groups ? {
    critical = module.m03_action_groups[0].action_group_ids["critical"]
    warning  = module.m03_action_groups[0].action_group_ids["warning"]
    info     = module.m03_action_groups[0].action_group_ids["info"]
  } : {}

  depends_on = [
    azurerm_resource_group.management,
    module.m01_log_analytics,
    module.m03_action_groups,
  ]


}

module "m08_diagnostics_storage" {
  source = "git::https://github.com/samirbelkessa/Landing-Zone//Terraform-Azure-LZ/modules/Management/M08-diagnostics-storage-account?ref=756f63f259dad5507e86b03dcce20b69f23879c6"

  workload                               = var.project_name
  shared_access_key_enabled              = var.diagnostics_storage_shared_access_key_enabled
  resource_group_name                    = local.rg_name
  replication_type                       = var.diagnostics_storage_replication_type
  region                                 = local.primary_region
  public_network_access_enabled          = var.diagnostics_storage_public_network_access
  project                                = var.project
  owner                                  = var.owner
  network_rules                          = var.diagnostics_storage_network_rules
  min_tls_version                        = var.diagnostics_storage_min_tls_version
  location                               = local.primary_location
  lifecycle_rules                        = var.diagnostics_storage_lifecycle_rules
  instance                               = var.instance
  infrastructure_encryption_enabled      = var.diagnostics_storage_infrastructure_encryption
  https_traffic_only_enabled             = true
  environment                            = var.environment
  enable_versioning                      = var.diagnostics_storage_versioning_enabled
  enable_lifecycle_management            = var.diagnostics_storage_enable_lifecycle
  enable_diagnostic_settings             = false
  enable_change_feed                     = var.diagnostics_storage_change_feed_enabled
  diagnostic_logs_retention_days         = 90
  department                             = var.department
  default_to_oauth_authentication        = true
  default_lifecycle_tier_to_cool_days    = var.diagnostics_storage_tier_to_cool_days
  default_lifecycle_tier_to_archive_days = var.diagnostics_storage_tier_to_archive_days
  default_lifecycle_delete_days          = var.diagnostics_storage_delete_days
  default_container_access_type          = "private"
  data_classification                    = var.data_classification
  custom_name                            = var.diagnostics_storage_custom_name
  criticality                            = var.criticality
  create_default_containers              = var.diagnostics_storage_create_default_containers
  count                                  = local.m08_can_deploy ? 1 : 0
  cost_center                            = var.cost_center
  container_soft_delete_retention_days   = var.diagnostics_storage_container_retention_days
  change_feed_retention_in_days          = var.diagnostics_storage_change_feed_retention_days
  blob_soft_delete_retention_days        = var.diagnostics_storage_blob_retention_days
  application                            = var.application
  allow_nested_items_to_be_public        = false
  additional_tags                        = var.diagnostics_storage_additional_tags
  additional_containers                  = var.diagnostics_storage_additional_containers
  account_tier                           = var.diagnostics_storage_account_tier
  account_kind                           = var.diagnostics_storage_account_kind
  access_tier                            = var.diagnostics_storage_access_tier

  depends_on = [
    azurerm_resource_group.management,
  ]


}

module "m08_blob_diagnostics" {
  source = "git::https://github.com/samirbelkessa/Landing-Zone//Terraform-Azure-LZ/modules/Management/M05-diagnostic-settings?ref=756f63f259dad5507e86b03dcce20b69f23879c6"

  target_resource_id             = "${module.m08_diagnostics_storage[0].id}/blobServices/default"
  tags                           = module.m08_diagnostics_storage[0].tags
  name                           = "diag-${module.m08_diagnostics_storage[0].name}-blob"
  metrics_retention_days         = 90
  logs_retention_days            = 90
  log_analytics_workspace_id     = module.m01_log_analytics[0].id
  log_analytics_destination_type = "Dedicated"
  count                          = local.m08_self_diagnostics_can_deploy ? 1 : 0

  enabled_metric_categories = [
    "Transaction",
    "Capacity",
  ]

  enabled_log_categories = [
    "StorageRead",
    "StorageWrite",
    "StorageDelete",
  ]

  depends_on = [
    module.m01_log_analytics,
    module.m08_diagnostics_storage,
  ]


}

module "m08_self_diagnostics" {
  source = "git::https://github.com/samirbelkessa/Landing-Zone//Terraform-Azure-LZ/modules/Management/M05-diagnostic-settings?ref=756f63f259dad5507e86b03dcce20b69f23879c6"

  target_resource_id             = module.m08_diagnostics_storage[0].id
  tags                           = module.m08_diagnostics_storage[0].tags
  name                           = "diag-${module.m08_diagnostics_storage[0].name}"
  metrics_retention_days         = 90
  logs_retention_days            = 90
  log_analytics_workspace_id     = module.m01_log_analytics[0].id
  log_analytics_destination_type = "Dedicated"
  count                          = local.m08_self_diagnostics_can_deploy ? 1 : 0

  enabled_metric_categories = [
    "Transaction",
    "Capacity",
  ]

  depends_on = [
    module.m01_log_analytics,
    module.m08_diagnostics_storage,
  ]


}

resource "azurerm_log_analytics_linked_storage_account" "custom_logs" {
  workspace_resource_id = module.m01_log_analytics[0].id
  resource_group_name   = azurerm_resource_group.management[count.index].name
  data_source_type      = "CustomLogs"
  count                 = local.link_storage_to_la ? 1 : 0

  storage_account_ids = [
    module.m08_diagnostics_storage[0].id,
  ]
}

resource "azurerm_log_analytics_linked_storage_account" "query" {
  workspace_resource_id = module.m01_log_analytics[0].id
  resource_group_name   = azurerm_resource_group.management[count.index].name
  data_source_type      = "Query"
  count                 = local.link_storage_to_la ? 1 : 0

  storage_account_ids = [
    module.m08_diagnostics_storage[0].id,
  ]
}

resource "azurerm_log_analytics_linked_storage_account" "alerts" {
  workspace_resource_id = module.m01_log_analytics[0].id
  resource_group_name   = azurerm_resource_group.management[count.index].name
  data_source_type      = "Alerts"
  count                 = local.link_storage_to_la ? 1 : 0

  storage_account_ids = [
    module.m08_diagnostics_storage[0].id,
  ]
}

module "m01_log_analytics" {
  source = "git::https://github.com/samirbelkessa/Landing-Zone//Terraform-Azure-LZ/modules/Management/M01-log-analytics-workspace?ref=756f63f259dad5507e86b03dcce20b69f23879c6"

  workload                      = var.project_name
  total_retention_in_days       = var.log_analytics_total_retention_days
  sku                           = var.log_analytics_sku
  secondary_retention_in_days   = 30
  secondary_location            = local.secondary_location
  retention_in_days             = var.log_analytics_retention_days
  resource_group_name           = local.rg_name
  region                        = local.primary_region
  project                       = var.project
  owner                         = var.owner
  location                      = local.rg_location
  instance                      = "001"
  environment                   = var.environment
  enable_table_level_archive    = true
  enable_diagnostic_settings    = var.deploy_m08_diagnostics_storage && var.enable_m01_archive_to_storage
  enable_cross_region_workspace = var.enable_log_analytics_dr
  diagnostic_storage_account_id = var.deploy_m08_diagnostics_storage ? module.m08_diagnostics_storage[0].id : null
  deploy_solutions              = true
  department                    = var.department
  data_classification           = var.data_classification
  custom_name                   = var.log_analytics_custom_name
  criticality                   = var.criticality
  count                         = var.deploy_m01_log_analytics ? 1 : 0
  cost_center                   = var.cost_center
  application                   = var.application

  solutions = [
    { name = "SecurityInsights", publisher = "Microsoft" },
    { name = "AzureActivity", publisher = "Microsoft" },
    { name = "ChangeTracking", publisher = "Microsoft" },
    { name = "Updates", publisher = "Microsoft" },
    { name = "VMInsights", publisher = "Microsoft" },
    { name = "ServiceMap", publisher = "Microsoft" },
    { name = "AgentHealthAssessment", publisher = "Microsoft" },
  ]


  depends_on = [
    azurerm_resource_group.management,
    module.m08_diagnostics_storage,
  ]

  archive_tables = {
    Syslog        = 400
    SigninLogs    = 400
    SecurityEvent = 400
    Perf          = 180
    AzureMetrics  = 180
    AzureActivity = 400
    AuditLogs     = 400
  }


}

module "m07_data_collection_rules" {
  source = "git::https://github.com/samirbelkessa/Landing-Zone//Terraform-Azure-LZ/modules/Management/M07-data-collection-rules?ref=756f63f..."

  tags                              = local.dcr_tags
  enable_associations               = var.enable_dcr_associations
  data_collection_rules             = local.all_dcr_configurations
  data_collection_rule_associations = var.enable_dcr_associations ? {} : {}
  count                             = var.deploy_m07_dcr ? 1 : 0

  depends_on = [
    azurerm_resource_group.management,
    module.m01_log_analytics,
  ]


}

module "tags_rg" {
  source = "git::https://github.com/samirbelkessa/Landing-Zone//Terraform-Azure-LZ/modules/Fondations/F03-tags?ref=756f63f259dad5507e86b03dcce20b69f23879c6"

  project             = var.project
  owner               = var.owner
  environment         = "Production"
  department          = var.department
  data_classification = var.data_classification
  criticality         = var.criticality
  cost_center         = var.cost_center
  application         = var.application


}

