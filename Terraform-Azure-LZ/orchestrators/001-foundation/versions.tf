# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Orchestrator: 01-Foundation                                                   ║
# ║ Purpose: Deploys Management Group hierarchy (F01)                             ║
# ║ State: foundation.tfstate                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0"
    }
  }

  # ════════════════════════════════════════════════════════════════════════════
  # Backend Configuration - Uncomment and configure for your environment
  # ════════════════════════════════════════════════════════════════════════════
  backend "azurerm" {
    subscription_id      = "ef7442e9-4d15-4a28-939a-f428a3d59487"  # ← Sub du Storage Account
    resource_group_name  = "rg-intelly-terraform-state"
    storage_account_name = "stintellytfstate"
    container_name       = "tfstate"
    key                  = "foundation.tfstate"
  }
}