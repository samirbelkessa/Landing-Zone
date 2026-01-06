# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Module: policy-set-definitions (G02)                                          ║
# ║ Purpose: Azure Policy Set Definitions (Initiatives) for CAF Landing Zone      ║
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
