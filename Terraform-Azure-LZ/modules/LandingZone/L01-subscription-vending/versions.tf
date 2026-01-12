# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Module: L01 - Subscription Vending                                            ║
# ║ Description: Creates Azure Subscriptions and places them in Management Groups ║
# ║ Version: 1.0.0                                                                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">= 1.9.0"
    }
  }
}
