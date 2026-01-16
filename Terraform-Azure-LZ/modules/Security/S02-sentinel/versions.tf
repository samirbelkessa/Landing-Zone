# =============================================================================
# VERSIONS.TF - Terraform and Provider Constraints
# =============================================================================
# Module: S02-sentinel
# Purpose: Microsoft Sentinel SIEM/SOAR deployment
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0"
    }
  }
}
