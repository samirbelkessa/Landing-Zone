# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Versions - Orchestrator 03-Management                                         ║
# ║ Purpose: Orchestrates deployment of Management Layer (M01-M08)                ║
# ║ Reads: foundation.tfstate, governance.tfstate                                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0"
    }
  }

  # ════════════════════════════════════════════════════════════════════════════
  # Backend Configuration - MANAGEMENT tfstate
  # ════════════════════════════════════════════════════════════════════════════
  # IMPORTANT: Update these values to match your environment
  backend "azurerm" {
    subscription_id      = "ef7442e9-4d15-4a28-939a-f428a3d59487"
    resource_group_name  = "rg-intelly-terraform-state"
    storage_account_name = "stintellytfstate"
    container_name       = "tfstate"
    key                  = "management.tfstate"
  }
}
