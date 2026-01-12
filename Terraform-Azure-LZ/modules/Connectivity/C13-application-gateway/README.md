# C13 - Application Gateway Module

## Description

This module deploys an Azure Application Gateway with Web Application Firewall (WAF) v2 capabilities. It supports zone-redundant deployments, autoscaling, SSL/TLS termination, and integration with Azure Key Vault for certificate management.

The module is designed for centralized WAF deployment in a Hub-and-Spoke architecture, providing L7 load balancing and WAF protection for web applications.

## Architecture

```
                    ┌─────────────────────────────────────────────────────┐
                    │                 RESOURCE GROUP                       │
                    │                 rg-appgw-aue-001                      │
                    │                                                       │
    Internet ───────┼──► ┌─────────────┐    ┌─────────────────────────┐    │
                    │    │  Public IP  │    │    WAF Policy           │    │
                    │    │ pip-agw-... │────│   OWASP 3.2 Rules       │    │
                    │    └──────┬──────┘    │   Prevention Mode       │    │
                    │           │           └───────────┬─────────────┘    │
                    │           ▼                       │                   │
                    │    ┌──────────────────────────────┴────────────────┐ │
                    │    │          APPLICATION GATEWAY                  │ │
                    │    │              agw-hub-aue-001                   │ │
                    │    │  ┌─────────────────────────────────────────┐  │ │
                    │    │  │  Frontend IP │ Listeners │ Routing Rules│  │ │
                    │    │  └─────────────────────────────────────────┘  │ │
                    │    │  ┌─────────────────────────────────────────┐  │ │
                    │    │  │  Backend Pools │ HTTP Settings │ Probes │  │ │
                    │    │  └─────────────────────────────────────────┘  │ │
                    │    └───────────────────┬───────────────────────────┘ │
                    │                        │                              │
                    └────────────────────────┼──────────────────────────────┘
                                             │
                    ┌────────────────────────┼──────────────────────────────┐
                    │            HUB VNET    │                              │
                    │      vnet-hub-aue-001  │                              │
                    │                        ▼                              │
                    │    ┌────────────────────────────────────────────┐    │
                    │    │     ApplicationGatewaySubnet               │    │
                    │    │           10.0.1.192/26                     │    │
                    │    └────────────────────────────────────────────┘    │
                    │                        │                              │
                    │              VNet Peering                             │
                    └────────────────────────┼──────────────────────────────┘
                                             │
                    ┌────────────────────────┼──────────────────────────────┐
                    │         SPOKE VNETS    │                              │
                    │                        ▼                              │
                    │    ┌────────────┐  ┌────────────┐  ┌────────────┐    │
                    │    │  App 1     │  │  App 2     │  │  App 3     │    │
                    │    │  Backend   │  │  Backend   │  │  Backend   │    │
                    │    └────────────┘  └────────────┘  └────────────┘    │
                    └──────────────────────────────────────────────────────┘
```

## Prerequisites

### Required Resources
- **Resource Group**: Must exist before deployment
- **Virtual Network**: Hub VNet with dedicated subnet for Application Gateway
- **Subnet**: Minimum /27 CIDR, named `ApplicationGatewaySubnet` or dedicated for AppGW
- **Log Analytics Workspace**: For diagnostic logs (optional but recommended)

### Dependencies
| Module | Code | Required |
|--------|------|----------|
| Hub Virtual Network | C01 | ✅ Yes |
| Log Analytics Workspace | M01 | ⚠️ Recommended |
| Naming Convention | F02 | ⚠️ Recommended |
| Tags | F03 | ⚠️ Recommended |

### Subnet Requirements
- Minimum size: /27 (32 addresses)
- Recommended size: /26 (64 addresses) for production
- No other resources in the subnet
- NSG: Not required (AppGW manages its own traffic rules)
- UDR: Avoid 0.0.0.0/0 routes to Azure Firewall (use route exclusion if needed)

## Usage

### Basic Example

```hcl
module "application_gateway" {
  source = "./modules/C13-application-gateway"

  # Required
  name                = "agw-hub-aue-001"
  resource_group_name = "rg-appgw-aue-001"
  subnet_id           = "/subscriptions/.../subnets/ApplicationGatewaySubnet"

  # Optional - Location
  location = "australiaeast"

  # Optional - Tags
  tags = {
    Environment        = "Production"
    Owner              = "Platform Team"
    CostCenter         = "IT-001"
    Application        = "Hub Services"
    Criticality        = "High"
    DataClassification = "Internal"
  }
}
```

### Advanced Example - Production Australia East

```hcl
# -----------------------------------------------------------------------------
# Application Gateway - Hub Australia East (Production)
# Centralized WAF with OWASP 3.2 rules in Prevention mode
# -----------------------------------------------------------------------------

module "application_gateway_aue" {
  source = "./modules/C13-application-gateway"

  # Required
  name                = "agw-hub-aue-001"
  resource_group_name = azurerm_resource_group.appgw_aue.name
  subnet_id           = module.hub_vnet_aue.subnet_ids["ApplicationGatewaySubnet"]
  location            = "australiaeast"

  # SKU and Capacity
  sku_name          = "WAF_v2"
  sku_tier          = "WAF_v2"
  autoscale_enabled = true
  min_capacity      = 2
  max_capacity      = 10
  zones             = ["1", "2", "3"]

  # WAF Configuration
  waf_enabled              = true
  waf_mode                 = "Prevention"
  waf_rule_set_type        = "OWASP"
  waf_rule_set_version     = "3.2"
  waf_file_upload_limit_mb = 100

  # WAF Exclusions (example for known false positives)
  waf_exclusions = [
    {
      match_variable          = "RequestHeaderNames"
      selector                = "x-custom-header"
      selector_match_operator = "Equals"
    }
  ]

  # SSL/TLS Policy (TLS 1.2 minimum)
  ssl_policy_type = "Predefined"
  ssl_policy_name = "AppGwSslPolicy20220101S"

  # Backend Configuration
  backend_address_pools = [
    {
      name         = "backend-app01"
      fqdns        = ["app01.internal.contoso.com"]
      ip_addresses = []
    },
    {
      name         = "backend-app02"
      ip_addresses = ["10.0.16.10", "10.0.16.11"]
      fqdns        = []
    }
  ]

  backend_http_settings = [
    {
      name                                = "https-settings"
      port                                = 443
      protocol                            = "Https"
      cookie_based_affinity               = "Disabled"
      request_timeout                     = 60
      pick_host_name_from_backend_address = true
      probe_name                          = "health-probe-https"
    },
    {
      name                  = "http-settings"
      port                  = 80
      protocol              = "Http"
      cookie_based_affinity = "Disabled"
      request_timeout       = 30
    }
  ]

  # Frontend Ports
  frontend_port_settings = [
    { name = "port-80", port = 80 },
    { name = "port-443", port = 443 }
  ]

  # HTTP Listeners
  http_listeners = [
    {
      name               = "listener-http"
      frontend_port_name = "port-80"
      protocol           = "Http"
    },
    {
      name                 = "listener-https-app01"
      frontend_port_name   = "port-443"
      protocol             = "Https"
      host_name            = "app01.contoso.com"
      ssl_certificate_name = "wildcard-contoso"
      require_sni          = true
    }
  ]

  # Routing Rules
  request_routing_rules = [
    {
      name                       = "rule-http-redirect"
      rule_type                  = "Basic"
      http_listener_name         = "listener-http"
      backend_address_pool_name  = "backend-app01"
      backend_http_settings_name = "http-settings"
      priority                   = 100
    },
    {
      name                       = "rule-https-app01"
      rule_type                  = "Basic"
      http_listener_name         = "listener-https-app01"
      backend_address_pool_name  = "backend-app01"
      backend_http_settings_name = "https-settings"
      priority                   = 200
    }
  ]

  # Health Probes
  health_probes = [
    {
      name                                      = "health-probe-https"
      protocol                                  = "Https"
      path                                      = "/health"
      interval                                  = 30
      timeout                                   = 30
      unhealthy_threshold                       = 3
      pick_host_name_from_backend_http_settings = true
      match = {
        status_code = ["200-399"]
      }
    }
  ]

  # SSL Certificates (Key Vault integration)
  identity_type = "UserAssigned"
  identity_ids  = [azurerm_user_assigned_identity.appgw.id]

  ssl_certificates = [
    {
      name                = "wildcard-contoso"
      key_vault_secret_id = azurerm_key_vault_certificate.wildcard.secret_id
    }
  ]

  # Diagnostics
  enable_diagnostic_settings = true
  log_analytics_workspace_id = module.log_analytics.id

  # Tags
  tags = {
    Environment        = "Production"
    Owner              = "Platform Team"
    CostCenter         = "IT-001"
    Application        = "Hub Services"
    Criticality        = "High"
    DataClassification = "Internal"
  }
}
```

### DR Example - Australia Southeast

```hcl
module "application_gateway_ause" {
  source = "./modules/C13-application-gateway"

  # Required
  name                = "agw-hub-ause-001"
  resource_group_name = "rg-appgw-ause-001"
  subnet_id           = module.hub_vnet_ause.subnet_ids["ApplicationGatewaySubnet"]
  location            = "australiasoutheast"

  # Same configuration as primary for DR
  sku_name          = "WAF_v2"
  sku_tier          = "WAF_v2"
  autoscale_enabled = true
  min_capacity      = 1  # Lower for DR standby
  max_capacity      = 10
  zones             = []  # Australia Southeast has limited AZ support

  waf_enabled          = true
  waf_mode             = "Prevention"
  waf_rule_set_version = "3.2"

  enable_diagnostic_settings = true
  log_analytics_workspace_id = module.log_analytics_ause.id

  tags = {
    Environment        = "Production"
    Owner              = "Platform Team"
    CostCenter         = "IT-001"
    Application        = "Hub Services DR"
    Criticality        = "High"
    DataClassification = "Internal"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of the Application Gateway (must start with 'agw-') | `string` | n/a | ✅ |
| resource_group_name | Name of the Resource Group | `string` | n/a | ✅ |
| subnet_id | Resource ID of the subnet for Application Gateway | `string` | n/a | ✅ |
| location | Azure region for deployment | `string` | `"australiaeast"` | ❌ |
| tags | Map of tags to apply | `map(string)` | `{}` | ❌ |
| sku_name | SKU name (Standard_v2 or WAF_v2) | `string` | `"WAF_v2"` | ❌ |
| sku_tier | SKU tier (must match sku_name) | `string` | `"WAF_v2"` | ❌ |
| capacity | Fixed capacity (when autoscaling disabled) | `number` | `2` | ❌ |
| zones | Availability zones list | `list(string)` | `["1","2","3"]` | ❌ |
| autoscale_enabled | Enable autoscaling | `bool` | `true` | ❌ |
| min_capacity | Minimum autoscale capacity | `number` | `2` | ❌ |
| max_capacity | Maximum autoscale capacity | `number` | `10` | ❌ |
| waf_enabled | Enable WAF | `bool` | `true` | ❌ |
| waf_mode | WAF mode (Detection or Prevention) | `string` | `"Prevention"` | ❌ |
| waf_rule_set_type | WAF rule set type | `string` | `"OWASP"` | ❌ |
| waf_rule_set_version | OWASP rule set version | `string` | `"3.2"` | ❌ |
| ssl_policy_type | SSL policy type | `string` | `"Predefined"` | ❌ |
| ssl_policy_name | Predefined SSL policy name | `string` | `"AppGwSslPolicy20220101S"` | ❌ |
| backend_address_pools | List of backend pools | `list(object)` | Default pool | ❌ |
| backend_http_settings | List of HTTP settings | `list(object)` | Default settings | ❌ |
| frontend_port_settings | List of frontend ports | `list(object)` | Ports 80, 443 | ❌ |
| http_listeners | List of HTTP listeners | `list(object)` | Default listener | ❌ |
| request_routing_rules | List of routing rules | `list(object)` | Default rule | ❌ |
| health_probes | List of custom health probes | `list(object)` | `[]` | ❌ |
| enable_diagnostic_settings | Enable diagnostic settings | `bool` | `true` | ❌ |
| log_analytics_workspace_id | Log Analytics Workspace ID | `string` | `null` | ❌ |

## Outputs

| Name | Description |
|------|-------------|
| id | Resource ID of the Application Gateway |
| name | Name of the Application Gateway |
| public_ip_id | Resource ID of the Public IP |
| public_ip_address | Public IP address |
| waf_policy_id | Resource ID of the WAF Policy |
| backend_address_pool_ids | Map of backend pool names to IDs |
| http_listener_ids | Map of listener names to IDs |
| frontend_ip_configuration_id | Frontend IP configuration ID |
| is_waf_enabled | Boolean if WAF is enabled |

## IP Addressing - Australia Project

Based on the IP Plan, the following subnets are reserved for Application Gateway:

| Region | Subnet | CIDR | IP Range | Usable |
|--------|--------|------|----------|--------|
| Australia East | ApplicationGatewaySubnet | 10.0.1.192/26 | 10.0.1.192 - 10.0.1.255 | 59 |
| Australia Southeast | ApplicationGatewaySubnet | 10.1.1.192/26 | 10.1.1.192 - 10.1.1.255 | 59 |

## Best Practices

### Security
- Always use WAF_v2 SKU for internet-facing applications
- Enable WAF in Prevention mode for production
- Use TLS 1.2 minimum (AppGwSslPolicy20220101S)
- Store SSL certificates in Key Vault
- Use User Assigned Managed Identity for Key Vault access

### High Availability
- Deploy across all available zones (AUE: 1,2,3)
- Use autoscaling with appropriate min/max capacity
- Configure health probes for all backends
- Set appropriate request timeouts

### Performance
- Enable HTTP/2 for improved performance
- Use connection draining for graceful backend updates
- Configure appropriate backend timeouts
- Consider cookie-based affinity for stateful applications

### Monitoring
- Enable all diagnostic logs
- Monitor WAF logs for blocked requests
- Set up alerts for unhealthy backends
- Review performance logs regularly

## Known Limitations

1. **Australia Southeast Zones**: Limited availability zone support - set zones to empty list
2. **NSG**: Application Gateway manages its own security rules - avoid adding NSG to the subnet
3. **UDR**: Avoid default routes (0.0.0.0/0) to Azure Firewall on AppGW subnet
4. **Certificate Updates**: Requires AppGW restart when certificates are updated in Key Vault

## Related Modules

- [C01 - Hub Virtual Network](../C01-hub-virtual-network/) - Hub VNet with subnets
- [M01 - Log Analytics Workspace](../M01-log-analytics-workspace/) - Diagnostics target
- [S03 - Key Vault](../S03-key-vault/) - SSL certificate storage
- [I03 - Managed Identity](../I03-managed-identity/) - Identity for Key Vault access
- [F02 - Naming Convention](../F02-naming-convention/) - Naming standards
- [F03 - Tags](../F03-tags/) - Tagging standards

## License

This module is part of the Azure Landing Zone CAF project.
