################################################################################
# locals.tf - Local Values and Calculations
# Module: naming-convention (F02)
################################################################################

locals {
  #-----------------------------------------------------------------------------
  # Resource Type Definitions
  # Based on Azure CAF naming conventions
  # Format: slug, max_length, lowercase_only, alphanumeric_only, scope
  #-----------------------------------------------------------------------------
  resource_definitions = {
    # Foundation
    "mg"      = { slug = "mg", max_length = 90, lowercase = false, alphanum_only = false, scope = "tenant" }
    "rg"      = { slug = "rg", max_length = 90, lowercase = false, alphanum_only = false, scope = "subscription" }
    "sub"     = { slug = "sub", max_length = 64, lowercase = false, alphanum_only = false, scope = "tenant" }
    "policy"  = { slug = "policy", max_length = 128, lowercase = false, alphanum_only = false, scope = "definition" }
    "init"    = { slug = "init", max_length = 128, lowercase = false, alphanum_only = false, scope = "definition" }
    "role"    = { slug = "role", max_length = 64, lowercase = false, alphanum_only = false, scope = "definition" }

    # Networking
    "vnet"    = { slug = "vnet", max_length = 64, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "snet"    = { slug = "snet", max_length = 80, lowercase = false, alphanum_only = false, scope = "vnet" }
    "nsg"     = { slug = "nsg", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "asg"     = { slug = "asg", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "rt"      = { slug = "rt", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "udr"     = { slug = "udr", max_length = 80, lowercase = false, alphanum_only = false, scope = "route_table" }
    "pip"     = { slug = "pip", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "pipp"    = { slug = "pipp", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "lb"      = { slug = "lb", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "lbi"     = { slug = "lbi", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "nat"     = { slug = "nat", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "peer"    = { slug = "peer", max_length = 80, lowercase = false, alphanum_only = false, scope = "vnet" }
    "nic"     = { slug = "nic", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "pdns"    = { slug = "pdns", max_length = 63, lowercase = true, alphanum_only = false, scope = "resource_group" }
    "pdnsz"   = { slug = "pdnsz", max_length = 63, lowercase = true, alphanum_only = false, scope = "resource_group" }
    "pdnszl"  = { slug = "pdnszl", max_length = 80, lowercase = false, alphanum_only = false, scope = "private_dns_zone" }

    # Firewall & Security
    "afw"     = { slug = "afw", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "afwp"    = { slug = "afwp", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "afwrcg"  = { slug = "afwrcg", max_length = 80, lowercase = false, alphanum_only = false, scope = "firewall_policy" }
    "afwrc"   = { slug = "afwrc", max_length = 80, lowercase = false, alphanum_only = false, scope = "rule_collection_group" }
    "waf"     = { slug = "waf", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "wafp"    = { slug = "wafp", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }

    # Gateways
    "vgw"     = { slug = "vgw", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "lgw"     = { slug = "lgw", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "cn"      = { slug = "cn", max_length = 80, lowercase = false, alphanum_only = false, scope = "vgw" }
    "ergw"    = { slug = "ergw", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "erc"     = { slug = "erc", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "agw"     = { slug = "agw", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "bas"     = { slug = "bas", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }

    # DNS & Traffic
    "dnsz"    = { slug = "dnsz", max_length = 63, lowercase = true, alphanum_only = false, scope = "resource_group" }
    "traf"    = { slug = "traf", max_length = 63, lowercase = false, alphanum_only = false, scope = "global" }
    "fd"      = { slug = "fd", max_length = 64, lowercase = true, alphanum_only = true, scope = "global" }
    "cdn"     = { slug = "cdn", max_length = 260, lowercase = false, alphanum_only = false, scope = "global" }
    "cdnep"   = { slug = "cdnep", max_length = 50, lowercase = false, alphanum_only = false, scope = "cdn_profile" }

    # Storage
    "st"      = { slug = "st", max_length = 24, lowercase = true, alphanum_only = true, scope = "global" }
    "stdiag"  = { slug = "stdiag", max_length = 24, lowercase = true, alphanum_only = true, scope = "global" }
    "dls"     = { slug = "dls", max_length = 24, lowercase = true, alphanum_only = true, scope = "global" }

    # Compute
    "vm"      = { slug = "vm", max_length = 15, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "vmss"    = { slug = "vmss", max_length = 64, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "avail"   = { slug = "avail", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "disk"    = { slug = "disk", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "snap"    = { slug = "snap", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "gal"     = { slug = "gal", max_length = 80, lowercase = false, alphanum_only = true, scope = "resource_group" }
    "img"     = { slug = "img", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "ppg"     = { slug = "ppg", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "cg"      = { slug = "cg", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }

    # Containers
    "aks"     = { slug = "aks", max_length = 63, lowercase = true, alphanum_only = false, scope = "resource_group" }
    "acr"     = { slug = "acr", max_length = 50, lowercase = true, alphanum_only = true, scope = "global" }
    "ci"      = { slug = "ci", max_length = 63, lowercase = true, alphanum_only = false, scope = "resource_group" }
    "aci"     = { slug = "aci", max_length = 63, lowercase = true, alphanum_only = false, scope = "resource_group" }

    # Databases
    "sql"     = { slug = "sql", max_length = 63, lowercase = true, alphanum_only = false, scope = "global" }
    "sqldb"   = { slug = "sqldb", max_length = 128, lowercase = false, alphanum_only = false, scope = "server" }
    "sqlelp"  = { slug = "sqlelp", max_length = 128, lowercase = false, alphanum_only = false, scope = "server" }
    "cosmos"  = { slug = "cosmos", max_length = 44, lowercase = true, alphanum_only = false, scope = "global" }
    "mysql"   = { slug = "mysql", max_length = 63, lowercase = true, alphanum_only = false, scope = "global" }
    "psql"    = { slug = "psql", max_length = 63, lowercase = true, alphanum_only = false, scope = "global" }
    "redis"   = { slug = "redis", max_length = 63, lowercase = false, alphanum_only = false, scope = "global" }
    "maria"   = { slug = "maria", max_length = 63, lowercase = true, alphanum_only = false, scope = "global" }

    # Security
    "kv"      = { slug = "kv", max_length = 24, lowercase = false, alphanum_only = false, scope = "global" }
    "id"      = { slug = "id", max_length = 128, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "pep"     = { slug = "pep", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "psc"     = { slug = "psc", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "pls"     = { slug = "pls", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }

    # Management & Monitoring
    "log"     = { slug = "log", max_length = 63, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "aa"      = { slug = "aa", max_length = 50, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "appi"    = { slug = "appi", max_length = 260, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "ag"      = { slug = "ag", max_length = 260, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "dcr"     = { slug = "dcr", max_length = 64, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "dce"     = { slug = "dce", max_length = 44, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "ma"      = { slug = "ma", max_length = 260, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "diag"    = { slug = "diag", max_length = 260, lowercase = false, alphanum_only = false, scope = "resource" }
    "budget"  = { slug = "budget", max_length = 63, lowercase = false, alphanum_only = false, scope = "scope" }
    "lock"    = { slug = "lock", max_length = 260, lowercase = false, alphanum_only = false, scope = "resource" }

    # Web & App Services
    "app"     = { slug = "app", max_length = 60, lowercase = true, alphanum_only = false, scope = "global" }
    "plan"    = { slug = "plan", max_length = 40, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "func"    = { slug = "func", max_length = 60, lowercase = true, alphanum_only = false, scope = "global" }
    "logic"   = { slug = "logic", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "apim"    = { slug = "apim", max_length = 50, lowercase = false, alphanum_only = false, scope = "global" }

    # Backup & DR
    "rsv"     = { slug = "rsv", max_length = 50, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "bkpol"   = { slug = "bkpol", max_length = 150, lowercase = false, alphanum_only = false, scope = "vault" }
    "asr"     = { slug = "asr", max_length = 63, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "asrpol"  = { slug = "asrpol", max_length = 150, lowercase = false, alphanum_only = false, scope = "vault" }

    # Integration
    "sb"      = { slug = "sb", max_length = 50, lowercase = false, alphanum_only = false, scope = "global" }
    "sbq"     = { slug = "sbq", max_length = 260, lowercase = false, alphanum_only = false, scope = "namespace" }
    "sbt"     = { slug = "sbt", max_length = 260, lowercase = false, alphanum_only = false, scope = "namespace" }
    "evh"     = { slug = "evh", max_length = 50, lowercase = false, alphanum_only = false, scope = "global" }
    "evhns"   = { slug = "evhns", max_length = 50, lowercase = false, alphanum_only = false, scope = "global" }
    "evgd"    = { slug = "evgd", max_length = 50, lowercase = false, alphanum_only = false, scope = "region" }
    "evgt"    = { slug = "evgt", max_length = 50, lowercase = false, alphanum_only = false, scope = "resource_group" }

    # AI & Analytics
    "adf"     = { slug = "adf", max_length = 63, lowercase = false, alphanum_only = false, scope = "global" }
    "syn"     = { slug = "syn", max_length = 50, lowercase = true, alphanum_only = false, scope = "global" }
    "synsp"   = { slug = "synsp", max_length = 60, lowercase = false, alphanum_only = false, scope = "workspace" }
    "syndp"   = { slug = "syndp", max_length = 60, lowercase = false, alphanum_only = false, scope = "workspace" }
    "aml"     = { slug = "aml", max_length = 260, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "cog"     = { slug = "cog", max_length = 64, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "oai"     = { slug = "oai", max_length = 64, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "srch"    = { slug = "srch", max_length = 60, lowercase = true, alphanum_only = false, scope = "global" }
    "dbw"     = { slug = "dbw", max_length = 64, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "stream"  = { slug = "stream", max_length = 63, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "dec"     = { slug = "dec", max_length = 22, lowercase = true, alphanum_only = true, scope = "global" }

    # IoT
    "iot"     = { slug = "iot", max_length = 50, lowercase = false, alphanum_only = false, scope = "global" }
    "iotdps"  = { slug = "iotdps", max_length = 64, lowercase = false, alphanum_only = false, scope = "resource_group" }

    # Defender & Sentinel
    "mdc"     = { slug = "mdc", max_length = 260, lowercase = false, alphanum_only = false, scope = "subscription" }
    "sentinel" = { slug = "sentinel", max_length = 260, lowercase = false, alphanum_only = false, scope = "workspace" }

    # Network Watcher
    "nw"      = { slug = "nw", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }
    "nwfl"    = { slug = "nwfl", max_length = 80, lowercase = false, alphanum_only = false, scope = "resource_group" }
  }

  #-----------------------------------------------------------------------------
  # Region Abbreviations Mapping
  #-----------------------------------------------------------------------------
  region_abbreviations = {
    "australiaeast"      = "aue"
    "australiasoutheast" = "aus"
    "australiacentral"   = "auc"
    "australiacentral2"  = "auc2"
    "eastus"             = "eus"
    "eastus2"            = "eus2"
    "westus"             = "wus"
    "westus2"            = "wus2"
    "westus3"            = "wus3"
    "centralus"          = "cus"
    "northcentralus"     = "ncus"
    "southcentralus"     = "scus"
    "westcentralus"      = "wcus"
    "canadacentral"      = "cac"
    "canadaeast"         = "cae"
    "brazilsouth"        = "brs"
    "brazilsoutheast"    = "brse"
    "northeurope"        = "neu"
    "westeurope"         = "weu"
    "uksouth"            = "uks"
    "ukwest"             = "ukw"
    "francecentral"      = "frc"
    "francesouth"        = "frs"
    "germanynorth"       = "den"
    "germanywestcentral" = "dewc"
    "switzerlandnorth"   = "chn"
    "switzerlandwest"    = "chw"
    "norwayeast"         = "noe"
    "norwaywest"         = "now"
    "swedencentral"      = "sec"
    "polandcentral"      = "plc"
    "italynorth"         = "itn"
    "spaincentral"       = "esc"
    "eastasia"           = "ea"
    "southeastasia"      = "sea"
    "japaneast"          = "jpe"
    "japanwest"          = "jpw"
    "koreacentral"       = "krc"
    "koreasouth"         = "krs"
    "centralindia"       = "inc"
    "southindia"         = "ins"
    "westindia"          = "inw"
    "uaenorth"           = "uan"
    "uaecentral"         = "uac"
    "southafricanorth"   = "san"
    "southafricawest"    = "saw"
    "qatarcentral"       = "qac"
    "israelcentral"      = "ilc"
    "global"             = "glb"
  }

  #-----------------------------------------------------------------------------
  # Environment Abbreviations
  #-----------------------------------------------------------------------------
  environment_abbreviations = {
    "prod"    = "prd"
    "nonprod" = "npd"
    "dev"     = "dev"
    "test"    = "tst"
    "uat"     = "uat"
    "stg"     = "stg"
    "sandbox" = "sbx"
  }

  #-----------------------------------------------------------------------------
  # Computed Values
  #-----------------------------------------------------------------------------
  
  # Get resource definition
  resource_def = local.resource_definitions[var.resource_type]

  # Determine separator based on resource constraints
  effective_separator = local.resource_def.alphanum_only ? "" : var.separator

  # Build name components
  slug_component = var.use_slug ? local.resource_def.slug : ""
  env_abbrev     = local.environment_abbreviations[var.environment]
  
  # Format instance with leading zeros if provided
  instance_component = var.instance != null && var.instance != "" ? var.instance : ""

  # Build random suffix if requested
  random_chars = "abcdefghijklmnopqrstuvwxyz0123456789"

  # Assemble name parts (filter out empty strings)
  name_parts = compact([
    local.slug_component,
    var.workload,
    local.env_abbrev,
    var.region,
    local.instance_component,
    var.suffix
  ])

  # Join with separator
  assembled_name = join(local.effective_separator, local.name_parts)

  # Apply case transformation if required
  cased_name = local.resource_def.lowercase ? lower(local.assembled_name) : local.assembled_name

  # Remove invalid characters if alphanumeric only
  clean_name = local.resource_def.alphanum_only ? replace(local.cased_name, "/[^a-zA-Z0-9]/", "") : local.cased_name

  # Truncate to max length (accounting for random suffix)
  max_name_length = local.resource_def.max_length - var.random_suffix_length
  truncated_name  = substr(local.clean_name, 0, min(length(local.clean_name), local.max_name_length))

  # Final name - use custom_name if provided, otherwise use generated name
  generated_name = var.custom_name != null ? var.custom_name : local.truncated_name

  #-----------------------------------------------------------------------------
  # Validation Results
  #-----------------------------------------------------------------------------
  
  # Check if name meets all constraints
  name_valid = (
    length(local.generated_name) <= local.resource_def.max_length &&
    length(local.generated_name) >= 1 &&
    (!local.resource_def.lowercase || local.generated_name == lower(local.generated_name)) &&
    (!local.resource_def.alphanum_only || can(regex("^[a-zA-Z0-9]+$", local.generated_name)))
  )

  # Provide validation message
  validation_message = local.name_valid ? "Name is valid" : "Name violates constraints for resource type ${var.resource_type}"
}
