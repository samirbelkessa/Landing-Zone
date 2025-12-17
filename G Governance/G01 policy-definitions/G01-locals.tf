################################################################################
# Local Values
################################################################################

locals {
  # Module identification tags
  module_tags = {
    ManagedBy = "Terraform"
    Module    = "policy-definitions"
  }

  # Extract management group name from ID for naming policies
  mg_name = element(split("/", var.management_group_id), length(split("/", var.management_group_id)) - 1)

  #-----------------------------------------------------------------------------
  # CAF Policy Definitions - Network Category
  #-----------------------------------------------------------------------------
  network_policies = var.enable_network_policies ? {
    # Hub VNet existence validation
    "audit-hub-vnet-australia-east" = {
      name        = "Audit Hub VNet in Australia East"
      description = "Audits that a Hub Virtual Network exists in Australia East region. Required for hub-spoke topology."
      mode        = "All"
      metadata = {
        category = "Network"
        version  = "1.0.0"
      }
      parameters = {}
      policy_rule = {
        if = {
          allOf = [
            {
              field  = "type"
              equals = "Microsoft.Network/virtualNetworks"
            },
            {
              field  = "location"
              equals = "australiaeast"
            },
            {
              field    = "tags['NetworkType']"
              notEquals = "Hub"
            }
          ]
        }
        then = {
          effect = "audit"
        }
      }
    }

    # Route table must route to Firewall
    "audit-route-to-firewall" = {
      name        = "Audit routes to Azure Firewall"
      description = "Audits that route tables have a default route (0.0.0.0/0) pointing to Azure Firewall for internet-bound traffic."
      mode        = "Indexed"
      metadata = {
        category = "Network"
        version  = "1.0.0"
      }
      parameters = {
        effect = {
          type          = "String"
          defaultValue  = "Audit"
          allowedValues = ["Audit", "Disabled"]
          metadata = {
            displayName = "Effect"
            description = "Enable or disable the policy"
          }
        }
      }
      policy_rule = {
        if = {
          allOf = [
            {
              field  = "type"
              equals = "Microsoft.Network/routeTables"
            },
            {
              count = {
                field = "Microsoft.Network/routeTables/routes[*]"
                where = {
                  allOf = [
                    {
                      field  = "Microsoft.Network/routeTables/routes[*].addressPrefix"
                      equals = "0.0.0.0/0"
                    },
                    {
                      field  = "Microsoft.Network/routeTables/routes[*].nextHopType"
                      equals = "VirtualAppliance"
                    }
                  ]
                }
              }
              equals = 0
            }
          ]
        }
        then = {
          effect = "[parameters('effect')]"
        }
      }
    }

    # Azure Firewall Premium validation
    "audit-firewall-premium" = {
      name        = "Audit Azure Firewall Premium SKU"
      description = "Audits that Azure Firewall uses Premium SKU for advanced threat protection features."
      mode        = "Indexed"
      metadata = {
        category = "Network"
        version  = "1.0.0"
      }
      parameters = {}
      policy_rule = {
        if = {
          allOf = [
            {
              field  = "type"
              equals = "Microsoft.Network/azureFirewalls"
            },
            {
              field    = "Microsoft.Network/azureFirewalls/sku.tier"
              notEquals = "Premium"
            }
          ]
        }
        then = {
          effect = "audit"
        }
      }
    }

    # Private DNS zones linked to Hub
    "audit-private-dns-hub-link" = {
      name        = "Audit Private DNS zones linked to Hub VNet"
      description = "Audits that Private DNS zones are linked to the Hub VNet for consistent name resolution."
      mode        = "All"
      metadata = {
        category = "Network"
        version  = "1.0.0"
      }
      parameters = {
        hubVnetId = {
          type = "String"
          metadata = {
            displayName = "Hub VNet Resource ID"
            description = "Resource ID of the Hub Virtual Network"
          }
        }
        effect = {
          type          = "String"
          defaultValue  = "Audit"
          allowedValues = ["Audit", "Disabled"]
          metadata = {
            displayName = "Effect"
            description = "Enable or disable the policy"
          }
        }
      }
      policy_rule = {
        if = {
          allOf = [
            {
              field  = "type"
              equals = "Microsoft.Network/privateDnsZones"
            },
            {
              count = {
                field = "Microsoft.Network/privateDnsZones/virtualNetworkLinks[*]"
                where = {
                  field  = "Microsoft.Network/privateDnsZones/virtualNetworkLinks[*].virtualNetwork.id"
                  equals = "[parameters('hubVnetId')]"
                }
              }
              equals = 0
            }
          ]
        }
        then = {
          effect = "[parameters('effect')]"
        }
      }
    }

    # VNet peered to Hub validation
    "audit-vnet-peered-to-hub" = {
      name        = "Audit VNets are peered to Hub"
      description = "Audits that spoke Virtual Networks are peered to the Hub VNet for hub-spoke connectivity."
      mode        = "All"
      metadata = {
        category = "Network"
        version  = "1.0.0"
      }
      parameters = {
        hubVnetId = {
          type = "String"
          metadata = {
            displayName = "Hub VNet Resource ID"
            description = "Resource ID of the Hub Virtual Network"
          }
        }
        effect = {
          type          = "String"
          defaultValue  = "Audit"
          allowedValues = ["Audit", "Disabled"]
          metadata = {
            displayName = "Effect"
            description = "Enable or disable the policy"
          }
        }
      }
      policy_rule = {
        if = {
          allOf = [
            {
              field  = "type"
              equals = "Microsoft.Network/virtualNetworks"
            },
            {
              field    = "tags['NetworkType']"
              notEquals = "Hub"
            },
            {
              count = {
                field = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings[*]"
                where = {
                  field  = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings[*].remoteVirtualNetwork.id"
                  equals = "[parameters('hubVnetId')]"
                }
              }
              equals = 0
            }
          ]
        }
        then = {
          effect = "[parameters('effect')]"
        }
      }
    }

    # Public IP via AppGW/FrontDoor only
    "audit-public-ip-appgw-frontdoor" = {
      name        = "Audit Public IPs via Application Gateway or Front Door only"
      description = "Audits that public IP addresses are associated only with Application Gateway or Azure Front Door, not directly with VMs or NICs."
      mode        = "Indexed"
      metadata = {
        category = "Network"
        version  = "1.0.0"
      }
      parameters = {
        effect = {
          type          = "String"
          defaultValue  = "Audit"
          allowedValues = ["Audit", "Deny", "Disabled"]
          metadata = {
            displayName = "Effect"
            description = "Enable or disable the policy"
          }
        }
      }
      policy_rule = {
        if = {
          allOf = [
            {
              field  = "type"
              equals = "Microsoft.Network/publicIPAddresses"
            },
            {
              anyOf = [
                {
                  field    = "Microsoft.Network/publicIPAddresses/ipConfiguration.id"
                  contains = "/networkInterfaces/"
                },
                {
                  field    = "Microsoft.Network/publicIPAddresses/ipConfiguration.id"
                  contains = "/virtualMachines/"
                }
              ]
            }
          ]
        }
        then = {
          effect = "[parameters('effect')]"
        }
      }
    }

    # DDoS Standard NOT required (Cloudflare)
    "disabled-ddos-standard" = {
      name        = "DDoS Standard NOT Required (Cloudflare Protected)"
      description = "Informational policy - DDoS Standard protection plan is not required as applications are protected by Cloudflare."
      mode        = "All"
      metadata = {
        category = "Network"
        version  = "1.0.0"
        note     = "DDoS Standard is disabled for this organization as Cloudflare provides DDoS protection"
      }
      parameters = {}
      policy_rule = {
        if = {
          field  = "type"
          equals = "Microsoft.Network/ddosProtectionPlans"
        }
        then = {
          effect = "disabled"
        }
      }
    }
  } : {}

  #-----------------------------------------------------------------------------
  # CAF Policy Definitions - Security Category
  #-----------------------------------------------------------------------------
  security_policies = var.enable_security_policies ? {
    # Storage deny public access
    "deny-storage-public-access" = {
      name        = "Deny Storage Account Public Access"
      description = "Denies storage accounts with public blob or container access enabled. Storage must be accessed via private endpoints."
      mode        = "Indexed"
      metadata = {
        category = "Storage"
        version  = "1.0.0"
      }
      parameters = {
        effect = {
          type          = "String"
          defaultValue  = "Deny"
          allowedValues = ["Audit", "Deny", "Disabled"]
          metadata = {
            displayName = "Effect"
            description = "Enable or disable the policy"
          }
        }
      }
      policy_rule = {
        if = {
          allOf = [
            {
              field  = "type"
              equals = "Microsoft.Storage/storageAccounts"
            },
            {
              field    = "Microsoft.Storage/storageAccounts/allowBlobPublicAccess"
              notEquals = false
            }
          ]
        }
        then = {
          effect = "[parameters('effect')]"
        }
      }
    }

    # Private endpoints required for SQL
    "deny-sql-without-private-endpoint" = {
      name        = "Deny Azure SQL without Private Endpoint"
      description = "Denies Azure SQL Servers that allow public network access. Private endpoints must be used."
      mode        = "Indexed"
      metadata = {
        category = "SQL"
        version  = "1.0.0"
      }
      parameters = {
        effect = {
          type          = "String"
          defaultValue  = "Deny"
          allowedValues = ["Audit", "Deny", "Disabled"]
          metadata = {
            displayName = "Effect"
            description = "Enable or disable the policy"
          }
        }
      }
      policy_rule = {
        if = {
          allOf = [
            {
              field  = "type"
              equals = "Microsoft.Sql/servers"
            },
            {
              field    = "Microsoft.Sql/servers/publicNetworkAccess"
              notEquals = "Disabled"
            }
          ]
        }
        then = {
          effect = "[parameters('effect')]"
        }
      }
    }

    # Private endpoints required for Cosmos DB
    "deny-cosmos-without-private-endpoint" = {
      name        = "Deny Cosmos DB without Private Endpoint"
      description = "Denies Cosmos DB accounts that allow public network access. Private endpoints must be used."
      mode        = "Indexed"
      metadata = {
        category = "Cosmos DB"
        version  = "1.0.0"
      }
      parameters = {
        effect = {
          type          = "String"
          defaultValue  = "Deny"
          allowedValues = ["Audit", "Deny", "Disabled"]
          metadata = {
            displayName = "Effect"
            description = "Enable or disable the policy"
          }
        }
      }
      policy_rule = {
        if = {
          allOf = [
            {
              field  = "type"
              equals = "Microsoft.DocumentDB/databaseAccounts"
            },
            {
              field    = "Microsoft.DocumentDB/databaseAccounts/publicNetworkAccess"
              notEquals = "Disabled"
            }
          ]
        }
        then = {
          effect = "[parameters('effect')]"
        }
      }
    }

    # Private endpoints required for App Service
    "audit-app-service-private-endpoint" = {
      name        = "Audit App Service Private Endpoint"
      description = "Audits that App Services use private endpoints for inbound connectivity."
      mode        = "Indexed"
      metadata = {
        category = "App Service"
        version  = "1.0.0"
      }
      parameters = {
        effect = {
          type          = "String"
          defaultValue  = "Audit"
          allowedValues = ["Audit", "Deny", "Disabled"]
          metadata = {
            displayName = "Effect"
            description = "Enable or disable the policy"
          }
        }
      }
      policy_rule = {
        if = {
          allOf = [
            {
              field  = "type"
              equals = "Microsoft.Web/sites"
            },
            {
              field    = "Microsoft.Web/sites/publicNetworkAccess"
              notEquals = "Disabled"
            }
          ]
        }
        then = {
          effect = "[parameters('effect')]"
        }
      }
    }
  } : {}

  #-----------------------------------------------------------------------------
  # CAF Policy Definitions - Monitoring Category
  #-----------------------------------------------------------------------------
  monitoring_policies = var.enable_monitoring_policies ? {
    # Deploy diagnostic settings to Log Analytics
    "deploy-diagnostic-settings-la" = {
      name        = "Deploy Diagnostic Settings to Log Analytics"
      description = "Deploys diagnostic settings for supported resources to send logs and metrics to the central Log Analytics workspace."
      mode        = "Indexed"
      metadata = {
        category = "Monitoring"
        version  = "1.0.0"
      }
      parameters = {
        logAnalyticsWorkspaceId = {
          type = "String"
          metadata = {
            displayName = "Log Analytics Workspace ID"
            description = "Resource ID of the central Log Analytics workspace"
          }
        }
        effect = {
          type          = "String"
          defaultValue  = "DeployIfNotExists"
          allowedValues = ["DeployIfNotExists", "AuditIfNotExists", "Disabled"]
          metadata = {
            displayName = "Effect"
            description = "Enable or disable the policy"
          }
        }
      }
      policy_rule = {
        if = {
          allOf = [
            {
              field = "type"
              in = [
                "Microsoft.KeyVault/vaults",
                "Microsoft.Network/applicationGateways",
                "Microsoft.Network/azureFirewalls",
                "Microsoft.Network/networkSecurityGroups",
                "Microsoft.Sql/servers/databases",
                "Microsoft.Web/sites"
              ]
            }
          ]
        }
        then = {
          effect = "[parameters('effect')]"
          details = {
            type              = "Microsoft.Insights/diagnosticSettings"
            roleDefinitionIds = ["/providers/Microsoft.Authorization/roleDefinitions/749f88d5-cbae-40b8-bcfc-e573ddc772fa"]
            existenceCondition = {
              field  = "Microsoft.Insights/diagnosticSettings/workspaceId"
              equals = "[parameters('logAnalyticsWorkspaceId')]"
            }
            deployment = {
              properties = {
                mode = "incremental"
                template = {
                  "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
                  contentVersion = "1.0.0.0"
                  parameters = {
                    resourceName = { type = "string" }
                    location     = { type = "string" }
                    workspaceId  = { type = "string" }
                  }
                  resources = [
                    {
                      type       = "Microsoft.Insights/diagnosticSettings"
                      apiVersion = "2021-05-01-preview"
                      name       = "setByPolicy"
                      scope      = "[concat(resourceGroup().id, '/providers/', parameters('resourceType'), '/', parameters('resourceName'))]"
                      location   = "[parameters('location')]"
                      properties = {
                        workspaceId = "[parameters('workspaceId')]"
                        logs = [
                          {
                            categoryGroup = "allLogs"
                            enabled       = true
                          }
                        ]
                        metrics = [
                          {
                            category = "AllMetrics"
                            enabled  = true
                          }
                        ]
                      }
                    }
                  ]
                }
                parameters = {
                  resourceName = { value = "[field('name')]" }
                  location     = { value = "[field('location')]" }
                  workspaceId  = { value = "[parameters('logAnalyticsWorkspaceId')]" }
                }
              }
            }
          }
        }
      }
    }

    # Log Analytics retention minimum
    "audit-la-retention-minimum" = {
      name        = "Audit Log Analytics Retention Minimum ${var.log_retention_days} Days"
      description = "Audits that Log Analytics workspaces have at least ${var.log_retention_days} days interactive retention."
      mode        = "Indexed"
      metadata = {
        category = "Monitoring"
        version  = "1.0.0"
      }
      parameters = {
        minimumRetentionDays = {
          type         = "Integer"
          defaultValue = var.log_retention_days
          metadata = {
            displayName = "Minimum Retention Days"
            description = "Minimum number of days for interactive log retention"
          }
        }
        effect = {
          type          = "String"
          defaultValue  = "Audit"
          allowedValues = ["Audit", "Disabled"]
          metadata = {
            displayName = "Effect"
            description = "Enable or disable the policy"
          }
        }
      }
      policy_rule = {
        if = {
          allOf = [
            {
              field  = "type"
              equals = "Microsoft.OperationalInsights/workspaces"
            },
            {
              field = "Microsoft.OperationalInsights/workspaces/retentionInDays"
              less  = "[parameters('minimumRetentionDays')]"
            }
          ]
        }
        then = {
          effect = "[parameters('effect')]"
        }
      }
    }

    # Log Analytics archive enabled
    "audit-la-archive-enabled" = {
      name        = "Audit Log Analytics Archive Enabled"
      description = "Audits that Log Analytics workspaces have table-level archive enabled for long-term retention (1.1 years total)."
      mode        = "All"
      metadata = {
        category = "Monitoring"
        version  = "1.0.0"
        note     = "Archive configuration is at table level, this policy checks workspace configuration"
      }
      parameters = {
        effect = {
          type          = "String"
          defaultValue  = "Audit"
          allowedValues = ["Audit", "Disabled"]
          metadata = {
            displayName = "Effect"
            description = "Enable or disable the policy"
          }
        }
      }
      policy_rule = {
        if = {
          field  = "type"
          equals = "Microsoft.OperationalInsights/workspaces"
        }
        then = {
          effect = "[parameters('effect')]"
        }
      }
    }

    # Sentinel connectors enabled
    "audit-sentinel-connectors" = {
      name        = "Audit Sentinel Connectors Enabled"
      description = "Audits that Microsoft Sentinel has required data connectors enabled."
      mode        = "All"
      metadata = {
        category = "Security Center"
        version  = "1.0.0"
      }
      parameters = {
        effect = {
          type          = "String"
          defaultValue  = "Audit"
          allowedValues = ["Audit", "Disabled"]
          metadata = {
            displayName = "Effect"
            description = "Enable or disable the policy"
          }
        }
      }
      policy_rule = {
        if = {
          field  = "type"
          equals = "Microsoft.SecurityInsights/dataConnectors"
        }
        then = {
          effect = "[parameters('effect')]"
        }
      }
    }
  } : {}

  #-----------------------------------------------------------------------------
  # CAF Policy Definitions - Backup Category
  #-----------------------------------------------------------------------------
  backup_policies = var.enable_backup_policies ? {
    # Backup GRS required for Production
    "audit-backup-grs-production" = {
      name        = "Audit Backup GRS for Production"
      description = "Audits that Recovery Services vaults in production environments use Geo-Redundant Storage (GRS) with cross-region restore enabled."
      mode        = "Indexed"
      metadata = {
        category = "Backup"
        version  = "1.0.0"
      }
      parameters = {
        effect = {
          type          = "String"
          defaultValue  = "Audit"
          allowedValues = ["Audit", "Deny", "Disabled"]
          metadata = {
            displayName = "Effect"
            description = "Enable or disable the policy"
          }
        }
      }
      policy_rule = {
        if = {
          allOf = [
            {
              field  = "type"
              equals = "Microsoft.RecoveryServices/vaults"
            },
            {
              anyOf = [
                {
                  field  = "tags['Environment']"
                  equals = "Production"
                },
                {
                  field  = "tags['Environment']"
                  equals = "Prod"
                }
              ]
            },
            {
              anyOf = [
                {
                  field    = "Microsoft.RecoveryServices/vaults/redundancySettings.standardTierStorageRedundancy"
                  notEquals = "GeoRedundant"
                },
                {
                  field    = "Microsoft.RecoveryServices/vaults/redundancySettings.crossRegionRestore"
                  notEquals = "Enabled"
                }
              ]
            }
          ]
        }
        then = {
          effect = "[parameters('effect')]"
        }
      }
    }

    # Backup LRS sufficient for Non-Production
    "audit-backup-lrs-nonproduction" = {
      name        = "Audit Backup LRS for Non-Production"
      description = "Informational policy - Locally Redundant Storage (LRS) is sufficient for non-production Recovery Services vaults."
      mode        = "Indexed"
      metadata = {
        category = "Backup"
        version  = "1.0.0"
        note     = "LRS is acceptable for non-production to reduce costs"
      }
      parameters = {
        effect = {
          type          = "String"
          defaultValue  = "Audit"
          allowedValues = ["Audit", "Disabled"]
          metadata = {
            displayName = "Effect"
            description = "Enable or disable the policy"
          }
        }
      }
      policy_rule = {
        if = {
          allOf = [
            {
              field  = "type"
              equals = "Microsoft.RecoveryServices/vaults"
            },
            {
              anyOf = [
                {
                  field  = "tags['Environment']"
                  equals = "Development"
                },
                {
                  field  = "tags['Environment']"
                  equals = "Dev"
                },
                {
                  field  = "tags['Environment']"
                  equals = "Test"
                },
                {
                  field  = "tags['Environment']"
                  equals = "NonProd"
                }
              ]
            }
          ]
        }
        then = {
          effect = "[parameters('effect')]"
        }
      }
    }
  } : {}

  #-----------------------------------------------------------------------------
  # CAF Policy Definitions - Cost Category
  #-----------------------------------------------------------------------------
  cost_policies = var.enable_cost_policies ? {
    # Budget configured
    "audit-budget-configured" = {
      name        = "Audit Budget Configured"
      description = "Audits that resource groups and subscriptions have budgets configured for cost management."
      mode        = "All"
      metadata = {
        category = "Cost Management"
        version  = "1.0.0"
      }
      parameters = {
        effect = {
          type          = "String"
          defaultValue  = "Audit"
          allowedValues = ["Audit", "Disabled"]
          metadata = {
            displayName = "Effect"
            description = "Enable or disable the policy"
          }
        }
      }
      policy_rule = {
        if = {
          field  = "type"
          equals = "Microsoft.Resources/subscriptions/resourceGroups"
        }
        then = {
          effect = "[parameters('effect')]"
        }
      }
    }

    # Allowed VM SKUs for Sandbox
    "deny-expensive-vm-skus-sandbox" = {
      name        = "Deny Expensive VM SKUs in Sandbox"
      description = "Denies VM SKUs outside the approved list for Sandbox environments to control costs."
      mode        = "Indexed"
      metadata = {
        category = "Compute"
        version  = "1.0.0"
      }
      parameters = {
        allowedSkus = {
          type         = "Array"
          defaultValue = var.allowed_vm_skus_sandbox
          metadata = {
            displayName = "Allowed VM SKUs"
            description = "List of allowed VM SKUs in Sandbox"
          }
        }
        effect = {
          type          = "String"
          defaultValue  = "Deny"
          allowedValues = ["Audit", "Deny", "Disabled"]
          metadata = {
            displayName = "Effect"
            description = "Enable or disable the policy"
          }
        }
      }
      policy_rule = {
        if = {
          allOf = [
            {
              field  = "type"
              equals = "Microsoft.Compute/virtualMachines"
            },
            {
              field  = "Microsoft.Compute/virtualMachines/sku.name"
              notIn = "[parameters('allowedSkus')]"
            }
          ]
        }
        then = {
          effect = "[parameters('effect')]"
        }
      }
    }

    # Deny expensive resources in Sandbox
    "deny-expensive-resources-sandbox" = {
      name        = "Deny Expensive Resources in Sandbox"
      description = "Denies creation of expensive resource types in Sandbox environments (ExpressRoute, Premium SKUs)."
      mode        = "All"
      metadata = {
        category = "Cost Management"
        version  = "1.0.0"
      }
      parameters = {
        deniedResourceTypes = {
          type         = "Array"
          defaultValue = var.expensive_resource_types
          metadata = {
            displayName = "Denied Resource Types"
            description = "List of expensive resource types to deny"
          }
        }
        effect = {
          type          = "String"
          defaultValue  = "Deny"
          allowedValues = ["Audit", "Deny", "Disabled"]
          metadata = {
            displayName = "Effect"
            description = "Enable or disable the policy"
          }
        }
      }
      policy_rule = {
        if = {
          field = "type"
          in    = "[parameters('deniedResourceTypes')]"
        }
        then = {
          effect = "[parameters('effect')]"
        }
      }
    }
  } : {}

  #-----------------------------------------------------------------------------
  # CAF Policy Definitions - Lifecycle Category
  #-----------------------------------------------------------------------------
  lifecycle_policies = var.enable_lifecycle_policies ? {
    # Expiration tag required for Sandbox
    "deny-sandbox-without-expiration" = {
      name        = "Deny Sandbox Resources Without Expiration Tag"
      description = "Denies creation of resources in Sandbox without an 'Expiration' tag specifying when the resource should be deleted."
      mode        = "Indexed"
      metadata = {
        category = "Tags"
        version  = "1.0.0"
      }
      parameters = {
        tagName = {
          type         = "String"
          defaultValue = "Expiration"
          metadata = {
            displayName = "Tag Name"
            description = "Name of the expiration tag"
          }
        }
        effect = {
          type          = "String"
          defaultValue  = "Deny"
          allowedValues = ["Audit", "Deny", "Disabled"]
          metadata = {
            displayName = "Effect"
            description = "Enable or disable the policy"
          }
        }
      }
      policy_rule = {
        if = {
          field  = "[concat('tags[', parameters('tagName'), ']')]"
          exists = "false"
        }
        then = {
          effect = "[parameters('effect')]"
        }
      }
    }

    # Audit only mode for Sandbox
    "audit-only-sandbox" = {
      name        = "Audit Only Mode for Sandbox"
      description = "Marker policy for Sandbox environments - all policies should use Audit effect instead of Deny."
      mode        = "All"
      metadata = {
        category = "General"
        version  = "1.0.0"
        note     = "This is a reference policy for Sandbox behavior"
      }
      parameters = {}
      policy_rule = {
        if = {
          field  = "type"
          equals = "Microsoft.Resources/subscriptions/resourceGroups"
        }
        then = {
          effect = "audit"
        }
      }
    }
  } : {}

  #-----------------------------------------------------------------------------
  # CAF Policy Definitions - Decommissioned Category
  #-----------------------------------------------------------------------------
  decommissioned_policies = {
    # Deny all resource creation
    "deny-all-resource-creation" = {
      name        = "Deny All Resource Creation"
      description = "Denies creation of any resources. Used for decommissioned subscriptions."
      mode        = "All"
      metadata = {
        category = "General"
        version  = "1.0.0"
      }
      parameters = {}
      policy_rule = {
        if = {
          not = {
            field  = "type"
            equals = "Microsoft.Resources/subscriptions/resourceGroups"
          }
        }
        then = {
          effect = "deny"
        }
      }
    }

    # Deny all resource modification
    "deny-all-resource-modification" = {
      name        = "Deny All Resource Modification"
      description = "Denies modification of any existing resources. Used for decommissioned subscriptions."
      mode        = "All"
      metadata = {
        category = "General"
        version  = "1.0.0"
      }
      parameters = {}
      policy_rule = {
        if = {
          field    = "type"
          notEquals = ""
        }
        then = {
          effect = "deny"
        }
      }
    }
  }

  #-----------------------------------------------------------------------------
  # Merge all CAF policies when enabled
  #-----------------------------------------------------------------------------
  caf_policy_definitions = var.deploy_caf_policies ? merge(
    local.network_policies,
    local.security_policies,
    local.monitoring_policies,
    local.backup_policies,
    local.cost_policies,
    local.lifecycle_policies,
    local.decommissioned_policies
  ) : {}

  #-----------------------------------------------------------------------------
  # Final merged policy definitions (CAF + Custom)
  #-----------------------------------------------------------------------------
  all_policy_definitions = merge(
    local.caf_policy_definitions,
    var.custom_policy_definitions
  )
}
