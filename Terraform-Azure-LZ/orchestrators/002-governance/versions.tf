# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Versions - Orchestrator 02-Governance                                         ║
# ║ Purpose: Orchestrates deployment of Landing Zone Governance                   ║
# ║ Components: G01, G02, G03, G04 (reads F01 from remote state)                 ║
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
  # Backend Configuration - GOVERNANCE tfstate (separate from foundation)
  # ════════════════════════════════════════════════════════════════════════════
  backend "azurerm" {
    subscription_id      = "ef7442e9-4d15-4a28-939a-f428a3d59487"
    resource_group_name  = "rg-intelly-terraform-state"
    storage_account_name = "stintellytfstate"
    container_name       = "tfstate"
    key                  = "governance.tfstate"
  }
}
