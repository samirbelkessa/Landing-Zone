# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Module: orchestrator-lza-gov                                                  ║
# ║ Purpose: Orchestrates deployment of Landing Zone Governance Foundation        ║
# ║ Components: F01, G01, G02, G03, G04                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0"
    }
  }
}
