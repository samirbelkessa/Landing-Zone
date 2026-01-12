# =============================================================================
# Locals - Module tags (F03)
# =============================================================================

locals {
  # ---------------------------------------------------------------------------
  # Timestamp for resource creation tracking
  # ---------------------------------------------------------------------------
  current_timestamp = timestamp()
  creation_date     = formatdate("YYYY-MM-DD", local.current_timestamp)

  # ---------------------------------------------------------------------------
  # Environment short codes for naming conventions
  # ---------------------------------------------------------------------------
  environment_short_codes = {
    Production    = "prd"
    PreProduction = "ppd"
    Development   = "dev"
    Test          = "tst"
    Sandbox       = "sbx"
    DR            = "dr"
  }

  environment_short = local.environment_short_codes[var.environment]

  # ---------------------------------------------------------------------------
  # Criticality levels with descriptions
  # ---------------------------------------------------------------------------
  criticality_descriptions = {
    Critical = "Business critical - Maximum availability and protection required"
    High     = "High importance - Enhanced protection and monitoring"
    Medium   = "Standard importance - Default protection levels"
    Low      = "Low importance - Minimal protection acceptable"
  }

  # ---------------------------------------------------------------------------
  # Data classification levels with descriptions
  # ---------------------------------------------------------------------------
  data_classification_descriptions = {
    Public       = "Public data - No restrictions on access"
    Internal     = "Internal use only - Not for external sharing"
    Confidential = "Confidential - Restricted access, encryption required"
    Restricted   = "Highly restricted - Strict access controls, audit required"
  }

  # ---------------------------------------------------------------------------
  # Sandbox expiration validation
  # ---------------------------------------------------------------------------
  is_sandbox = var.environment == "Sandbox" || var.archetype == "Sandbox"

  sandbox_expiration_error = (
    local.is_sandbox &&
    var.enforce_sandbox_expiration &&
    var.expiration_date == null
  )

  # ---------------------------------------------------------------------------
  # Default expiration for Sandbox (90 days from creation)
  # ---------------------------------------------------------------------------
  default_sandbox_expiration = formatdate("YYYY-MM-DD", timeadd(local.current_timestamp, "2160h"))

  effective_expiration_date = (
    var.expiration_date != null ? var.expiration_date :
    local.is_sandbox ? local.default_sandbox_expiration :
    null
  )

  # ---------------------------------------------------------------------------
  # MANDATORY TAGS - Required on every resource
  # ---------------------------------------------------------------------------
  mandatory_tags = {
    Environment        = var.environment
    Owner              = var.owner
    CostCenter         = var.cost_center
    Application        = var.application
    Criticality        = var.criticality
    DataClassification = var.data_classification
    ManagedBy          = "Terraform"
  }

  # ---------------------------------------------------------------------------
  # CONDITIONAL TAGS - Added based on variable values
  # ---------------------------------------------------------------------------
  conditional_tags = merge(
    # Expiration date (required for Sandbox)
    local.effective_expiration_date != null ? {
      ExpirationDate = local.effective_expiration_date
    } : {},

    # Project tag
    var.project != null ? {
      Project = var.project
    } : {},

    # Department tag
    var.department != null ? {
      Department = var.department
    } : {},

    # Compliance tag
    var.compliance != null ? {
      Compliance = var.compliance
    } : {},

    # Maintenance window
    var.maintenance_window != null ? {
      MaintenanceWindow = var.maintenance_window
    } : {},

    # Creation metadata
    var.created_by != null ? {
      CreatedBy = var.created_by
    } : {},

    # Terraform workspace
    var.terraform_workspace != null ? {
      TerraformWorkspace = var.terraform_workspace
    } : {},

    # Module name
    var.module_name != null ? {
      Module = var.module_name
    } : {},

    # Archetype tag
    var.archetype != null ? {
      Archetype = var.archetype
    } : {},

    # Environment short code for naming
    {
      EnvironmentShort = local.environment_short
    }
  )

  # ---------------------------------------------------------------------------
  # AUTOMATION TAGS - For lifecycle management
  # ---------------------------------------------------------------------------
  automation_tags = {
    CreatedDate = local.creation_date
  }

  # ---------------------------------------------------------------------------
  # FINAL MERGED TAGS
  # ---------------------------------------------------------------------------
  all_tags = merge(
    local.mandatory_tags,
    local.conditional_tags,
    local.automation_tags,
    var.additional_tags
  )

  # ---------------------------------------------------------------------------
  # Tags filtered by category (for selective application)
  # ---------------------------------------------------------------------------
  
  # Security-related tags only
  security_tags = {
    DataClassification = var.data_classification
    Compliance         = var.compliance
    Environment        = var.environment
    Criticality        = var.criticality
  }

  # Cost-related tags only
  cost_tags = {
    CostCenter  = var.cost_center
    Environment = var.environment
    Application = var.application
    Owner       = var.owner
    Project     = var.project
    Department  = var.department
  }

  # Operational tags only
  operational_tags = {
    Environment       = var.environment
    Criticality       = var.criticality
    MaintenanceWindow = var.maintenance_window
    Owner             = var.owner
    Application       = var.application
  }

  # ---------------------------------------------------------------------------
  # Derived metadata for other modules
  # ---------------------------------------------------------------------------
  is_production = contains(["Production", "PreProduction", "DR"], var.environment)
  is_critical   = contains(["Critical", "High"], var.criticality)
  is_sensitive  = contains(["Confidential", "Restricted"], var.data_classification)

  # Backup tier recommendation based on criticality and environment
  backup_tier = (
    var.criticality == "Critical" && local.is_production ? "GRS" :
    var.criticality == "High" && local.is_production ? "GRS" :
    local.is_production ? "GRS" :
    "LRS"
  )

  # Retention tier recommendation
  retention_tier = (
    var.criticality == "Critical" ? "long" :
    var.criticality == "High" ? "standard" :
    "minimal"
  )
}
