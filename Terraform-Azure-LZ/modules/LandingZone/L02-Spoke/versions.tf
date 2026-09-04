# =============================================================================
# L02 - SPOKE VIRTUAL NETWORK — versions.tf
# =============================================================================
# Dual provider aliases:
#   azurerm.spoke → subscription where the spoke VNet is deployed
#   azurerm.hub   → connectivity subscription for hub-side peering
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = ">= 4.57.0"
      configuration_aliases = [azurerm.spoke, azurerm.hub]
    }
  }
}
