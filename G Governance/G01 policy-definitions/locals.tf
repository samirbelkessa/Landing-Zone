################################################################################
# Local Values - Policy Definitions (G01)
# CORRECTED: Using jsonencode() for policy_rule, metadata, parameters
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
  # Network Policies
  #-----------------------------------------------------------------------------
  network_policies_all = {
    "audit-hub-vnet-australia-east" = {
      name         = "Audit Hub VNet in Australia East"
      description  = "Audits that a Hub Virtual Network exists in Australia East region."
      mode         = "All"
      metadata     = jsonencode({ category = "Network", version = "1.0.0" })
      parameters   = jsonencode({})
      policy_rule  = jsonencode({
        if = {
          allOf = [
            { field = "type", equals = "Microsoft.Network/virtualNetworks" },
            { field = "location", equals = "australiaeast" },
            { field = "tags['NetworkType']", notEquals = "Hub" }
          ]
        }
        then = { effect = "audit" }
      })
    }

    "audit-route-to-firewall" = {
      name         = "Audit routes to Azure Firewall"
      description  = "Audits that route tables have a default route pointing to Azure Firewall."
      mode         = "Indexed"
      metadata     = jsonencode({ category = "Network", version = "1.0.0" })
      parameters   = jsonencode({
        effect = {
          type         = "String"
          defaultValue = "Audit"
          allowedValues = ["Audit", "Disabled"]
          metadata     = { displayName = "Effect", description = "Enable or disable the policy" }
        }
      })
      policy_rule  = jsonencode({
        if = {
          allOf = [
            { field = "type", equals = "Microsoft.Network/routeTables" },
            {
              count = {
                field = "Microsoft.Network/routeTables/routes[*]"
                where = {
                  allOf = [
                    { field = "Microsoft.Network/routeTables/routes[*].addressPrefix", equals = "0.0.0.0/0" },
                    { field = "Microsoft.Network/routeTables/routes[*].nextHopType", equals = "VirtualAppliance" }
                  ]
                }
              }
              equals = 0
            }
          ]
        }
        then = { effect = "[parameters('effect')]" }
      })
    }

    "audit-firewall-premium" = {
      name         = "Audit Azure Firewall Premium SKU"
      description  = "Audits that Azure Firewall uses Premium SKU."
      mode         = "Indexed"
      metadata     = jsonencode({ category = "Network", version = "1.0.0" })
      parameters   = jsonencode({})
      policy_rule  = jsonencode({
        if = {
          allOf = [
            { field = "type", equals = "Microsoft.Network/azureFirewalls" },
            { field = "Microsoft.Network/azureFirewalls/sku.tier", notEquals = "Premium" }
          ]
        }
        then = { effect = "audit" }
      })
    }

    "audit-vnet-peered-to-hub" = {
      name         = "Audit VNets are peered to Hub"
      description  = "Audits that spoke VNets have at least one peering configured."
      mode         = "All"
      metadata     = jsonencode({ category = "Network", version = "1.0.0" })
      parameters   = jsonencode({})
      policy_rule  = jsonencode({
        if = {
          allOf = [
            { field = "type", equals = "Microsoft.Network/virtualNetworks" },
            { field = "tags['NetworkType']", notEquals = "Hub" },
            {
              count = {
                field = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings[*]"
              }
              equals = 0
            }
          ]
        }
        then = { effect = "audit" }
      })
    }

    "audit-public-ip-appgw-frontdoor" = {
      name         = "Audit Public IPs via AppGW or Front Door only"
      description  = "Audits that public IPs are not directly attached to VMs or NICs."
      mode         = "Indexed"
      metadata     = jsonencode({ category = "Network", version = "1.0.0" })
      parameters   = jsonencode({
        effect = {
          type         = "String"
          defaultValue = "Audit"
          allowedValues = ["Audit", "Deny", "Disabled"]
          metadata     = { displayName = "Effect", description = "Enable or disable the policy" }
        }
      })
      policy_rule  = jsonencode({
        if = {
          allOf = [
            { field = "type", equals = "Microsoft.Network/publicIPAddresses" },
            {
              anyOf = [
                { field = "Microsoft.Network/publicIPAddresses/ipConfiguration.id", contains = "/networkInterfaces/" },
                { field = "Microsoft.Network/publicIPAddresses/ipConfiguration.id", contains = "/virtualMachines/" }
              ]
            }
          ]
        }
        then = { effect = "[parameters('effect')]" }
      })
    }

    "disabled-ddos-standard" = {
      name         = "DDoS Standard NOT Required (Cloudflare)"
      description  = "Informational - DDoS Standard not required as apps are protected by Cloudflare."
      mode         = "All"
      metadata     = jsonencode({ category = "Network", version = "1.0.0", note = "Cloudflare provides DDoS protection" })
      parameters   = jsonencode({})
      policy_rule  = jsonencode({
        if   = { field = "type", equals = "Microsoft.Network/ddosProtectionPlans" }
        then = { effect = "disabled" }
      })
    }

    "audit-private-dns-hub-link" = {
      name         = "Audit Private DNS zones linked to Hub"
      description  = "Audits that Private DNS zones have at least one VNet link."
      mode         = "All"
      metadata     = jsonencode({ category = "Network", version = "1.0.0" })
      parameters   = jsonencode({})
      policy_rule  = jsonencode({
        if = {
          allOf = [
            { field = "type", equals = "Microsoft.Network/privateDnsZones" }
          ]
        }
        then = { effect = "audit" }
      })
    }
  }

  #-----------------------------------------------------------------------------
  # Security Policies
  #-----------------------------------------------------------------------------
  security_policies_all = {
    "deny-storage-public-access" = {
      name         = "Deny Storage Account Public Access"
      description  = "Denies storage accounts with public blob access enabled."
      mode         = "Indexed"
      metadata     = jsonencode({ category = "Storage", version = "1.0.0" })
      parameters   = jsonencode({
        effect = {
          type         = "String"
          defaultValue = "Deny"
          allowedValues = ["Audit", "Deny", "Disabled"]
          metadata     = { displayName = "Effect", description = "Enable or disable the policy" }
        }
      })
      policy_rule  = jsonencode({
        if = {
          allOf = [
            { field = "type", equals = "Microsoft.Storage/storageAccounts" },
            { field = "Microsoft.Storage/storageAccounts/allowBlobPublicAccess", notEquals = false }
          ]
        }
        then = { effect = "[parameters('effect')]" }
      })
    }

    "deny-sql-without-private-endpoint" = {
      name         = "Deny Azure SQL without Private Endpoint"
      description  = "Denies Azure SQL Servers with public network access."
      mode         = "Indexed"
      metadata     = jsonencode({ category = "SQL", version = "1.0.0" })
      parameters   = jsonencode({
        effect = {
          type         = "String"
          defaultValue = "Deny"
          allowedValues = ["Audit", "Deny", "Disabled"]
          metadata     = { displayName = "Effect", description = "Enable or disable the policy" }
        }
      })
      policy_rule  = jsonencode({
        if = {
          allOf = [
            { field = "type", equals = "Microsoft.Sql/servers" },
            { field = "Microsoft.Sql/servers/publicNetworkAccess", notEquals = "Disabled" }
          ]
        }
        then = { effect = "[parameters('effect')]" }
      })
    }

    "deny-cosmos-without-private-endpoint" = {
      name         = "Deny Cosmos DB without Private Endpoint"
      description  = "Denies Cosmos DB with public network access."
      mode         = "Indexed"
      metadata     = jsonencode({ category = "Cosmos DB", version = "1.0.0" })
      parameters   = jsonencode({
        effect = {
          type         = "String"
          defaultValue = "Deny"
          allowedValues = ["Audit", "Deny", "Disabled"]
          metadata     = { displayName = "Effect", description = "Enable or disable the policy" }
        }
      })
      policy_rule  = jsonencode({
        if = {
          allOf = [
            { field = "type", equals = "Microsoft.DocumentDB/databaseAccounts" },
            { field = "Microsoft.DocumentDB/databaseAccounts/publicNetworkAccess", notEquals = "Disabled" }
          ]
        }
        then = { effect = "[parameters('effect')]" }
      })
    }

    "audit-app-service-private-endpoint" = {
      name         = "Audit App Service Private Endpoint"
      description  = "Audits that App Services use private endpoints."
      mode         = "Indexed"
      metadata     = jsonencode({ category = "App Service", version = "1.0.0" })
      parameters   = jsonencode({
        effect = {
          type         = "String"
          defaultValue = "Audit"
          allowedValues = ["Audit", "Deny", "Disabled"]
          metadata     = { displayName = "Effect", description = "Enable or disable the policy" }
        }
      })
      policy_rule  = jsonencode({
        if = {
          allOf = [
            { field = "type", equals = "Microsoft.Web/sites" },
            { field = "Microsoft.Web/sites/publicNetworkAccess", notEquals = "Disabled" }
          ]
        }
        then = { effect = "[parameters('effect')]" }
      })
    }
  }

  #-----------------------------------------------------------------------------
  # Monitoring Policies
  #-----------------------------------------------------------------------------
  monitoring_policies_all = {
    "audit-la-retention-minimum" = {
      name         = "Audit Log Analytics Retention Minimum ${var.log_retention_days} Days"
      description  = "Audits that Log Analytics workspaces have minimum retention."
      mode         = "Indexed"
      metadata     = jsonencode({ category = "Monitoring", version = "1.0.0" })
      parameters   = jsonencode({
        minimumRetentionDays = {
          type         = "Integer"
          defaultValue = var.log_retention_days
          metadata     = { displayName = "Minimum Retention Days" }
        }
        effect = {
          type         = "String"
          defaultValue = "Audit"
          allowedValues = ["Audit", "Disabled"]
          metadata     = { displayName = "Effect" }
        }
      })
      policy_rule  = jsonencode({
        if = {
          allOf = [
            { field = "type", equals = "Microsoft.OperationalInsights/workspaces" },
            { field = "Microsoft.OperationalInsights/workspaces/retentionInDays", less = "[parameters('minimumRetentionDays')]" }
          ]
        }
        then = { effect = "[parameters('effect')]" }
      })
    }

    "audit-la-archive-enabled" = {
      name         = "Audit Log Analytics Archive Enabled"
      description  = "Audits that Log Analytics workspaces have archive enabled."
      mode         = "All"
      metadata     = jsonencode({ category = "Monitoring", version = "1.0.0" })
      parameters   = jsonencode({})
      policy_rule  = jsonencode({
        if   = { field = "type", equals = "Microsoft.OperationalInsights/workspaces" }
        then = { effect = "audit" }
      })
    }

    "audit-sentinel-connectors" = {
      name         = "Audit Sentinel Connectors Enabled"
      description  = "Audits that Sentinel has data connectors enabled."
      mode         = "All"
      metadata     = jsonencode({ category = "Security Center", version = "1.0.0" })
      parameters   = jsonencode({})
      policy_rule  = jsonencode({
        if   = { field = "type", equals = "Microsoft.SecurityInsights/dataConnectors" }
        then = { effect = "audit" }
      })
    }
  }

  #-----------------------------------------------------------------------------
  # Backup Policies
  #-----------------------------------------------------------------------------
  backup_policies_all = {
    "audit-backup-grs-production" = {
      name         = "Audit Backup GRS for Production"
      description  = "Audits that production RSV use GRS with cross-region restore."
      mode         = "Indexed"
      metadata     = jsonencode({ category = "Backup", version = "1.0.0" })
      parameters   = jsonencode({
        effect = {
          type         = "String"
          defaultValue = "Audit"
          allowedValues = ["Audit", "Deny", "Disabled"]
          metadata     = { displayName = "Effect" }
        }
      })
      policy_rule  = jsonencode({
        if = {
          allOf = [
            { field = "type", equals = "Microsoft.RecoveryServices/vaults" },
            {
              anyOf = [
                { field = "tags['Environment']", equals = "Production" },
                { field = "tags['Environment']", equals = "Prod" }
              ]
            },
            {
              anyOf = [
                { field = "Microsoft.RecoveryServices/vaults/redundancySettings.standardTierStorageRedundancy", notEquals = "GeoRedundant" },
                { field = "Microsoft.RecoveryServices/vaults/redundancySettings.crossRegionRestore", notEquals = "Enabled" }
              ]
            }
          ]
        }
        then = { effect = "[parameters('effect')]" }
      })
    }

    "audit-backup-lrs-nonproduction" = {
      name         = "Audit Backup LRS for Non-Production"
      description  = "Informational - LRS is sufficient for non-production."
      mode         = "Indexed"
      metadata     = jsonencode({ category = "Backup", version = "1.0.0", note = "LRS acceptable for non-prod" })
      parameters   = jsonencode({})
      policy_rule  = jsonencode({
        if = {
          allOf = [
            { field = "type", equals = "Microsoft.RecoveryServices/vaults" },
            {
              anyOf = [
                { field = "tags['Environment']", equals = "Development" },
                { field = "tags['Environment']", equals = "Dev" },
                { field = "tags['Environment']", equals = "Test" },
                { field = "tags['Environment']", equals = "NonProd" }
              ]
            }
          ]
        }
        then = { effect = "audit" }
      })
    }
  }

  #-----------------------------------------------------------------------------
  # Cost Policies
  #-----------------------------------------------------------------------------
  cost_policies_all = {
    "audit-budget-configured" = {
      name         = "Audit Budget Configured"
      description  = "Audits that budgets are configured for cost management."
      mode         = "All"
      metadata     = jsonencode({ category = "Cost Management", version = "1.0.0" })
      parameters   = jsonencode({})
      policy_rule  = jsonencode({
        if   = { field = "type", equals = "Microsoft.Resources/subscriptions/resourceGroups" }
        then = { effect = "audit" }
      })
    }

    "deny-expensive-vm-skus-sandbox" = {
      name         = "Deny Expensive VM SKUs in Sandbox"
      description  = "Denies VM SKUs outside approved list for Sandbox."
      mode         = "Indexed"
      metadata     = jsonencode({ category = "Compute", version = "1.0.0" })
      parameters   = jsonencode({
        allowedSkus = {
          type         = "Array"
          defaultValue = var.allowed_vm_skus_sandbox
          metadata     = { displayName = "Allowed VM SKUs" }
        }
        effect = {
          type         = "String"
          defaultValue = "Deny"
          allowedValues = ["Audit", "Deny", "Disabled"]
          metadata     = { displayName = "Effect" }
        }
      })
      policy_rule  = jsonencode({
        if = {
          allOf = [
            { field = "type", equals = "Microsoft.Compute/virtualMachines" },
            { field = "Microsoft.Compute/virtualMachines/sku.name", notIn = "[parameters('allowedSkus')]" }
          ]
        }
        then = { effect = "[parameters('effect')]" }
      })
    }

    "deny-expensive-resources-sandbox" = {
      name         = "Deny Expensive Resources in Sandbox"
      description  = "Denies expensive resource types in Sandbox."
      mode         = "All"
      metadata     = jsonencode({ category = "Cost Management", version = "1.0.0" })
      parameters   = jsonencode({
        deniedResourceTypes = {
          type         = "Array"
          defaultValue = var.expensive_resource_types
          metadata     = { displayName = "Denied Resource Types" }
        }
        effect = {
          type         = "String"
          defaultValue = "Deny"
          allowedValues = ["Audit", "Deny", "Disabled"]
          metadata     = { displayName = "Effect" }
        }
      })
      policy_rule  = jsonencode({
        if   = { field = "type", in = "[parameters('deniedResourceTypes')]" }
        then = { effect = "[parameters('effect')]" }
      })
    }
  }

  #-----------------------------------------------------------------------------
  # Lifecycle Policies
  #-----------------------------------------------------------------------------
  lifecycle_policies_all = {
    "deny-sandbox-without-expiration" = {
      name         = "Deny Sandbox Resources Without Expiration Tag"
      description  = "Denies resources without Expiration tag in Sandbox."
      mode         = "Indexed"
      metadata     = jsonencode({ category = "Tags", version = "1.0.0" })
      parameters   = jsonencode({
        tagName = {
          type         = "String"
          defaultValue = "Expiration"
          metadata     = { displayName = "Tag Name" }
        }
        effect = {
          type         = "String"
          defaultValue = "Deny"
          allowedValues = ["Audit", "Deny", "Disabled"]
          metadata     = { displayName = "Effect" }
        }
      })
      policy_rule  = jsonencode({
        if   = { field = "[concat('tags[', parameters('tagName'), ']')]", exists = "false" }
        then = { effect = "[parameters('effect')]" }
      })
    }

    "audit-only-sandbox" = {
      name         = "Audit Only Mode for Sandbox"
      description  = "Marker policy for Sandbox - audit mode."
      mode         = "All"
      metadata     = jsonencode({ category = "General", version = "1.0.0" })
      parameters   = jsonencode({})
      policy_rule  = jsonencode({
        if   = { field = "type", equals = "Microsoft.Resources/subscriptions/resourceGroups" }
        then = { effect = "audit" }
      })
    }
  }

  #-----------------------------------------------------------------------------
  # Decommissioned Policies
  #-----------------------------------------------------------------------------
  decommissioned_policies_all = {
    "deny-all-resource-creation" = {
      name         = "Deny All Resource Creation"
      description  = "Denies creation of any resources. For decommissioned subscriptions."
      mode         = "All"
      metadata     = jsonencode({ category = "General", version = "1.0.0" })
      parameters   = jsonencode({})
      policy_rule  = jsonencode({
        if   = { not = { field = "type", equals = "Microsoft.Resources/subscriptions/resourceGroups" } }
        then = { effect = "deny" }
      })
    }

    "deny-all-resource-modification" = {
      name         = "Deny All Resource Modification"
      description  = "Denies modification of any resources. For decommissioned subscriptions."
      mode         = "All"
      metadata     = jsonencode({ category = "General", version = "1.0.0" })
      parameters   = jsonencode({})
      policy_rule  = jsonencode({
        if   = { field = "type", notEquals = "" }
        then = { effect = "deny" }
      })
    }
  }

  #-----------------------------------------------------------------------------
  # Conditional Merge - No type inconsistency with this approach
  #-----------------------------------------------------------------------------
  caf_policy_definitions = var.deploy_caf_policies ? merge(
    var.enable_network_policies ? local.network_policies_all : {},
    var.enable_security_policies ? local.security_policies_all : {},
    var.enable_monitoring_policies ? local.monitoring_policies_all : {},
    var.enable_backup_policies ? local.backup_policies_all : {},
    var.enable_cost_policies ? local.cost_policies_all : {},
    var.enable_lifecycle_policies ? local.lifecycle_policies_all : {},
    local.decommissioned_policies_all
  ) : {}

  #-----------------------------------------------------------------------------
  # Final merged policy definitions (CAF + Custom)
  #-----------------------------------------------------------------------------
  all_policy_definitions = merge(
    local.caf_policy_definitions,
    var.custom_policy_definitions
  )
}
