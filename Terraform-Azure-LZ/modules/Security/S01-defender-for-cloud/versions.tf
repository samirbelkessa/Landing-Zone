# =============================================================================
# VERSIONS.TF - Terraform and Provider Constraints
# =============================================================================
# Module: S01-defender-for-cloud
# Purpose: Microsoft Defender for Cloud deployment
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
